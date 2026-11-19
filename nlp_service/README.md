# CIMS resume NLP service

A small FastAPI service that reads the text of a resume and returns the fields the app pre-fills
(name, phone, programme, faculty, CGPA, skills, work history). The Flutter app calls it through
`ResumeParserService.parseViaNlp` and falls back to its own built-in regex parser when the service
cannot be reached.

```
pip install -r requirements.txt
python -m spacy download en_core_web_sm
uvicorn app:app --port 8000                 # local
NGROK_AUTHTOKEN=... uvicorn app:app --port 8000   # also prints a public URL for the phone
```

## How a resume is read

| Field | How |
|---|---|
| name | "the first lines look like a name" rule (titles such as *Ms.*, *Encik* and Malaysian *a/l*, *a/p* handled); the pretrained spaCy NER only as a fallback |
| phone, address, date of birth, programme, faculty, semester, CGPA | labelled-field and pattern rules |
| work history | date-range anchors; "Position at Company" and "Position, Company" splits |
| skills | 1. the list under a Skills-type heading, or a one-line "Skills: a, b, c"; 2. **only if that finds nothing**, the trained SKILL model |

## The trained SKILL model (no manual labeling)

A spaCy named-entity model trained on this laptop's CPU from about 2,500 real resumes in `*.jsonl`
(the Kaggle "Resume Dataset"). **Nobody labelled anything by hand**; the labels come from the resumes
themselves:

1. `skill_labels.py` finds the list under each resume's own *Skills* / *Highlights* / *Core
   competencies* heading. Those list items are skills by structure.
2. A phrase only counts if it is listed as a skill in **at least 3 different resumes** (agreement
   between unrelated people replaces manual review), and a single plain word must be listed as a
   skill in a good share of the resumes that contain it at all.
3. The same distinctive phrase is also labelled where it appears inside sentences of that resume.
4. Resumes are cut into short chunks. The training split also gets the same chunks written in other
   layouts (CAPITAL headings, bullets), so the model does not depend on one layout.

```
python train/prepare_data.py          # builds train/dev/test .spacy files (split by resume)
python -m spacy train train/config.cfg --output models/skill_ner \
   --paths.train train/train.spacy --paths.dev train/dev.spacy \
   --training.max_steps 9000 --training.eval_frequency 500 --training.patience 3000
python -m spacy evaluate models/skill_ner/model-best train/test.spacy
```

Held-out test resumes (never seen in training): **precision 84.0, recall 88.5, F1 86.2**. Be careful
with that number: it measures agreement with the automatic labels, not with a person's judgement.

## Accuracy test on fake resumes (also automatic)

`eval/generate_synthetic.py` writes resumes in 7 layouts with the true answers stored beside them.
Every parser is scored the same way:

```
python eval/generate_synthetic.py 350 2026
flutter test test/resume_parser_benchmark_test.dart        # the app's regex parser   (run from the project root)
python eval/predict_python.py                              # the spaCy service, 4 skill modes
python eval/score.py                                       # writes eval/RESULTS.md
```

See `eval/RESULTS.md` for the tables. Honest reading of them:

* The fake resumes are simple, and the parsers were corrected against the failures the test found
  (inline "Skills:", faculty lines, titles, "Position, Company"), so scores of 100% on names, phone
  and work history say the layouts are handled, **not** that every real resume is.
* For resumes with a skills list the heading rules are already as good as it gets here (F1 0.90 to
  1.00); the trained model alone is weaker (F1 0.52) and does not recognise skills it never saw in
  its training resumes (7% of the unseen ones).
* Its value is resumes with **no** skills list, where the rules find nothing: F1 0.00 to 0.24. That is why
  the default tries the rules first and the model second.
* The model was trained on general-purpose resumes (accountants, chefs, HR ...). More IT-student
  resumes would help it most.

## The TensorFlow model (runs ON THE PHONE, no server)

