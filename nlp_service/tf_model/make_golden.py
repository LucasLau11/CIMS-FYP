"""
Writes test/fixtures/skill_encoding_golden.json: the Python answers for tokenising, encoding,
chunking, decoding and the skill sanity check on a set of tricky texts. The Dart twin
(lib/utils/skill_text_encoding.dart) must give the same answers; test/skill_text_encoding_test.dart
checks that, so the phone cannot quietly drift away from the model's training.

    .venv/Scripts/python tf_model/make_golden.py           (run from nlp_service/)
"""

from __future__ import annotations

import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, ROOT)
sys.path.insert(0, HERE)

from skill_labels import chunk_text, looks_like_skill  # noqa: E402
from text_encoding import MAX_CHARS, decode_spans, encode_tokens, labels_from_probs, tokenize, windows  # noqa: E402

PROJECT = os.path.dirname(ROOT)
OUT = os.path.join(PROJECT, "test", "fixtures", "skill_encoding_golden.json")

TEXTS = [
    "Siti binti Ahmad\nPhone: 012-345 6789\nSkills: Python, C++, Node.js, TCP/IP, C#",
    "TECHNICAL SKILLS\n• Problem Solving\n• Photoshop\n- Svelte\n* Hugging Face Transformers",
    "Built dashboards using Power BI and SQL; deployed with Docker (Kubernetes).",
    "Programming: Python, Java\nTools: Git, Docker\nCGPA: 3.45",
    "Café — résumé with non-ASCII, emoji-free text • and tabs\tinside.",
    "a" * 40 + " " + "ABC123_def " * 5,
    "",
    "\n\n   \n",
    "\n".join(f"line number {i} with some words" for i in range(60)),
]
ITEMS = ["Python", "C++", "Node.js", "TCP/IP", "and", "web site development and", "2019 - 2021", "name@mail.com",
         "Languages: English", "microsoft office (powerpoint", "Skills", "Project Management", "x", "A" * 41,
         "one two three four five six", "Experience in planning the whole budget for the year."]
LABELS = [[0, 1, 2, 2, 0, 1, 0, 2, 2, 1], [1], [2, 2], [], [0, 0, 1, 2, 2, 0, 1, 1, 0, 2]]


def main() -> None:
    chars = sorted({c for t in TEXTS for c in t if not c.isspace()})
    words = sorted({tok.lower() for t in TEXTS for _, _, tok in tokenize(t)})
    vocab = {"words": {w: i + 2 for i, w in enumerate(words)}, "chars": {c: i + 2 for i, c in enumerate(chars)}}

    cases = []
    for text in TEXTS:
        toks = tokenize(text)
        wid, cid = encode_tokens([t for _, _, t in toks], vocab)
        cases.append({
            "text": text,
            "tokens": [[a, b, t] for a, b, t in toks],
            "wordIds": wid,
            "charIds": cid,
            "chunks": [[o, c] for o, c in chunk_text(text, 300)],
            "windows": [list(w) for w in windows(len(toks), 7)],
        })
    decode_cases = []
    base = tokenize("one two three four five six seven eight nine ten")
    for lab in LABELS:
        toks = base[:len(lab)]
        decode_cases.append({"labels": lab, "tokens": [[a, b, t] for a, b, t in toks], "spans": [list(s) for s in decode_spans(lab, toks)]})

    probs = [[0.9, 0.05, 0.05], [0.4, 0.5, 0.1], [0.3, 0.2, 0.5], [0.5, 0.25, 0.25], [0.49, 0.3, 0.21], [0.2, 0.4, 0.4]]
    prob_cases = [{"probs": probs, "threshold": t, "labels": labels_from_probs(probs, t)} for t in (0.5, 0.3, 0.7)]

    golden = {
        "probCases": prob_cases,
        "maxChars": MAX_CHARS,
        "vocab": vocab,
        "cases": cases,
        "decode": decode_cases,
        "items": [[i, looks_like_skill(i)] for i in ITEMS],
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(golden, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(f"wrote {OUT}: {len(cases)} texts, {len(decode_cases)} label sequences, {len(ITEMS)} items")


if __name__ == "__main__":
    main()
