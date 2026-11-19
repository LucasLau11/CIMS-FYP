"""
Picks the decision threshold on the DEV chunks (never the test chunks) and then scores the test chunks once.

    .venv-tf/Scripts/python tf_model/tune_threshold.py

Needs tf_model/artifacts/skill_tagger.keras (written by train_tf.py train).
"""

from __future__ import annotations

import json
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import tensorflow as tf  # noqa: E402

import train_tf  # noqa: E402
from text_encoding import MAX_CHARS, MAX_LEN, encode_tokens, tokenize  # noqa: E402

ART = train_tf.OUT
DATA = train_tf.DATA


def main() -> None:
    model = train_tf.load_trained()
    dev = json.load(open(os.path.join(DATA, "dev_chunks.json"), encoding="utf-8"))
    test = json.load(open(os.path.join(DATA, "test_chunks.json"), encoding="utf-8"))
    predict = lambda W, C: model.predict([W, C], verbose=0)

    best = (0.0, 0.5)
    print("threshold  dev precision  recall  F1")
    for thr in (0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.5, 0.6):
        p, r, f = train_tf.span_scores(predict, dev[:1500], outside_threshold=thr)
        print(f"   {thr:.2f}      {p:.3f}        {r:.3f}   {f:.3f}")
        if f > best[0]:
            best = (f, thr)
    thr = best[1]
    json.dump({"outside_threshold": thr}, open(os.path.join(ART, "threshold.json"), "w"))
    p, r, f = train_tf.span_scores(predict, test, outside_threshold=thr)
    print(f"\nchosen threshold {thr}.  HELD-OUT TEST (exact span): precision {p:.3f}  recall {r:.3f}  F1 {f:.3f}")
    json.dump({"outside_threshold": thr, "precision": p, "recall": r, "f1": f}, open(os.path.join(ART, "test_scores.json"), "w"))


if __name__ == "__main__":
    main()
