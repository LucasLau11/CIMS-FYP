"""
Hybrid resume field extractor: pretrained spaCy NER (name / organisation)
plus regex/heuristics for everything else, ported field-for-field from the
original Dart-only parser at lib/services/resume_parser_service.dart so the
two stay comparable (regex vs NLP) for the FYP report.

Skills extraction is still regex/section-based here in Phase A — Phase B
replaces this specific field with a custom-trained SKILL entity component.
"""

import re
from dataclasses import dataclass, field
from typing import Optional

import spacy

_nlp = spacy.load("en_core_web_sm")

# -----------------------------------------------------------------
# Data shapes — mirror ParsedResumeData / ParsedWorkExperience in
# lib/services/resume_parser_service.dart exactly, field for field.
# -----------------------------------------------------------------


@dataclass
class ParsedWorkExperience:
    position: Optional[str] = None
    companyName: Optional[str] = None
    startYear: Optional[int] = None
    endYear: Optional[int] = None
    isCurrent: bool = False
    description: Optional[str] = None


@dataclass
class ParsedResumeData:
    fullName: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    dateOfBirth: Optional[str] = None  # ISO "YYYY-MM-DD"
    programme: Optional[str] = None
    faculty: Optional[str] = None
    semester: Optional[int] = None
    cgpa: Optional[float] = None
    skills: list[str] = field(default_factory=list)
    workExperience: list[ParsedWorkExperience] = field(default_factory=list)
    nameSource: str = "none"  # "nlp" | "regex" | "none" — for the FYP A/B comparison


# -----------------------------------------------------------------
# Section heading aliases — identical list to the Dart version.
# -----------------------------------------------------------------

SKILLS_HEADINGS = [
    "technical skills", "key skills", "core competencies", "areas of expertise",
    "skills & competencies", "competencies", "expertise", "skills",
]

WORK_HEADINGS = [
    "professional experience", "work experience", "employment history",
    "work history", "relevant experience", "experience",
]

ALL_SECTION_HEADINGS = SKILLS_HEADINGS + WORK_HEADINGS + [
    "education", "academic background", "qualifications",
    "projects", "certifications", "certificates", "achievements", "awards",
    "activities", "extracurricular", "co-curricular", "hobbies", "interests",
    "languages", "publications", "references", "summary", "objective",
    "profile", "about me", "personal details", "personal information",
]


def _extract_section(text: str, heading_aliases: list[str]) -> Optional[list[str]]:
    lines = text.split("\n")
    sorted_aliases = sorted(heading_aliases, key=len, reverse=True)

    heading_index = None
    for i, raw in enumerate(lines):
        cleaned = re.sub(r"[:\-–—]+$", "", raw.strip().lower()).strip()
        if not cleaned or len(cleaned) > 40:
            continue
        if cleaned in sorted_aliases:
            heading_index = i
            break
    if heading_index is None:
        return None

    collected: list[str] = []
    for i in range(heading_index + 1, len(lines)):
        raw = lines[i]
        cleaned = re.sub(r"[:\-–—]+$", "", raw.strip().lower()).strip()
        if cleaned and len(cleaned) <= 40 and cleaned in ALL_SECTION_HEADINGS:
            break
        collected.append(raw)
        if len(collected) >= 40:
            break
    return collected


def _extract_skills(text: str) -> list[str]:
    block_lines = _extract_section(text, SKILLS_HEADINGS)
    if block_lines is None:
        return []

    tokens: list[str] = []
    seen: set[str] = set()
    for raw_line in block_lines:
        line = re.sub(r"^[•▪◦·*\-]\s+", "", raw_line.strip())
        if not line:
            continue
        for part in re.split(r"[,;|/]|\s{2,}", line):
            token = re.sub(r"^[•▪◦·*]+|[.]+$", "", part.strip()).strip()
            if not token or len(token) < 2 or len(token) > 30:
                continue
            if not re.search(r"[A-Za-z]", token):
                continue
            key = token.lower()
            if key not in seen:
                seen.add(key)
                tokens.append(token)
        if len(tokens) >= 40:
            break
    return tokens


_STREET_KEYWORDS = re.compile(
    r"\b(jalan|jln|lorong|lrg|taman|tmn|persiaran|lot|no\.?\s?\d|blok|unit|apartment|kondominium|street|avenue|road|drive|boulevard)\b",
    re.IGNORECASE,
)


def _looks_like_a_place_not_a_name(candidate: str) -> bool:
    """Pretrained NER occasionally tags a short street/place name (e.g.
    "Jalan Ampang") as PERSON — it superficially looks like a two-word
    proper noun. Reject anything matching known address vocabulary before
    trusting an NLP-found name."""
    return bool(_STREET_KEYWORDS.search(candidate))


