"""
Phase B, step 1 — weak-supervision auto-tagging of SKILL spans across a
folder of resumes, using spaCy's PhraseMatcher against skills_vocabulary.py.

This produces a ROUGH first pass, not a finished training set — the next
step (you, by hand) is reviewing the output and fixing mistakes: skills it
missed, wrong spans, things it shouldn't have matched. See phase B step 2.

Usage:
    python bootstrap_label_skills.py path/to/resume_folder [output_name.jsonl]

    The output filename is optional — defaults to labeled_skills.jsonl.
    Pass a distinct name per category batch (e.g. labeled_it.jsonl,
    labeled_design.jsonl) so repeated runs don't overwrite each other.

Requires the dev extras: pip install -r requirements-dev.txt

Output:
    <output_name>.jsonl — one JSON object per resume, with the full text
    plus every matched span's text and character offsets. This offset
    format is what spaCy's training data conversion step (Phase B, step 3)
    will consume later.

    Also prints a human-readable summary per file as it runs, so you can
    sanity-check quality immediately without opening the JSONL.
"""

import json
import sys
from collections import Counter
from pathlib import Path

import spacy
from spacy.matcher import PhraseMatcher

from skills_vocabulary import ALL_SKILLS

OUTPUT_FILE = "labeled_skills.jsonl"


def extract_text(path: Path) -> str:
    suffix = path.suffix.lower()
    if suffix == ".pdf":
        from pypdf import PdfReader

        reader = PdfReader(str(path))
        return "\n".join(page.extract_text() or "" for page in reader.pages)
    elif suffix == ".docx":
        import docx

        doc = docx.Document(str(path))
        return "\n".join(p.text for p in doc.paragraphs)
    elif suffix == ".txt":
        return path.read_text(encoding="utf-8", errors="ignore")
    else:
        raise ValueError(f"Unsupported file type: {suffix}")


def build_matcher(nlp) -> PhraseMatcher:
    matcher = PhraseMatcher(nlp.vocab, attr="LOWER")
    patterns = [nlp.make_doc(skill) for skill in ALL_SKILLS]
    matcher.add("SKILL", patterns)
    return matcher


def dedupe_overlapping(spans):
    """Keeps the longest span when two matches overlap (e.g. "Machine
    Learning" should win over a spurious standalone "Learning")."""
    spans = sorted(spans, key=lambda s: (s.start, -(s.end - s.start)))
    kept = []
    last_end = -1
    for span in spans:
        if span.start >= last_end:
            kept.append(span)
            last_end = span.end
    return kept


def main():
    if len(sys.argv) not in (2, 3):
        print("Usage: python bootstrap_label_skills.py path/to/resume_folder [output_name.jsonl]")
        sys.exit(1)

    folder = Path(sys.argv[1])
    output_file = sys.argv[2] if len(sys.argv) == 3 else OUTPUT_FILE
    if not folder.is_dir():
        print(f"Not a folder: {folder}")
        sys.exit(1)

    files = sorted(
        f for f in folder.rglob("*") if f.suffix.lower() in (".pdf", ".docx", ".txt")
    )
    if not files:
        print(f"No .pdf/.docx/.txt files found under {folder}")
        sys.exit(1)

    print(f"Loading spaCy + vocabulary ({len(ALL_SKILLS)} skill terms)...")
    nlp = spacy.load("en_core_web_sm")
    matcher = build_matcher(nlp)

    all_skill_counts = Counter()
    written = 0

    with open(output_file, "w", encoding="utf-8") as out:
        for i, path in enumerate(files, 1):
            print(f"\n[{i}/{len(files)}] {path.name}")
            try:
                text = extract_text(path)
            except Exception as e:
                print(f"  Skipped — could not extract text: {e}")
                continue

            if not text.strip():
                print("  Skipped — 0 characters extracted (scanned/image PDF?)")
                continue

            doc = nlp(text)
            matches = matcher(doc)
            spans = dedupe_overlapping([doc[start:end] for _, start, end in matches])

            skill_texts = [span.text for span in spans]
            all_skill_counts.update(s.lower() for s in skill_texts)

            print(f"  Found {len(spans)} skill mentions: {', '.join(sorted(set(skill_texts))) or '(none)'}")

            out.write(
                json.dumps(
                    {
                        "file": path.name,
                        "text": text,
                        "skills": [
                            {"text": span.text, "start": span.start_char, "end": span.end_char}
                            for span in spans
                        ],
                    },
                    ensure_ascii=False,
                )
                + "\n"
            )
            written += 1

    print(f"\n{'=' * 60}")
    print(f"Processed {written}/{len(files)} files -> {output_file}")
    print(f"\nTop 20 most common skill matches (spot-check these first):")
    for skill, count in all_skill_counts.most_common(20):
        print(f"  {count:4d}  {skill}")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
