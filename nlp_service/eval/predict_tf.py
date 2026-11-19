"""
Scores the TensorFlow Lite tagger on the fake resumes. Run with the .venv-tf Python:

    .venv-tf/Scripts/python eval/predict_tf.py

(run eval/predict_python.py first: the fields other than skills are copied from it, because the
TensorFlow model only finds skills, and the spaCy packages are not installed in .venv-tf.)

Writes eval/predictions_tf_model.json  (skills from the TensorFlow model only)
       eval/predictions_tf_auto.json   (the Skills-heading rules first, the TensorFlow model only if
                                        the rules find nothing - the same plan as the spaCy default)
"""

from __future__ import annotations

import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, ROOT)

import tf_skills  # noqa: E402


def main() -> None:
    data = json.load(open(os.path.join(HERE, "synthetic_resumes.json"), encoding="utf-8"))
    base = json.load(open(os.path.join(HERE, "predictions_spacy_section.json"), encoding="utf-8"))["predictions"]
    tagger = tf_skills.tagger()
    if tagger is None:
        raise SystemExit("No TensorFlow Lite model yet: run tf_model/train_tf.py train, then export.")

    t0 = time.time()
    tf_skills_by_id = {str(r["id"]): tagger.extract(r["text"]) for r in data}
    seconds = round((time.time() - t0) / len(data), 4)

    for name, pick in (
        ("tf_model", lambda rid: tf_skills_by_id[rid]),
        ("tf_auto", lambda rid: base[rid]["skills"] or tf_skills_by_id[rid]),
    ):
        preds = {rid: {**p, "skills": pick(rid)} for rid, p in base.items()}
        json.dump({"name": name, "seconds_per_resume": seconds, "predictions": preds},
                  open(os.path.join(HERE, f"predictions_{name}.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)
        print(f"{name}: {len(preds)} resumes written")


if __name__ == "__main__":
    main()
