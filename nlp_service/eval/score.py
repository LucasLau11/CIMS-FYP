"""
Scores every eval/predictions_*.json against the true answers and writes eval/RESULTS.md.

    python eval/score.py

Everything is automatic. Fields are scored only on the resumes whose layout actually prints them.

  exact fields   fullName, phone (digits), programme, faculty, semester, cgpa, dateOfBirth, address
                 -> accuracy = correct / resumes where the field is present
  skills         precision / recall / F1 over the set of skills (case-insensitive)
                 plus recall on the "unseen" skills that no word list contained
  work history   an entry counts as found when position AND company both match (case-insensitive);
                 precision / recall / F1 over entries
"""

from __future__ import annotations

import glob
import json
import os
import re
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))

NICE = {
    "dart_regex": "Regex only (the app's built-in parser)",
    "spacy_section": "spaCy service, skills from the Skills heading",
    "spacy_model": "spaCy service + trained SKILL model (model only)",
    "spacy_both": "spaCy service + trained SKILL model (model + heading, always)",
    "spacy_auto": "spaCy service, default: heading rules, trained model only if none found",
    "tf_model": "TensorFlow Lite model only (runs on the phone)",
    "tf_auto": "TensorFlow Lite on the phone: heading rules, model only if none found",
}


def norm(s) -> str:
    return re.sub(r"[^a-z0-9]+", " ", (s or "").lower()).strip()


def digits(s) -> str:
    return re.sub(r"\D", "", s or "")


def phone_ok(pred, truth) -> bool:
    p, t = digits(pred), digits(truth)
    return bool(p) and (p[-9:] == t[-9:])


def contains_either(pred, truth) -> bool:
    p, t = norm(pred), norm(truth)
    return bool(p) and (p in t or t in p)


def prf(tp: int, fp: int, fn: int) -> tuple[float, float, float]:
    p = tp / (tp + fp) if tp + fp else 0.0
    r = tp / (tp + fn) if tp + fn else 0.0
    f = 2 * p * r / (p + r) if p + r else 0.0
    return p, r, f


def score_one(preds: dict, data: list[dict]) -> dict:
    exact = defaultdict(lambda: [0, 0])  # field -> [correct, total]
    sk = defaultdict(lambda: [0, 0, 0])  # layout/all -> tp, fp, fn
    unseen = [0, 0]
    wk = [0, 0, 0]
    for r in data:
        t, scored, pr = r["truth"], r["scored"], preds.get(str(r["id"]), {})
        checks = {
            "fullName": lambda: norm(pr.get("fullName")) == norm(t["fullName"]),
            "phone": lambda: phone_ok(pr.get("phone"), t["phone"]),
            "programme": lambda: contains_either(pr.get("programme"), t["programme"]),
            "faculty": lambda: contains_either(pr.get("faculty"), t["faculty"]),
            "semester": lambda: pr.get("semester") == t["semester"],
            "cgpa": lambda: pr.get("cgpa") is not None and abs(float(pr["cgpa"]) - t["cgpa"]) < 0.005,
            "dateOfBirth": lambda: pr.get("dateOfBirth") is not None and str(pr["dateOfBirth"])[:10] == t["dateOfBirth"],
            "address": lambda: contains_either(pr.get("address"), t["address"]),
        }
        for field, fn in checks.items():
            if scored.get(field):
                exact[field][1] += 1
                exact[field][0] += bool(fn())

        truth_sk = {norm(s) for s in t["skills"]}
        pred_sk = {norm(s) for s in pr.get("skills", [])}
        tp, fp, fn_ = len(truth_sk & pred_sk), len(pred_sk - truth_sk), len(truth_sk - pred_sk)
        for key in ("all", r["layout"]):
            sk[key][0] += tp
            sk[key][1] += fp
            sk[key][2] += fn_
        for s in t["unseenSkills"]:
            unseen[1] += 1
            unseen[0] += norm(s) in pred_sk

        truth_w = {(norm(w["position"]), norm(w["companyName"])) for w in t["workExperience"]}
        pred_w = {(norm(w.get("position")), norm(w.get("companyName"))) for w in pr.get("workExperience", [])}
        wk[0] += len(truth_w & pred_w)
        wk[1] += len(pred_w - truth_w)
        wk[2] += len(truth_w - pred_w)
    return {"exact": exact, "skills": sk, "unseen": unseen, "work": wk}


def main() -> None:
    data = json.load(open(os.path.join(HERE, "synthetic_resumes.json"), encoding="utf-8"))
    results = {}
    for path in sorted(glob.glob(os.path.join(HERE, "predictions_*.json"))):
        blob = json.load(open(path, encoding="utf-8"))
        results[blob["name"]] = (score_one(blob["predictions"], data), blob.get("seconds_per_resume"))
    if not results:
        raise SystemExit("No predictions_*.json found. Run predict_python.py (and the Dart benchmark) first.")

    order = [n for n in ("dart_regex", "spacy_section", "spacy_model", "spacy_both", "spacy_auto", "tf_model", "tf_auto") if n in results]
    layouts = sorted({r["layout"] for r in data})
    pct = lambda a, b: f"{100 * a / b:.0f}%" if b else "-"

    md = []
    md.append("# Resume parser accuracy on fake resumes\n")
    md.append(f"{len(data)} generated resumes in {len(layouts)} layouts, with the true answers stored beside them. Scored automatically; nobody labelled anything by hand.\n")
    md.append("These are generated resumes: the numbers show how each parser copes with these layouts, not how it does on every real resume.\n")
    md.append("## Fields that must match exactly\n")
    fields = ["fullName", "phone", "programme", "faculty", "semester", "cgpa", "dateOfBirth", "address"]
    md.append("| Parser | " + " | ".join(fields) + " |")
    md.append("|---|" + "---|" * len(fields))
    for n in order:
        ex = results[n][0]["exact"]
        md.append(f"| {NICE[n]} | " + " | ".join(pct(*ex[f]) if ex[f][1] else "-" for f in fields) + " |")

    md.append("\n## Skills (set of skills per resume)\n")
    md.append("| Parser | Precision | Recall | F1 | Recall on unseen skills |")
    md.append("|---|---|---|---|---|")
    for n in order:
        r = results[n][0]
        p, rc, f = prf(*r["skills"]["all"])
        u = r["unseen"]
        md.append(f"| {NICE[n]} | {p:.2f} | {rc:.2f} | {f:.2f} | {pct(u[0], u[1])} ({u[0]}/{u[1]}) |")

    md.append("\n### Skills F1 by layout\n")
    md.append("| Parser | " + " | ".join(layouts) + " |")
    md.append("|---|" + "---|" * len(layouts))
    for n in order:
        r = results[n][0]
        md.append(f"| {NICE[n]} | " + " | ".join(f"{prf(*r['skills'][l])[2]:.2f}" for l in layouts) + " |")

    md.append("\n## Work history (position + company both right)\n")
    md.append("| Parser | Precision | Recall | F1 |")
    md.append("|---|---|---|---|")
    for n in order:
        p, rc, f = prf(*results[n][0]["work"])
        md.append(f"| {NICE[n]} | {p:.2f} | {rc:.2f} | {f:.2f} |")

    md.append("\n## Speed\n")
    md.append("| Parser | Seconds per resume |")
    md.append("|---|---|")
    for n in order:
        md.append(f"| {NICE[n]} | {results[n][1] if results[n][1] is not None else '-'} |")

    text = "\n".join(md) + "\n"
    open(os.path.join(HERE, "RESULTS.md"), "w", encoding="utf-8").write(text)
    print(text)


if __name__ == "__main__":
    main()