_DATE_RANGE_PATTERN = re.compile(
    r"((?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?\s+)?(\d{4})\s*(?:-|–|—|to)\s*"
    r"((?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?\s+)?(present|current|now|\d{4})",
    re.IGNORECASE,
)


def _org_entities_in(doc_span_text: str) -> list[str]:
    """Pretrained-NER enrichment: ORG entities found within one job entry's
    text, used as a cross-check/fallback for the regex-split company name."""
    doc = _nlp(doc_span_text)
    return [ent.text.strip() for ent in doc.ents if ent.label_ == "ORG"]


def _extract_work_experience(text: str) -> list[ParsedWorkExperience]:
    block_lines = _extract_section(text, WORK_HEADINGS)
    if not block_lines:
        return []

    anchor_indexes = [i for i, line in enumerate(block_lines) if _DATE_RANGE_PATTERN.search(line)]
    if not anchor_indexes:
        non_empty = [l.strip() for l in block_lines if l.strip()]
        if not non_empty:
            return []
        return [
            ParsedWorkExperience(
                position=non_empty[0] if len(non_empty[0]) <= 60 else None,
                description="\n".join(non_empty),
            )
        ]

    entries: list[ParsedWorkExperience] = []
    for a, anchor_line in enumerate(anchor_indexes):
        if len(entries) >= 8:
            break
        next_anchor = anchor_indexes[a + 1] if a + 1 < len(anchor_indexes) else len(block_lines)

        date_match = _DATE_RANGE_PATTERN.search(block_lines[anchor_line])
        start_year = int(date_match.group(2)) if date_match.group(2) else None
        end_raw = date_match.group(4)
        is_current = bool(re.match(r"present|current|now", end_raw, re.IGNORECASE))
        end_year = None if is_current else (int(end_raw) if end_raw.isdigit() else None)

        date_stripped = (block_lines[anchor_line][: date_match.start()] + block_lines[anchor_line][date_match.end() :]).strip()
        title_line = date_stripped if date_stripped else (block_lines[anchor_line - 1].strip() if anchor_line > 0 else "")

        position = None
        company = None
        cleaned_title = re.sub(r"[()\[\]]", "", re.sub(r"^[•▪◦·*\-]\s+", "", title_line)).strip()
        if cleaned_title:
            split_match = re.match(r"^(.*?)\s+(?:at|@|,|-|–|—|\|)\s+(.*)$", cleaned_title)
            if split_match:
                position = split_match.group(1).strip() or None
                company = split_match.group(2).strip() or None
            else:
                position = cleaned_title

        description_lines = []
        for i in range(anchor_line + 1, next_anchor):
            l = block_lines[i].strip()
            if not l:
                continue
            description_lines.append(re.sub(r"^[•▪◦·*\-]\s+", "", l))
        description = "\n".join(description_lines) if description_lines else None

        # Pretrained-NER cross-check: if regex didn't split out a company
        # name, see if spaCy found an ORG entity on the title line itself.
        if not company and cleaned_title:
            orgs = _org_entities_in(cleaned_title)
            if orgs:
                company = orgs[0]

        if position or company or description:
            entries.append(
                ParsedWorkExperience(
                    position=position or None,
                    companyName=company or None,
                    startYear=start_year,
                    endYear=end_year,
                    isCurrent=is_current,
                    description=description,
                )
            )
    return entries


def _extract_labelled(text: str, labels: list[str]) -> Optional[str]:
    for label in labels:
        match = re.search(rf"{re.escape(label)}\s*[:\-]\s*(.+)", text, re.IGNORECASE)
        if match:
            value = match.group(1).strip()
            if value and len(value) < 150:
                return value
    return None


def _extract_name_regex(text: str) -> Optional[str]:
    lines = [l.strip() for l in text.split("\n") if l.strip()]
    for line in lines[:6]:
        if len(line) > 60:
            continue
        if re.search(r"[0-9@]", line):
            continue
        cleaned = re.sub(r"^[^\w]+", "", line).strip()
        if not cleaned:
            continue
        words = cleaned.split()
        if not (2 <= len(words) <= 5):
            continue
        if all(re.match(r"^[A-Za-z][a-zA-Z.'\-]*$", w) for w in words):
            return cleaned
    return None


