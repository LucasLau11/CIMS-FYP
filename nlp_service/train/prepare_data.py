"""
Step 1 of 3 - build the training data, automatically (no manual review).

    python train/prepare_data.py

Reads the resumes in ../*.jsonl, learns which phrases are skills from the resumes themselves (see
skill_labels.py), labels them, cuts every resume into short chunks and writes spaCy training files:

    train/train.spacy   80% of resumes
    train/dev.spacy     10% (used while training to pick the best checkpoint)
    train/test.spacy    10% (never seen during training; used for the final score)
    train/learned_vocabulary.json   the skill phrases that were discovered

The split is by RESUME (not by chunk), so a resume's text never appears in both training and test.
"""

from __future__ import annotations

import glob
import hashlib
import json
import os
import random
import re
import sys

import spacy
from spacy.tokens import DocBin

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, ROOT)

from skill_labels import SKILLS_HEADINGS, OTHER_HEADINGS, build_vocabulary, chunk_text, silver_skill_spans  # noqa: E402

HEADINGS = set(SKILLS_HEADINGS) | set(OTHER_HEADINGS)
BULLETS = ["• ", "- ", "* ", "▪ ", "– "]

LABEL = "SKILL"
NEGATIVE_KEEP = 0.35  # share of chunks without any skill that is kept as negative examples


def load_resumes() -> list[dict]:
    seen: set[str] = set()
    rows: list[dict] = []
    for path in sorted(glob.glob(os.path.join(ROOT, "*.jsonl"))):
        if os.path.basename(path) in ("reviewed_skills.jsonl", "sample_for_review.jsonl"):
            continue  # copies of resumes that are already in the category files
        for line in open(path, encoding="utf-8"):
            if not line.strip():
                continue
            r = json.loads(line)
            key = r["file"]
            if key in seen:
                continue
            seen.add(key)
            rows.append({"file": key, "text": r["text"]})
    return rows


def bucket(file_name: str) -> str:
    h = int(hashlib.md5(file_name.encode()).hexdigest(), 16) % 100
    return "test" if h < 10 else ("dev" if h < 20 else "train")



def restyle(chunk: str, spans: list[tuple[int, int]], upper_headings: bool, bullet: str | None):
    """Same chunk, written differently: headings in CAPITALS and/or a bullet in front of each short
    line. Resumes come in many layouts; training on the same text in several of them teaches the
    model to rely on the words, not on one layout. Spans are moved to match."""
    new_lines: list[str] = []
    line_start_old: list[int] = []
    added_before: list[int] = []  # characters added in front of each line (cumulative)
    pos = 0
    added = 0
    for ln in chunk.split("\n"):
        line_start_old.append(pos)
        text = ln
        prefix = ""
        norm = re.sub(r"[:\-–—\s]+$", "", ln.strip().lower())
        is_heading = norm in HEADINGS and len(norm) <= 40
        if is_heading and upper_headings:
            text = ln.upper()
        elif bullet and not is_heading and 0 < len(ln.strip()) <= 45:
            prefix = bullet
        added_before.append(added + len(prefix))
        new_lines.append(prefix + text)
        added += len(prefix)
        pos += len(ln) + 1
    moved = []
    import bisect
    for a, b in spans:
        i = bisect.bisect_right(line_start_old, a) - 1
        moved.append((a + added_before[i], b + added_before[i]))
    return "\n".join(new_lines), moved


def main() -> None:
    random.seed(7)
    resumes = load_resumes()
    parts = {"train": [], "dev": [], "test": []}
    for r in resumes:
        parts[bucket(r["file"])].append(r)
    print({k: len(v) for k, v in parts.items()}, "resumes")

    # the vocabulary is learned from TRAINING resumes only, so dev/test labels cannot leak into it
    vocab = build_vocabulary([r["text"] for r in parts["train"]])
    print("learned", len(vocab), "skill phrases from the training resumes")
    json.dump(sorted(vocab), open(os.path.join(HERE, "learned_vocabulary.json"), "w", encoding="utf-8"), indent=0)

    nlp = spacy.blank("en")
    for name, rows in parts.items():
        db = DocBin()
        n_chunks = n_spans = n_pos = 0
        for r in rows:
            spans = silver_skill_spans(r["text"], vocab)
            for offset, chunk in chunk_text(r["text"]):
                end = offset + len(chunk)
                inside = [(s.start - offset, s.end - offset) for s in spans if s.start >= offset and s.end <= end]
                if not inside and random.random() > NEGATIVE_KEEP:
                    continue
                variants = [(chunk, inside)]
                if name == "train" and inside:
                    # the same text in other layouts (train only; dev and test stay untouched)
                    variants.append(restyle(chunk, inside, upper_headings=True, bullet=None))
                    variants.append(restyle(chunk, inside, upper_headings=random.random() < 0.5, bullet=random.choice(BULLETS)))
                for text, positions in variants:
                    doc = nlp.make_doc(text)
                    ents = []
                    for a, b in positions:
                        sp = doc.char_span(a, b, label=LABEL, alignment_mode="contract")
                        if sp is not None:
                            ents.append(sp)
                    doc.ents = spacy.util.filter_spans(ents)
                    db.add(doc)
                    n_chunks += 1
                    n_spans += len(doc.ents)
                    n_pos += bool(doc.ents)
        db.to_disk(os.path.join(HERE, f"{name}.spacy"))
        print(f"{name:5s}: {n_chunks:6d} chunks ({n_pos} with skills), {n_spans} skill spans")


if __name__ == "__main__":
    main()
