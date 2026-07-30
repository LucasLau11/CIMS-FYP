"""
Phase B, step 1.5 — randomly samples N resumes per category from the
bootstrap-tagged *.jsonl files into one combined file, ready for
review_skills.py. Lets you review a representative slice (~15-20 per
category) instead of all ~2,500 resumes across every category.

Usage:
    python sample_for_review.py --per-category 20
    python sample_for_review.py --per-category 20 --output sample.jsonl file1.jsonl file2.jsonl ...

If no input files are given, picks up every *.jsonl in the current folder
except the sampler's own output and anything named reviewed_*.jsonl (so it
won't accidentally re-sample your review progress).

Uses a fixed random seed, so re-running with the same inputs/count is
reproducible rather than picking a different random slice each time.
"""

import json
import random
import sys
from pathlib import Path

DEFAULT_OUTPUT = "sample_for_review.jsonl"
DEFAULT_PER_CATEGORY = 20
SEED = 42


def discover_input_files(output_file: str):
    return sorted(
        f
        for f in Path(".").glob("*.jsonl")
        if f.name != output_file and not f.name.startswith("reviewed_")
    )


def main():
    args = sys.argv[1:]

    per_category = DEFAULT_PER_CATEGORY
    if "--per-category" in args:
        idx = args.index("--per-category")
        per_category = int(args[idx + 1])
        del args[idx : idx + 2]

    output_file = DEFAULT_OUTPUT
    if "--output" in args:
        idx = args.index("--output")
        output_file = args[idx + 1]
        del args[idx : idx + 2]

    input_files = [Path(f) for f in args] if args else discover_input_files(output_file)
    if not input_files:
        print("No input .jsonl files found.")
        sys.exit(1)

    rng = random.Random(SEED)
    total_written = 0

    with open(output_file, "w", encoding="utf-8") as out:
        for path in input_files:
            category = path.stem
            with open(path, encoding="utf-8") as f:
                lines = [line.strip() for line in f if line.strip()]

            chosen = rng.sample(lines, min(per_category, len(lines)))
            for line in chosen:
                rec = json.loads(line)
                rec["category"] = category
                out.write(json.dumps(rec, ensure_ascii=False) + "\n")

            print(f"{category:25s} sampled {len(chosen):3d} / {len(lines)}")
            total_written += len(chosen)

    print(f"\n{'=' * 60}")
    print(f"Wrote {total_written} resumes across {len(input_files)} categories -> {output_file}")
    print(f"Next: python review_skills.py {output_file}")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
