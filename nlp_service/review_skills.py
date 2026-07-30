"""
Phase B, step 2 — interactive review/correction of the bootstrap-tagged
skill spans from bootstrap_label_skills.py.

For each resume, shows every auto-tagged skill with a bit of surrounding
text so you can judge it in context, then asks two quick questions: which
(if any) are wrong, and what (if any) got missed. One decision-point per
resume, not per match — fast path is just hitting Enter twice to accept
everything, drop into corrections only when something looks off.

Usage:
    python review_skills.py labeled_it.jsonl labeled_design.jsonl ...
    python review_skills.py labeled_it.jsonl --output reviewed_skills.jsonl

Safe to stop and resume any time (Ctrl+C) — every reviewed resume is
written to the output file immediately, and re-running skips anything
already reviewed there.
"""

import json
import sys
from pathlib import Path

DEFAULT_OUTPUT = "reviewed_skills.jsonl"
CONTEXT_CHARS = 40


def load_records(input_files):
    records = []
    for path in input_files:
        fallback_category = Path(path).stem
        with open(path, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                rec = json.loads(line)
                # Records from sample_for_review.py already carry their own
                # per-resume category — only fall back to the source
                # filename's stem when reviewing a raw bootstrap file directly.
                rec.setdefault("category", fallback_category)
                records.append(rec)
    return records


def already_reviewed_keys(output_file):
    keys = set()
    if not Path(output_file).exists():
        return keys
    with open(output_file, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            rec = json.loads(line)
            keys.add((rec.get("category"), rec["file"]))
    return keys


def context_snippet(text: str, start: int, end: int) -> str:
    lo = max(0, start - CONTEXT_CHARS)
    hi = min(len(text), end + CONTEXT_CHARS)
    before = text[lo:start].replace("\n", " ")
    match = text[start:end]
    after = text[end:hi].replace("\n", " ")
    prefix = "..." if lo > 0 else ""
    suffix = "..." if hi < len(text) else ""
    return f"{prefix}{before}[{match}]{after}{suffix}"


def find_all_occurrences(text: str, needle: str):
    spans = []
    lower_text = text.lower()
    lower_needle = needle.lower()
    start = 0
    while True:
        idx = lower_text.find(lower_needle, start)
        if idx == -1:
            break
        spans.append({"text": text[idx : idx + len(needle)], "start": idx, "end": idx + len(needle)})
        start = idx + len(needle)
    return spans


def review_one(rec) -> dict:
    text = rec["text"]
    skills = rec["skills"]

    print(f"\n{'-' * 70}")
    print(f"{rec['category']} :: {rec['file']}  ({len(skills)} auto-tagged)")
    print(f"{'-' * 70}")
    if not skills:
        print("  (no matches found by the auto-tagger)")
    for i, s in enumerate(skills, 1):
        print(f"  [{i}] {context_snippet(text, s['start'], s['end'])}")

    remove_raw = input("\nRemove which numbers? (comma-separated, Enter = keep all): ").strip()
    remove_indexes = set()
    if remove_raw:
        for part in remove_raw.split(","):
            part = part.strip()
            if part.isdigit() and 1 <= int(part) <= len(skills):
                remove_indexes.add(int(part))
            else:
                print(f"  Ignoring invalid entry: {part!r}")

    kept = [s for i, s in enumerate(skills, 1) if i not in remove_indexes]

    add_raw = input("Add missed skills (comma-separated exact text, Enter = none): ").strip()
    added = []
    if add_raw:
        for skill_text in [s.strip() for s in add_raw.split(",") if s.strip()]:
            occurrences = find_all_occurrences(text, skill_text)
            if not occurrences:
                print(f"  Could not find {skill_text!r} in the text — skipped.")
                continue
            added.extend(occurrences)
            print(f"  Added {skill_text!r} at {len(occurrences)} location(s).")

    # De-dupe in case an added skill overlaps something already kept.
    final = kept + [a for a in added if not any(a["start"] == k["start"] and a["end"] == k["end"] for k in kept)]
    final.sort(key=lambda s: s["start"])

    return {"category": rec["category"], "file": rec["file"], "text": text, "skills": final}


def main():
    args = sys.argv[1:]
    if not args:
        print("Usage: python review_skills.py labeled_a.jsonl [labeled_b.jsonl ...] [--output out.jsonl]")
        sys.exit(1)

    output_file = DEFAULT_OUTPUT
    if "--output" in args:
        idx = args.index("--output")
        output_file = args[idx + 1]
        del args[idx : idx + 2]

    input_files = args
    for f in input_files:
        if not Path(f).exists():
            print(f"File not found: {f}")
            sys.exit(1)

    records = load_records(input_files)
    done = already_reviewed_keys(output_file)
    todo = [r for r in records if (r["category"], r["file"]) not in done]

    print(f"Loaded {len(records)} resumes across {len(input_files)} file(s).")
    print(f"Already reviewed: {len(done)}. Remaining: {len(todo)}.")
    if not todo:
        print("Nothing left to review.")
        return

    reviewed_count = len(done)
    try:
        with open(output_file, "a", encoding="utf-8") as out:
            for rec in todo:
                reviewed_count += 1
                print(f"\n[{reviewed_count}/{len(records)}]", end="")
                result = review_one(rec)
                out.write(json.dumps(result, ensure_ascii=False) + "\n")
                out.flush()
    except KeyboardInterrupt:
        print(f"\n\nStopped. Progress saved to {output_file} — re-run this same command to resume.")
        sys.exit(0)

    print(f"\nAll done. {reviewed_count} resumes reviewed -> {output_file}")


if __name__ == "__main__":
    main()