def _extract_name(text: str) -> tuple[Optional[str], str]:
    """Returns (name, source) — source is 'nlp' or 'regex' or 'none', kept
    for the FYP report's regex-vs-NLP comparison."""
    # Pretrained NER first: look for a PERSON entity within the first few
    # lines of the document (where a resume's name conventionally sits).
    head_text = "\n".join(text.split("\n")[:8])
    doc = _nlp(head_text)
    for ent in doc.ents:
        candidate = ent.text.strip()
        if ent.label_ == "PERSON" and 1 < len(candidate.split()) <= 5 and not _looks_like_a_place_not_a_name(candidate):
            return candidate, "nlp"

    regex_name = _extract_name_regex(text)
    if regex_name:
        return regex_name, "regex"
    return None, "none"


def _extract_phone(text: str) -> Optional[str]:
    labelled = _extract_labelled(text, ["phone", "mobile", "contact no", "contact number", "tel", "h/p", "hp"])
    if labelled:
        digit_match = re.search(r"[\d][\d\s\-]{7,}\d", labelled)
        if digit_match:
            return digit_match.group(0).strip()
    match = re.search(r"(\+?60[\s\-]?)?0?1[0-9][\s\-]?[0-9]{3,4}[\s\-]?[0-9]{3,4}", text)
    if match:
        return match.group(0).strip()
    intl_match = re.search(r"(?<!\d)\+?\(?\d{1,4}\)?[\s\-]?\d{2,4}[\s\-]?\d{2,4}[\s\-]?\d{0,4}", text)
    return intl_match.group(0).strip() if intl_match else None


def _extract_dob(text: str) -> Optional[str]:
    label_match = re.search(
        r"(?:date of birth|dob|d\.o\.b)\s*[:\-]?\s*"
        r"(\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4}|[A-Za-z]+\s+\d{1,2},?\s+\d{4})",
        text,
        re.IGNORECASE,
    )
    if not label_match:
        return None
    raw = label_match.group(1)
    m = re.match(r"^(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})$", raw)
    if m:
        day, month, year = int(m.group(1)), int(m.group(2)), int(m.group(3))
        if year < 100:
            year += 2000
        try:
            from datetime import date

            return date(year, month, day).isoformat()
        except ValueError:
            return None
    try:
        from dateutil import parser as date_parser  # lazy import, optional dep

        return date_parser.parse(raw).date().isoformat()
    except Exception:
        return None


def _extract_address(text: str) -> Optional[str]:
    labelled = _extract_labelled(
        text, ["address", "residential address", "home address", "current address", "location", "residing at"]
    )
    if labelled:
        return labelled

    postcode = re.compile(r"\b\d{5}\b")
    city_state_pattern = re.compile(r"^[A-Za-z\s]{3,30},\s*[A-Za-z\s]{2,30}$")
    for raw_line in text.split("\n"):
        line = raw_line.strip()
        if not line or len(line) > 150:
            continue
        if _STREET_KEYWORDS.search(line) and postcode.search(line):
            return line
        if _STREET_KEYWORDS.search(line) and len(line) > 15:
            return line
    for line in [l.strip() for l in text.split("\n")[:10]]:
        if city_state_pattern.match(line):
            return line
    return None


def _extract_programme(text: str) -> Optional[str]:
    labelled = _extract_labelled(text, ["programme", "program", "course", "field of study", "major"])
    if labelled:
        return labelled

    degree_line = re.search(r"^.*\b(bachelor|diploma|master|foundation)\b.*$", text, re.IGNORECASE | re.MULTILINE)
    if not degree_line:
        return None
    line = degree_line.group(0).strip()
    if not line or len(line) > 150:
        return None
    cut = re.match(r"^[^,|]+", line)
    return (cut.group(0) if cut else line).strip()


def _extract_semester(text: str) -> Optional[int]:
    match = re.search(r"semester\s*[:\-]?\s*(\d{1,2})", text, re.IGNORECASE)
    if not match:
        return None
    value = int(match.group(1))
    return value if 1 <= value <= 4 else None


def _extract_cgpa(text: str) -> Optional[float]:
    match = re.search(r"c?gpa\s*[:\-]?\s*(\d\.\d{1,2})", text, re.IGNORECASE)
    if not match:
        return None
    value = float(match.group(1))
    return value if 0 <= value <= 4.0 else None


def parse(text: str) -> ParsedResumeData:
    name, name_source = _extract_name(text)
    return ParsedResumeData(
        fullName=name,
        nameSource=name_source,
        phone=_extract_phone(text),
        address=_extract_address(text),
        dateOfBirth=_extract_dob(text),
        programme=_extract_programme(text),
        faculty=_extract_labelled(text, ["faculty"]),
        semester=_extract_semester(text),
        cgpa=_extract_cgpa(text),
        skills=_extract_skills(text),
        workExperience=_extract_work_experience(text),
    )
