"""
Automatic ("silver") skill labels, with NO manual review.

The earlier bootstrap (bootstrap_label_skills.py) matched a word list anywhere in a resume, which
tags ordinary words ("analysis", "word", "go", "excel") in running sentences. That is too noisy to
train on. This module labels from STRUCTURE instead: the items listed under a resume's own
"Skills" / "Highlights" / "Core competencies" heading are skills by construction, so they are
labelled with their exact character offsets. Then every other place the same phrase appears in the
same resume is labelled too (document-level propagation, a standard weak-supervision step), so the
model also sees skills inside sentences, not only inside lists.

The same chunking is used for training and for prediction, so the model sees the same kind of
input in both.
"""

from __future__ import annotations

import re
from dataclasses import dataclass

SKILLS_HEADINGS = [
    "technical skills", "key skills", "core competencies", "areas of expertise",
    "skills & competencies", "skills and competencies", "competencies", "expertise",
    "professional skills", "computer skills", "technical proficiencies", "skill highlights",
    "highlights", "skills summary", "summary of skills", "skills",
]

OTHER_HEADINGS = [
    "professional experience", "work experience", "employment history", "work history",
    "relevant experience", "experience", "education", "academic background", "qualifications",
    "education and training", "projects", "certifications", "certificates", "achievements",
    "awards", "activities", "extracurricular", "co-curricular", "hobbies", "interests",
    "languages", "publications", "references", "summary", "professional summary", "objective",
    "profile", "about me", "personal details", "personal information", "accomplishments",
    "affiliations", "additional information", "interests and hobbies",
]

_ALL_HEADINGS = set(SKILLS_HEADINGS) | set(OTHER_HEADINGS)
_BULLET = re.compile(r"^[\s•▪◦·*\-–—>●■]+")
_SPLIT = re.compile(r"\s*[,;|•▪◦·●■]\s*|\s{3,}")
_MAX_ITEM_CHARS = 40
_MAX_ITEM_WORDS = 5
_MAX_SECTION_LINES = 40

# words a skill cannot start or end with: a list item that does is a cut-off sentence fragment
_STOP = {
    "a", "an", "and", "or", "the", "of", "to", "in", "on", "at", "for", "with", "by", "from", "as",
    "is", "are", "was", "be", "been", "that", "this", "which", "who", "i", "my", "our", "their",
    "also", "etc", "including", "such", "using", "use", "per", "within", "into", "over",
}


@dataclass(frozen=True)
class Span:
    start: int
    end: int

    def text(self, doc_text: str) -> str:
        return doc_text[self.start:self.end]


def _norm_heading(line: str) -> str:
    return re.sub(r"[:\-–—\s]+$", "", line.strip().lower()).strip()


def looks_like_skill(item: str) -> bool:
    """Whether a list item is short and noun-like enough to be a skill (not a sentence or a date)."""
    item = item.strip()
    if not (2 <= len(item) <= _MAX_ITEM_CHARS):
        return False
    words = item.split()
    if len(words) > _MAX_ITEM_WORDS:
        return False
    if not re.search(r"[A-Za-z]", item):
        return False
    if re.fullmatch(r"[\d\W]+", item):
        return False
    # a sentence: several words ending in a full stop
    if item.endswith(".") and len(words) > 3:
        return False
    # section labels and field labels are not skills
    if _norm_heading(item) in _ALL_HEADINGS:
        return False
    if re.search(r"\b(19|20)\d{2}\b", item):  # a year: a date range or a job line
        return False
    if re.search(r"@|https?://|www\.", item):
        return False
    # unbalanced brackets or a colon: a cut-off or a "label: value" line, not a skill
    if item.count("(") != item.count(")") or ":" in item:
        return False
    first, last = re.sub(r"\W", "", words[0].lower()), re.sub(r"\W", "", words[-1].lower())
    if first in _STOP or last in _STOP:
        return False
    if not re.match(r"[A-Za-z0-9(+#.]", item) or "�" in item:
        return False
    return True


def _clean_bounds(line: str, start: int, end: int, line_offset: int) -> tuple[int, int]:
    """Trims bullets/punctuation off one item inside a line and returns absolute offsets."""
    seg = line[start:end]
    left = len(seg) - len(seg.lstrip(" \t•▪◦·*-–—>●■"))
    right = len(seg.rstrip(" \t.:;,"))
    return line_offset + start + left, line_offset + start + max(right, left)


def _items_in_line(line: str, line_offset: int) -> list[Span]:
    spans: list[Span] = []
    pos = 0
    for m in list(_SPLIT.finditer(line)) + [None]:
        seg_end = m.start() if m else len(line)
        if seg_end > pos:
            a, b = _clean_bounds(line, pos, seg_end, line_offset)
            if b > a:
                spans.append(Span(a, b))
        pos = m.end() if m else len(line)
    return spans


