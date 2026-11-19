"""
Scores the laptop service's extractor (extractor.py) on the HARD fake resumes, the same way the app's
regex parser is scored by test/resume_parser_hard_test.dart.

    python eval/generate_hard.py 600 4242
    python eval/score_hard_python.py

The skills come from the Skills-heading rules only ("section" mode), like the Dart parser.
"""

from __future__ import annotations

import json
import os
import re
import sys
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

import extractor  # noqa: E402


def norm(s) -> str:
    return re.sub(r"[^a-z0-9]+", " ", str(s or "").lower()).strip()


def digits(s) -> str:
    return re.sub(r"\D", "", str(s or ""))


def contains_either(pred, truth) -> bool:
    p, t = norm(pred), norm(truth)
    return bool(p) and (p in t or t in p)


def main() -> None:
    data = json.load(open(os.path.join(HERE, "hard_resumes.json"), encoding="utf-8"))
    total = defaultdict(int)
    correct = defaultdict(int)
    bad = defaultdict(lambda: [0, 0, ""])
    for r in data:
        t, v = r["truth"], r["variants"]
        p = extractor.parse(r["text"], skills_mode="section")
        want_phone, got_phone = digits(t["phone"]), digits(p.phone)
        truth_sk, pred_sk = {norm(s) for s in t["skills"]}, {norm(s) for s in p.skills}
        truth_w = {(norm(w["position"]), norm(w["companyName"])) for w in t["workExperience"]}
        pred_w = {(norm(w.position), norm(w.companyName)) for w in p.workExperience}
        checks = {
            "fullName": (v["name"], norm(p.fullName) == norm(t["fullName"]), f"got {p.fullName!r} want {t['fullName']!r}"),
            "phone": (v["phone"], len(got_phone) >= 9 and got_phone[-9:] == want_phone[-9:], f"got {p.phone!r} want {t['phone']!r}"),
            "address": (v["address"], contains_either(p.address, t["address"]), f"got {p.address!r}"),
            "dateOfBirth": (v["dob"], p.dateOfBirth == t["dateOfBirth"], f"got {p.dateOfBirth!r} want {t['dateOfBirth']!r}"),
            "programme": (v["programme"], contains_either(p.programme, t["programme"]), f"got {p.programme!r}"),
            "faculty": (v["programme"], contains_either(p.faculty, t["faculty"]), f"got {p.faculty!r}"),
            "semester": (v["semester"], p.semester == t["semester"], f"got {p.semester!r} want {t['semester']!r}"),
            "cgpa": (v["cgpa"], p.cgpa is not None and abs(p.cgpa - t["cgpa"]) < 0.005, f"got {p.cgpa!r} want {t['cgpa']!r}"),
            "skills (exact set)": (v["skills"], truth_sk == pred_sk, f"missing {sorted(truth_sk - pred_sk)} extra {sorted(pred_sk - truth_sk)}"),
            "work history (exact set)": (v["work"], truth_w == pred_w, f"want {sorted(truth_w)} got {sorted(pred_w)}"),
        }
        for field, (variant, ok, why) in checks.items():
            total[field] += 1
            correct[field] += ok
            if not ok:
                bad[(field, variant)][0] += 1
                bad[(field, variant)][2] = why
    print("| Field | Correct |")
    for field in total:
        print(f"| {field} | {100 * correct[field] / total[field]:.1f}% ({correct[field]}/{total[field]}) |")
    if bad:
        print("\nFailing habits:")
        for (field, variant), (n, _, why) in sorted(bad.items(), key=lambda kv: -kv[1][0])[:15]:
            print(f"  {field} / {variant}: {n} wrong, e.g. {why}")


if __name__ == "__main__":
    main()
