"""
Runs the trained SKILL model (models/skill_ner) on a resume.

The model is optional: if it has not been trained yet, or cannot be loaded, every function here
quietly returns an empty list and the extractor falls back to what it did before.
"""

from __future__ import annotations

import os
import re
from functools import lru_cache
from typing import Optional

from skill_labels import chunk_text, looks_like_skill

_HERE = os.path.dirname(os.path.abspath(__file__))
_CANDIDATES = [
    os.path.join(_HERE, "models", "skill_ner", "model-best"),
    os.path.join(_HERE, "models", "skill_ner", "model-last"),
]


@lru_cache(maxsize=1)
def _load():
    if os.environ.get("CIMS_SKILL_MODEL", "1") == "0":
        return None
    import spacy

    for path in _CANDIDATES:
        if os.path.isdir(path):
            try:
                return spacy.load(path)
            except Exception:  # a broken model must never break parsing
                return None
    return None


def available() -> bool:
    return _load() is not None


def extract(text: str, limit: int = 40) -> list[str]:
    nlp = _load()
    if nlp is None:
        return []
    chunks = [c for _, c in chunk_text(text)]
    seen: set[str] = set()
    out: list[str] = []
    for doc in nlp.pipe(chunks, batch_size=64):
        for ent in doc.ents:
            if ent.label_ != "SKILL":
                continue
            item = re.sub(r"^[^\w(+#.]+|[\s.:;,]+$", "", ent.text.strip())
            key = item.lower()
            if not item or key in seen or not looks_like_skill(item):
                continue
            seen.add(key)
            out.append(item)
            if len(out) >= limit:
                return out
    return out


def model_dir() -> Optional[str]:
    for path in _CANDIDATES:
        if os.path.isdir(path):
            return path
    return None
