"""
How text becomes numbers for the TensorFlow skill tagger. THE FLUTTER APP MUST DO EXACTLY THE SAME
(lib/utils/skill_text_encoding.dart is its twin; test/skill_text_encoding_test.dart checks the two
agree on files written by this module), so everything here is deliberately simple and ASCII-only.

    token     a run of [A-Za-z0-9_]  OR  one other non-space character      ("Node.js" -> Node . js)
    word id   lower-cased token -> index in vocab["words"]  (0 = padding, 1 = unknown)
    char ids  the first 16 characters of the token as written (case kept) -> vocab["chars"] (0 pad, 1 unknown)
    labels    0 = outside a skill, 1 = first token of a skill, 2 = inside a skill
"""

from __future__ import annotations

import re

MAX_LEN = 192    # tokens per window fed to the model
MAX_CHARS = 16   # characters kept per token

PAD, UNK = 0, 1
_TOKEN = re.compile(r"[A-Za-z0-9_]+|[^\sA-Za-z0-9_]")


def tokenize(text: str) -> list[tuple[int, int, str]]:
    """(start, end, token) for every token of [text]."""
    return [(m.start(), m.end(), m.group(0)) for m in _TOKEN.finditer(text)]


def encode_tokens(tokens: list[str], vocab: dict) -> tuple[list[int], list[list[int]]]:
    words = vocab["words"]
    chars = vocab["chars"]
    word_ids = [words.get(t.lower(), UNK) for t in tokens]
    char_ids = []
    for t in tokens:
        ids = [chars.get(c, UNK) for c in t[:MAX_CHARS]]
        ids += [PAD] * (MAX_CHARS - len(ids))
        char_ids.append(ids)
    return word_ids, char_ids


def windows(n_tokens: int, size: int = MAX_LEN):
    """Index ranges that cut [n_tokens] tokens into windows of at most [size]."""
    for a in range(0, max(n_tokens, 1), size):
        yield a, min(a + size, n_tokens)


def labels_from_probs(probs, outside_threshold: float = 0.5) -> list[int]:
    """One label per token from the model's [outside, first, inside] probabilities.

    A token is "outside" when the model is at least [outside_threshold] sure of that, otherwise it is
    the likelier of first/inside. The model is trained to favour finding skills, so its raw answer
    over-tags; a threshold below 0.5 (tuned on the dev resumes, see tune_threshold.py) trades a
    little recall for much better precision. The phone applies the same rule.
    """
    out = []
    for p in probs:
        out.append(0 if p[0] >= outside_threshold else (1 if p[1] >= p[2] else 2))
    return out


def decode_spans(labels: list[int], tokens: list[tuple[int, int, str]]) -> list[tuple[int, int]]:
    """Character spans (start, end) of the skills a label sequence marks."""
    spans: list[tuple[int, int]] = []
    start = end = None
    for lab, (a, b, _) in zip(labels, tokens):
        if lab == 1 or (lab == 2 and start is None):  # a new skill starts (an I with no B also starts one)
            if start is not None:
                spans.append((start, end))
            start, end = a, b
        elif lab == 2:
            end = b
        else:
            if start is not None:
                spans.append((start, end))
            start = end = None
    if start is not None:
        spans.append((start, end))
    return spans
