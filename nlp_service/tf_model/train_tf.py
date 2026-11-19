"""
Steps 2-4 of 4 - train the TensorFlow skill tagger, score it, and export it for the phone.

    .venv-tf/Scripts/python tf_model/train_tf.py train      # trains, prints dev F1 per epoch, scores the test set
    .venv-tf/Scripts/python tf_model/train_tf.py export     # TensorFlow Lite file + checks it matches Keras

Model: a small convolutional tagger (no recurrent layers, so it converts to TensorFlow Lite with
plain built-in operations and runs fast on a phone). Per token it sees the word (a learned
embedding) AND the characters of the word (a small character CNN, which is what lets it recognise
skill-like words it has never seen: capitals, digits, ".js", "++"). A stack of dilated 1-D
convolutions gives each token the context of the surrounding line, and a softmax picks
outside / first-token-of-a-skill / inside-a-skill.
"""

from __future__ import annotations

import json
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)

import tensorflow as tf  # noqa: E402

from text_encoding import MAX_CHARS, MAX_LEN, decode_spans, labels_from_probs, tokenize  # noqa: E402

DATA = os.path.join(HERE, "data")
OUT = os.path.join(HERE, "artifacts")


def build_model(n_words: int, n_chars: int) -> tf.keras.Model:
    words = tf.keras.Input(shape=(MAX_LEN,), dtype="int32", name="words")
    chars = tf.keras.Input(shape=(MAX_LEN, MAX_CHARS), dtype="int32", name="chars")

    w = tf.keras.layers.Embedding(n_words, 64, name="word_emb")(words)

    c = tf.keras.layers.Embedding(n_chars, 24, name="char_emb")(chars)            # (L, C, 24)
    c = tf.keras.layers.Conv2D(48, (1, 3), padding="same", activation="relu", name="char_conv")(c)
    c = tf.keras.layers.Lambda(lambda t: tf.reduce_max(t, axis=2), output_shape=(MAX_LEN, 48), name="char_max")(c)  # (L, 48)

    x = tf.keras.layers.Concatenate()([w, c])
    x = tf.keras.layers.Dense(128, activation="relu")(x)
    for dilation in (1, 2, 4, 8):
        y = tf.keras.layers.Conv1D(128, 3, padding="same", dilation_rate=dilation, activation="relu")(x)
        y = tf.keras.layers.Dropout(0.15)(y)
        x = tf.keras.layers.Add()([x, y])
        x = tf.keras.layers.LayerNormalization()(x)
    out = tf.keras.layers.Dense(3, activation="softmax", name="tags")(x)
    return tf.keras.Model([words, chars], out)


def load_trained() -> tf.keras.Model:
    """The best checkpoint. The architecture is rebuilt and the saved weights loaded into it, because
    Keras cannot re-create the pooling Lambda layer from the saved file on its own."""
    model = build_model(max(VOCAB["words"].values()) + 1, max(VOCAB["chars"].values()) + 1)
    model.load_weights(os.path.join(OUT, "skill_tagger.keras"))
    return model


def load(name):
    d = np.load(os.path.join(DATA, f"{name}.npz"))
    return d["words"].astype("int32"), d["chars"].astype("int32"), d["labels"].astype("int32")


def span_scores(model_predict, chunks, batch=256, outside_threshold=0.5):
    """Exact-match precision / recall / F1 of skill spans over the test chunks."""
    tp = fp = fn = 0
    for i in range(0, len(chunks), batch):
        part = chunks[i:i + batch]
        W = np.zeros((len(part), MAX_LEN), dtype="int32")
        C = np.zeros((len(part), MAX_LEN, MAX_CHARS), dtype="int32")
        toks = []
        for j, ch in enumerate(part):
            t = tokenize(ch["text"])[:MAX_LEN]
            toks.append(t)
            from text_encoding import encode_tokens
            wid, cid = encode_tokens([x for _, _, x in t], VOCAB)
            W[j, :len(t)] = wid
            C[j, :len(t)] = cid
        probs = model_predict(W, C)
        for j, ch in enumerate(part):
            got = set(decode_spans(labels_from_probs(probs[j][:len(toks[j])], outside_threshold), toks[j]))
            gold = {tuple(s) for s in ch["spans"]}
            tp += len(got & gold)
            fp += len(got - gold)
            fn += len(gold - got)
    p = tp / (tp + fp) if tp + fp else 0.0
    r = tp / (tp + fn) if tp + fn else 0.0
    return p, r, (2 * p * r / (p + r) if p + r else 0.0)


VOCAB = json.load(open(os.path.join(DATA, "vocab.json"), encoding="utf-8")) if os.path.exists(os.path.join(DATA, "vocab.json")) else None