def _find_sections(text: str) -> list[tuple[int, int, int]]:
    """(first line index, last line index exclusive, ...) of each skills section, as line ranges."""
    lines = text.split("\n")
    found: list[tuple[int, int, int]] = []
    i = 0
    while i < len(lines):
        norm = _norm_heading(lines[i])
        inline = None
        if norm not in SKILLS_HEADINGS or len(norm) > 40:
            # "Skills: Python, Java" on one line
            m = re.match(r"^\s*(" + "|".join(sorted(map(re.escape, SKILLS_HEADINGS), key=len, reverse=True)) + r")\s*:\s*(.+)$", lines[i], re.I)
            if m:
                inline = m.start(2)
                found.append((i, i + 1, inline))
            i += 1
            continue
        j = i + 1
        while j < len(lines) and j - i <= _MAX_SECTION_LINES:
            n2 = _norm_heading(lines[j])
            if n2 and len(n2) <= 40 and n2 in _ALL_HEADINGS:
                break
            j += 1
        found.append((i + 1, j, -1))
        i = j
    return found


def section_items(text: str) -> list[Span]:
    """Every skill-like list item under a skills heading of this resume (before any consensus filter)."""
    lines = text.split("\n")
    offsets: list[int] = []
    o = 0
    for ln in lines:
        offsets.append(o)
        o += len(ln) + 1

    items: list[Span] = []
    for first, last, inline_col in _find_sections(text):
        for li in range(first, last):
            line = lines[li]
            body = line[inline_col:] if inline_col >= 0 else line
            base = offsets[li] + (inline_col if inline_col >= 0 else 0)
            if not body.strip():
                continue
            for sp in _items_in_line(body, base):
                if looks_like_skill(sp.text(text)):
                    items.append(sp)
    return items


def build_vocabulary(texts, min_docs: int = 3, min_ratio: float = 0.3) -> set[str]:
    """Phrases that appear as skills-section items in at least [min_docs] DIFFERENT resumes.

    A phrase listed as a skill by several unrelated people is very likely a real skill, while
    one-off list items are mostly cut-off sentences. This agreement between resumes is the
    automatic quality check that replaces manual review.
    """
    texts = list(texts)
    df: dict[str, int] = {}
    for text in texts:
        for phrase in {sp.text(text).lower() for sp in section_items(text)}:
            df[phrase] = df.get(phrase, 0) + 1
    candidates = {p for p, n in df.items() if n >= min_docs}

    # A single plain word ("clients", "policies", "meetings") is listed as a skill in some resumes
    # but is mostly just an ordinary word. Keep it only if, in the resumes that contain the word at
    # all, it is LISTED as a skill in a good share of them (a ratio measured from the data itself).
    singles = {p for p in candidates if " " not in p}
    occurs: dict[str, int] = {p: 0 for p in singles}
    for text in texts:
        words = set(re.findall(r"[a-z0-9+#.\-/]+", text.lower()))
        for p in singles & words:
            occurs[p] += 1
    keep = set(candidates)
    for p in singles:
        if occurs[p] and df[p] / occurs[p] < min_ratio:
            keep.discard(p)
    return keep


def _propagates(phrase: str) -> bool:
    """Only distinctive phrases are labelled outside the list: multi-word ones and names with
    capitals, digits or symbols (SQL, C++, Node.js). Plain one-word terms ("sales") are too common
    in ordinary sentences."""
    if len(phrase.split()) >= 2:
        return True
    return bool(re.search(r"[0-9+#.]", phrase)) or (len(phrase) >= 3 and phrase.isupper())


def silver_skill_spans(text: str, vocab: set[str]) -> list[Span]:
    """Skill spans for one resume: list items that passed the consensus filter, plus every other
    place the same distinctive phrase appears in this resume."""
    spans: set[tuple[int, int]] = set()
    kept: set[str] = set()
    for sp in section_items(text):
        phrase = sp.text(text).lower()
        if phrase in vocab:
            spans.add((sp.start, sp.end))
            kept.add(phrase)
    for phrase in kept:
        if not _propagates(phrase):
            continue
        for m in re.finditer(r"(?<![\w+#])" + re.escape(phrase) + r"(?![\w+#])", text, re.I):
            spans.add((m.start(), m.end()))

    ordered = sorted(spans, key=lambda s: (s[0], -(s[1] - s[0])))
    result: list[Span] = []
    last_end = -1
    for s_, e_ in ordered:
        if s_ >= last_end:
            result.append(Span(s_, e_))
            last_end = e_
    return result


# ------------------------------------------------------------------ chunking


def chunk_text(text: str, max_chars: int = 600) -> list[tuple[int, str]]:
    """Splits a resume into windows of whole lines (offset of the window, window text)."""
    chunks: list[tuple[int, str]] = []
    cur_start = 0
    cur_len = 0
    pos = 0
    buf_start = 0
    lines = text.split("\n")
    for ln in lines:
        add = len(ln) + 1
        if cur_len + add > max_chars and cur_len > 0:
            chunks.append((buf_start, text[buf_start:pos].rstrip("\n")))
            buf_start = pos
            cur_len = 0
        cur_len += add
        pos += add
    if pos > buf_start:
        chunks.append((buf_start, text[buf_start:pos].rstrip("\n")))
    return [(o, t) for o, t in chunks if t.strip()]
