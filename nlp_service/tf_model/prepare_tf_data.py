"""
Step 1 of 4 - the same automatic training data as the spaCy model, as numbers for TensorFlow.

    python tf_model/prepare_tf_data.py          (run from nlp_service/, with the .venv-tf Python)

Uses the SAME resumes, the SAME train/dev/test split (by resume), the SAME automatically learned
skill vocabulary and the SAME layout variations as train/prepare_data.py, so the two models are
trained and scored on identical material.

Writes tf_model/data/{train,dev,test}.npz and vocab.json, plus test_chunks.json (the test text with
its true spans, for an exact span-level score).
"""

from __future__ import annotations

import collections
import importlib.util
import json
import os
import random
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, ROOT)
sys.path.insert(0, HERE)

from skill_labels import build_vocabulary, chunk_text, silver_skill_spans  # noqa: E402
from text_encoding import MAX_CHARS, MAX_LEN, encode_tokens, tokenize  # noqa: E402

# reuse the spaCy pipeline's loading, split and re-styling code instead of copying it
_spec = importlib.util.spec_from_file_location("spacy_prep", os.path.join(ROOT, "train", "prepare_data.py"))
spacy_prep = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(spacy_prep)

DATA = os.path.join(HERE, "data")
VOCAB_SIZE = 30000
NEGATIVE_KEEP = spacy_prep.NEGATIVE_KEEP


def labels_for(tokens, spans):
    lab = [0] * len(tokens)
    for a, b in spans:
        first = True
        for i, (s, e, _) in enumerate(tokens):
            if s < b and e > a:  # the token overlaps the span
                lab[i] = 1 if first else 2
                first = False
    return lab


def build_chunks(rows, vocab_phrases, name):
    """[(text, [(a, b), ...]), ...] for one split, exactly as the spaCy pipeline builds them."""
    out = []
    for r in rows:
        spans = silver_skill_spans(r["text"], vocab_phrases)
        for offset, chunk in chunk_text(r["text"]):
            end = offset + len(chunk)
            inside = [(s.start - offset, s.end - offset) for s in spans if s.start >= offset and s.end <= end]
            if not inside and random.random() > NEGATIVE_KEEP:
                continue
            variants = [(chunk, inside)]
            if name == "train" and inside:
                variants.append(spacy_prep.restyle(chunk, inside, upper_headings=True, bullet=None))
                variants.append(spacy_prep.restyle(chunk, inside, upper_headings=random.random() < 0.5, bullet=random.choice(spacy_prep.BULLETS)))
            out.extend(variants)
    return out


def main() -> None:
    random.seed(7)
    os.makedirs(DATA, exist_ok=True)
    resumes = spacy_prep.load_resumes()
    parts = {"train": [], "dev": [], "test": []}
    for r in resumes:
        parts[spacy_prep.bucket(r["file"])].append(r)
    phrases = build_vocabulary([r["text"] for r in parts["train"]])
    print({k: len(v) for k, v in parts.items()}, "resumes;", len(phrases), "skill phrases learned")

    chunks = {name: build_chunks(rows, phrases, name) for name, rows in parts.items()}

    # vocabularies come from the training chunks only
    word_count = collections.Counter()
    char_count = collections.Counter()
    for text, _ in chunks["train"]:
        for _, _, tok in tokenize(text):
            word_count[tok.lower()] += 1
            char_count.update(tok[:MAX_CHARS])
    words = {w: i + 2 for i, (w, _) in enumerate(word_count.most_common(VOCAB_SIZE))}
    chars = {c: i + 2 for i, c in enumerate(sorted(c for c, n in char_count.items() if n >= 3))}
    vocab = {"words": words, "chars": chars, "max_len": MAX_LEN, "max_chars": MAX_CHARS}
    json.dump(vocab, open(os.path.join(DATA, "vocab.json"), "w", encoding="utf-8"), ensure_ascii=False)
    print(f"{len(words)} words, {len(chars)} characters in the vocabulary")

    for name, items in chunks.items():
        W, C, Y = [], [], []
        for text, spans in items:
            toks = tokenize(text)[:MAX_LEN]
            wid, cid = encode_tokens([t for _, _, t in toks], vocab)
            lab = labels_for(toks, spans)
            pad = MAX_LEN - len(toks)
            W.append(wid + [0] * pad)
            C.append(cid + [[0] * MAX_CHARS] * pad)
            Y.append(lab + [0] * pad)
        np.savez_compressed(os.path.join(DATA, f"{name}.npz"), words=np.array(W, dtype=np.int32),
                            chars=np.array(C, dtype=np.int16), labels=np.array(Y, dtype=np.int8))
        n_skill = int(sum((np.array(Y) == 1).sum() for _ in [0]))
        print(f"{name:5s}: {len(items):6d} chunks, {n_skill} skills")
    for split in ("dev", "test"):
        json.dump([{"text": t, "spans": s} for t, s in chunks[split]], open(os.path.join(DATA, f"{split}_chunks.json"), "w", encoding="utf-8"))


if __name__ == "__main__":
    main()
