"""
Runs the TensorFlow Lite skill tagger (tf_model/artifacts/skill_tagger.tflite) on a resume.

This is the Python twin of what the phone does: the same tokenizer (tf_model/text_encoding.py), the
same windows, the same decoding and the same final sanity check, on the same .tflite file.
"""

from __future__ import annotations

import json
import os
import re
import sys
from functools import lru_cache

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "tf_model"))

from skill_labels import chunk_text, looks_like_skill  # noqa: E402
from text_encoding import MAX_CHARS, MAX_LEN, decode_spans, encode_tokens, labels_from_probs, tokenize, windows  # noqa: E402

ART = os.path.join(HERE, "tf_model", "artifacts")


class TfSkillTagger:
    def __init__(self, model_path: str | None = None, vocab_path: str | None = None):
        import tensorflow as tf

        self.vocab = json.load(open(vocab_path or os.path.join(ART, "skill_vocab.json"), encoding="utf-8"))
        self.interp = tf.lite.Interpreter(model_path=model_path or os.path.join(ART, "skill_tagger.tflite"))
        self.interp.allocate_tensors()
        ins = self.interp.get_input_details()
        self.words_in = next(d for d in ins if len(d["shape"]) == 2)
        self.chars_in = next(d for d in ins if len(d["shape"]) == 3)
        self.out = self.interp.get_output_details()[0]

    def _labels(self, tokens: list[tuple[int, int, str]]) -> list[int]:
        labels: list[int] = []
        for a, b in windows(len(tokens)):
            part = tokens[a:b]
            wid, cid = encode_tokens([t for _, _, t in part], self.vocab)
            W = np.zeros((1, MAX_LEN), dtype=self.words_in["dtype"])
            C = np.zeros((1, MAX_LEN, MAX_CHARS), dtype=self.chars_in["dtype"])
            W[0, :len(part)] = wid
            C[0, :len(part)] = cid
            self.interp.set_tensor(self.words_in["index"], W)
            self.interp.set_tensor(self.chars_in["index"], C)
            self.interp.invoke()
            probs = self.interp.get_tensor(self.out["index"])[0][:len(part)]
            labels += labels_from_probs(probs, self.vocab.get("outside_threshold", 0.5))
        return labels

    def extract(self, text: str, limit: int = 40) -> list[str]:
        seen: set[str] = set()
        out: list[str] = []
        for _, chunk in chunk_text(text):
            tokens = tokenize(chunk)
            if not tokens:
                continue
            for a, b in decode_spans(self._labels(tokens), tokens):
                item = re.sub(r"^[^\w(+#.]+|[\s.:;,]+$", "", chunk[a:b].strip())
                key = item.lower()
                if item and key not in seen and looks_like_skill(item):
                    seen.add(key)
                    out.append(item)
                    if len(out) >= limit:
                        return out
        return out


@lru_cache(maxsize=1)
def tagger() -> TfSkillTagger | None:
    try:
        return TfSkillTagger()
    except Exception:
        return None
