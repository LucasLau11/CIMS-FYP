"""
Runs the Python extractor on the fake resumes and saves what it found.

    python eval/predict_python.py

Writes eval/predictions_<name>.json for each way of finding skills:
    spacy_section   items under a Skills heading only (how it worked before the trained model)
    spacy_model     only what the trained SKILL model finds
    spacy_both      the two combined
    spacy_auto      heading rules first, the model only when the rules find no skills (the default)
The names, phone, programme etc. come from the same code in all three, so only skills differ.
"""

from __future__ import annotations

import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, ROOT)

import extractor  # noqa: E402
import skills_model  # noqa: E402


def to_json(parsed) -> dict:
    return {
        "fullName": parsed.fullName,
        "phone": parsed.phone,
        "address": parsed.address,
        "dateOfBirth": parsed.dateOfBirth,
        "programme": parsed.programme,
        "faculty": parsed.faculty,
        "semester": parsed.semester,
        "cgpa": parsed.cgpa,
        "skills": parsed.skills,
        "workExperience": [
            {"position": w.position, "companyName": w.companyName, "startYear": w.startYear, "endYear": w.endYear, "isCurrent": w.isCurrent}
            for w in parsed.workExperience
        ],
    }


def main() -> None:
    data = json.load(open(os.path.join(HERE, "synthetic_resumes.json"), encoding="utf-8"))
    modes = {"spacy_section": "section", "spacy_model": "model", "spacy_both": "both", "spacy_auto": "auto"}
    if not skills_model.available():
        print("The trained skill model is not there yet: only 'spacy_section' will be meaningful.")
        modes = {"spacy_section": "section"}
    for name, mode in modes.items():
        t0 = time.time()
        preds = {str(r["id"]): to_json(extractor.parse(r["text"], skills_mode=mode)) for r in data}
        out = {"name": name, "seconds_per_resume": round((time.time() - t0) / len(data), 4), "predictions": preds}
        json.dump(out, open(os.path.join(HERE, f"predictions_{name}.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)
        print(f"{name}: {len(data)} resumes, {out['seconds_per_resume']}s each")


if __name__ == "__main__":
    main()