A second skill model, trained from scratch with TensorFlow/Keras on the same automatic labels and
the same train / dev / test resumes, then exported to TensorFlow Lite so the app can run it offline.
spaCy cannot be used for this: it has no build for Android (its `blis` dependency does not support
ARM), which is why this model exists at all.

Model (`tf_model/train_tf.py`): per token, a learned word embedding plus a small character CNN (so
capitals, digits, ".js" or "++" help it recognise skill-like words it never saw), then four dilated
1-D convolutions and a softmax over outside / first-token-of-a-skill / inside-a-skill. Only built-in
TensorFlow Lite operations, so the app needs no extra native libraries beyond `tflite_flutter`.

```
.venv/Scripts/python tf_model/prepare_tf_data.py       # same data as spaCy, as numbers   (the spaCy env)
python -m venv .venv-tf && .venv-tf/Scripts/pip install tensorflow-cpu numpy
.venv-tf/Scripts/python tf_model/train_tf.py train      # about 8 min per epoch on a laptop CPU
.venv-tf/Scripts/python tf_model/tune_threshold.py      # decision threshold picked on DEV, test scored once
.venv-tf/Scripts/python tf_model/train_tf.py export     # tf_model/artifacts/skill_tagger.tflite
.venv-tf/Scripts/python eval/predict_tf.py && .venv/Scripts/python eval/score.py
```

Results (the best checkpoint was epoch 3 of a run stopped at epoch 5, because the dev score had
stopped improving):

| | held-out resumes (exact span F1) | fake resumes, skills only (F1) | unseen skills found | size |
|---|---|---|---|---|
| spaCy SKILL model | **0.862** | 0.52 | 7% | 14 MB |
| TensorFlow model (TensorFlow Lite) | 0.760 (precision 0.68, recall 0.86) | 0.44 | **22%** | **2.1 MB** |

* The TensorFlow Lite file gives the same answers as the Keras model it came from (F1 0.757 against 0.759 on 600 test chunks).
* It is clearly **weaker than the spaCy model** on the held-out resumes. Its advantages are that it
  runs on the phone with no server, is small, and is trained entirely from this project's own data;
  it also finds more skills it never saw (the character CNN), on the fake resumes.
* In the app it is only the second try, after the regex parser (`ResumeParserService.parseOnDevice`),
  exactly like the spaCy model on the laptop. With the rules first, both give skills F1 0.91 on the fake resumes.
* The phone-side text handling (`lib/utils/skill_text_encoding.dart`) is a line-for-line twin of
  `tf_model/text_encoding.py`; `test/skill_text_encoding_test.dart` checks it against answers
  written by the Python code (`python tf_model/make_golden.py`). **Running the model on a real phone
  has not been tested yet**: it needs a device, and the app now requires Android 8.0 or newer.

## Tests

```
python -m unittest discover -s tests     # labelling code and the layouts the extractor used to get wrong
flutter test test/skill_text_encoding_test.dart test/resume_parser_fixes_test.dart   # from the project root
```

## A harder accuracy test (regex improvements)

The first fake-resume set scores 100%, so it can no longer show an improvement. `eval/generate_hard.py`
makes 600 resumes that use the habits of real student resumes (title lines, "Name:" labels, phones and CGPA
written many ways, dates of birth like "12th March 2002", "Sem 3", skills with levels and slashes,
"Industrial Training" sections, months inside one year ...), recording which habit each used.

```
python eval/generate_hard.py 600 4242
flutter test test/resume_parser_hard_test.dart        # the app's regex parser  -> eval/HARD_RESULTS.md
python eval/score_hard_python.py                      # this service's extractor
```

Measured before the regex was improved (app parser, 600 resumes): name 34%, address 65%, date of birth 42%,
semester 84%, CGPA 64%, skills (whole set right) 12%, work history (whole set right) 36%. After: 100% on all,
in the app and in `extractor.py`. Caution: the habits were written by the same person who then fixed the parser,
so 100% means these habits are handled, not that real resumes are. On 240 real (US-style) resumes the name
rule was also made stricter, because it used to accept job titles and skills as names.