def train(epochs: int = 12) -> None:
    os.makedirs(OUT, exist_ok=True)
    Wt, Ct, Yt = load("train")
    Wd, Cd, Yd = load("dev")
    n_words = max(VOCAB["words"].values()) + 1
    n_chars = max(VOCAB["chars"].values()) + 1
    model = build_model(n_words, n_chars)
    model.summary(print_fn=lambda s: print(s))

    # padding does not count; a skill token counts 3x so the rare class is not ignored
    def weights(W, Y):
        w = (W != 0).astype("float32")
        w[Y > 0] *= 3.0
        return w

    model.compile(optimizer=tf.keras.optimizers.Adam(1e-3), loss="sparse_categorical_crossentropy", weighted_metrics=["accuracy"])
    dev_chunks = None
    best = -1.0
    test_chunks = json.load(open(os.path.join(DATA, "test_chunks.json"), encoding="utf-8"))

    class Score(tf.keras.callbacks.Callback):
        def on_epoch_end(self, epoch, logs=None):
            nonlocal best
            # score on the dev split by reusing the test-chunk scorer on a slice of dev arrays
            pred = self.model.predict([Wd, Cd], batch_size=256, verbose=0).argmax(-1)
            tp = fp = fn = 0
            for j in range(len(Wd)):
                n = int((Wd[j] != 0).sum())
                # gold and predicted token labels -> compare as BIO spans over token indices
                def spans(lab):
                    out, s = [], None
                    for k, v in enumerate(lab[:n]):
                        if v == 1 or (v == 2 and s is None):
                            if s is not None:
                                out.append((s, k))
                            s = k
                        elif v == 0 and s is not None:
                            out.append((s, k))
                            s = None
                    if s is not None:
                        out.append((s, n))
                    return set(out)
                g, p_ = spans(Yd[j]), spans(pred[j])
                tp += len(g & p_)
                fp += len(p_ - g)
                fn += len(g - p_)
            p = tp / (tp + fp) if tp + fp else 0.0
            r = tp / (tp + fn) if tp + fn else 0.0
            f = 2 * p * r / (p + r) if p + r else 0.0
            print(f"  epoch {epoch + 1}: dev span P {p:.3f}  R {r:.3f}  F1 {f:.3f}", flush=True)
            if f > best:
                best = f
                self.model.save(os.path.join(OUT, "skill_tagger.keras"))

    model.fit([Wt, Ct], Yt, sample_weight=weights(Wt, Yt), validation_data=([Wd, Cd], Yd, weights(Wd, Yd)),
              epochs=epochs, batch_size=64, callbacks=[Score()], verbose=2)

    best_model = load_trained()
    p, r, f = span_scores(lambda W, C: best_model.predict([W, C], verbose=0), test_chunks)
    print(f"\nHELD-OUT TEST (exact span match): precision {p:.3f}  recall {r:.3f}  F1 {f:.3f}")
    json.dump({"precision": p, "recall": r, "f1": f}, open(os.path.join(OUT, "test_scores.json"), "w"))


def export() -> None:
    model = load_trained()
    conv = tf.lite.TFLiteConverter.from_keras_model(model)
    conv.optimizations = [tf.lite.Optimize.DEFAULT]          # 8-bit weights: about a quarter of the size
    conv.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]  # plain built-in ops only: no extra Flutter libraries
    tflite = conv.convert()
    path = os.path.join(OUT, "skill_tagger.tflite")
    open(path, "wb").write(tflite)
    print(f"TensorFlow Lite model: {len(tflite) / 1024:.0f} KB")

    # the .tflite must give the same answers as the Keras model, or the phone would behave differently
    interp = tf.lite.Interpreter(model_path=path)
    interp.allocate_tensors()
    test_chunks = json.load(open(os.path.join(DATA, "test_chunks.json"), encoding="utf-8"))
    ins = {d["name"].split(":")[0].split("/")[-1]: d for d in interp.get_input_details()}
    order = sorted(interp.get_input_details(), key=lambda d: 0 if len(d["shape"]) == 2 else 1)  # words (2-D) then chars (3-D)
    outd = interp.get_output_details()[0]

    def predict(W, C):
        out = np.zeros((len(W), MAX_LEN, 3), dtype="float32")
        for i in range(len(W)):
            interp.set_tensor(order[0]["index"], W[i:i + 1].astype(order[0]["dtype"]))
            interp.set_tensor(order[1]["index"], C[i:i + 1].astype(order[1]["dtype"]))
            interp.invoke()
            out[i] = interp.get_tensor(outd["index"])[0]
        return out

    sample = test_chunks[:600]
    p, r, f = span_scores(predict, sample, batch=64)
    kp, kr, kf = span_scores(lambda W, C: model.predict([W, C], verbose=0), sample)
    print(f"on 600 test chunks  TFLite F1 {f:.3f}   Keras F1 {kf:.3f}")
    json.dump({"tflite_f1_600": f, "keras_f1_600": kf, "size_kb": len(tflite) / 1024}, open(os.path.join(OUT, "export_scores.json"), "w"))
    # the phone needs the vocabulary (and the tuned decision threshold) next to the model
    vocab = json.load(open(os.path.join(DATA, "vocab.json"), encoding="utf-8"))
    thr_path = os.path.join(OUT, "threshold.json")
    vocab["outside_threshold"] = json.load(open(thr_path))["outside_threshold"] if os.path.exists(thr_path) else 0.5
    json.dump(vocab, open(os.path.join(OUT, "skill_vocab.json"), "w", encoding="utf-8"), ensure_ascii=False)


if __name__ == "__main__":
    {"train": train, "export": export}[sys.argv[1] if len(sys.argv) > 1 else "train"]()
