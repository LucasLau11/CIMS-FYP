# On-Device Resume Parser (Gemma via MediaPipe) — Design

**Status:** Approved for implementation (2026-08-18)
**Classification:** Architectural (per superpowers:brainstorming)

## Context

CIMS currently parses uploaded resumes via a hybrid two-tier system in
`lib/services/resume_parser_service.dart`:

1. **NLP tier** — an HTTP call to `nlp_service/`, a FastAPI + spaCy Python
   microservice, exposed publicly via an ngrok tunnel whose URL is stored
   on-device and editable at runtime (see `getNlpServiceUrl`/`setNlpServiceUrl`).
2. **Regex tier** — a local, no-network fallback that reliably catches
   clearly-labelled fields (e.g. "Phone: ...") but can't reliably parse
   unlabelled free-form text.

Every extracted field is always left editable by the student; parsing only
pre-fills, never silently overwrites.

## Problem

The ngrok tier requires the developer's own laptop to be running with an
active tunnel — the service silently stops working whenever that laptop or
tunnel isn't up. The stated goal is a resume parser that:

- Works **fully offline** — no server, no hosting, no ngrok
- Costs **nothing** — no billing, no paid API
- Genuinely uses **NLP machine learning** (not just regex/keyword matching)
- Needs **no labeled training dataset** — none exists, and building one is
  out of scope for now
- Only needs to support **Android** (no iOS requirement in this project)

## Investigation (what was ruled out, and why)

| Option | Verdict | Reason |
|---|---|---|
| On-device TFLite, custom-trained NER | Ruled out | No labeled dataset, and building one (200+ hand-tagged resumes) is out of scope |
| Hand-converted TFLite NER (pretrained BERT-style model, manually converted) | Ruled out | No ready-made Flutter package or pretrained model for this; real, open-ended conversion/tokenizer-parity risk with no guarantee of a working result |
| Better hosting for the existing FastAPI + spaCy service (Render, HF Spaces, Cloud Run, etc.) | Ruled out | Doesn't satisfy "fully offline" — still depends on a remote server being reachable |
| Google ML Kit Entity Extraction + regex + bundled skill-dictionary | Set aside | Genuinely free, on-device, no training needed — but only recognizes a fixed set of entity types (phone, address, date, email, etc.); doesn't extract skills, name, or work-experience blocks, which was the whole point of moving beyond regex. Doesn't read as "NLP machine learning" for the project's needs. |
| **Run the existing spaCy code on-device via Chaquopy** | **Ruled out — confirmed empirically** | Spiked directly (see below): spaCy has no build for Android ARM in Chaquopy's package index at all, because its `blis` dependency doesn't support ARM/ARM64. This is permanent, not a version/config issue. |
| **On-device LLM (Gemma) via MediaPipe/LiteRT** | **Selected** | Real trained ML model, runs fully on-device once downloaded, free/open weights, no training required (used via prompting), Android support via the `flutter_gemma` package, and is genuinely TensorFlow Lite (LiteRT) under the hood. |

### Spike evidence: Chaquopy + spaCy

A throwaway Gradle spike (Chaquopy plugin added to `android/app/build.gradle.kts`,
`pip { install("spacy") }`, target `arm64-v8a`) was run against the real
Chaquopy package index. Build output:

```
Chaquopy: Installing for arm64-v8a
ERROR: Could not find a version that satisfies the requirement spacy (from versions: none)
ERROR: No matching distribution found for spacy
```

No spaCy distribution exists for Android ARM. The spike changes were reverted
in full after this result (nothing from the spike remains in the codebase).

## Decision

Replace the NLP tier's remote HTTP call with an **on-device Gemma call** via
the `flutter_gemma` package (MediaPipe LLM Inference API / LiteRT runtime).
The regex tier is unchanged and remains the fallback.

### Known trade-offs, accepted going in

- **App size**: the Gemma model file (even quantized) is several hundred MB,
  downloaded on first use rather than bundled in the APK.
- **Latency**: on-device LLM inference takes seconds, not milliseconds —
  slower than the old network call typically was and slower than a small
  dedicated NER model would be.
- **Non-determinism**: extraction happens by prompting the model for a JSON
  object and parsing its response, not by a deterministic classifier. Output
  must be validated before use; the regex fallback exists precisely to catch
  the cases where it isn't.
- **API surface risk**: Google's own docs flag the MediaPipe LLM Inference
  API as being superseded by "LiteRT-LM." The underlying capability (on-device
  Gemma via LiteRT) is expected to remain available either way; the exact
  package/API name may need to be re-checked at implementation time.

## Academic fallback (explicit, deliberate)

If the project's supervisor requires a **self-trained** NLP model rather
than an integrated pretrained one, the following stays in place specifically
to make that pivot possible without starting over:

- **`nlp_service/` (FastAPI + spaCy) is not deleted.** It remains in the repo
  untouched as the base to extend if custom training becomes a requirement.
- **Task "NLP Phase B: skills dataset + custom NER training" stays pending**,
  not cancelled or superseded.
- **If that path is taken, train in TensorFlow/Keras, not spaCy.** The spike
  above proved spaCy can never reach on-device TFLite (the `blis`/ARM
  incompatibility is permanent). A TensorFlow-trained model has no such
  blocker and converts to real TFLite/LiteRT cleanly — so choosing
  TensorFlow for any future custom training keeps "genuinely on-device"
  achievable, which spaCy never could deliver.

This means the codebase intentionally carries two dormant/parallel NLP
assets after this change: the new on-device Gemma path (active) and the
existing `nlp_service/` project (dormant, preserved as a fallback starting
point). This is a deliberate decision, not leftover cruft.

## Design

### Data flow

1. Extract resume text — unchanged (Syncfusion for PDF, `docx_to_text` for DOCX).
2. Prompt Gemma with the extracted text, requesting a fixed JSON schema:
   `fullName`, `phone`, `address`, `dateOfBirth`, `programme`, `faculty`,
   `semester`, `cgpa`, `skills[]`, `workExperience[]` (each with `position`,
   `companyName`, `startYear`, `endYear`, `isCurrent`, `description`) —
   matching `ParsedResumeData`/`ParsedWorkExperience`'s existing shape.
3. Parse the model's response as JSON and validate it against the expected
   shape (required keys present, correct types, no obviously garbage values).
4. **If valid** → return as `ParsedResumeData(..., source: 'gemma')`.
   **If the call fails, times out, or the response doesn't validate** → fall
   through to the existing regex parser, `source: 'regex'`, exactly as today.
5. Every field remains editable by the student regardless of source — no
   behavior change here from the current app.

### Components touched

- `lib/services/resume_parser_service.dart` — replace the HTTP-to-`nlp_service`
  call with the on-device Gemma call; keep `parseWithRegexFallback` unchanged;
  update the `source` field's values from `'nlp' | 'regex'` to `'gemma' | 'regex'`.
- Remove the on-device "NLP service URL" setting (the editable ngrok URL
  field) from wherever it's currently surfaced in Settings/Profile, since
  there is no remote endpoint to configure anymore.
- Add the `flutter_gemma` dependency and the Gemma model download/initialization
  flow. Default choice: the smallest available Gemma variant suitable for
  instruction-following (e.g. Gemma 3 1B), INT4/INT8-quantized, downloaded
  on first use rather than bundled in the APK — this keeps the base install
  size unchanged and only costs the download to students who actually use
  resume parsing. The implementation plan should verify the exact current
  model name/format against `flutter_gemma`'s documentation at build time,
  since Google's model naming and the LiteRT-LM transition noted above may
  have moved since this spec was written.
- `nlp_service/` — **no changes**, preserved as-is per the academic fallback above.

### Error handling

- Network/model-load failure, malformed JSON, or a validation failure on the
  parsed shape are all treated identically: log (non-fatal) and fall through
  to the regex parser. The user never sees a hard failure from this path —
  worst case, they get the same regex-only experience the app already has
  today when the NLP tier is unavailable.

### Testing approach

- Unit-level: JSON-schema validation function tested against valid, partially
  valid, and garbage LLM output to confirm the fallback triggers correctly.
- Manual: run real sample resumes (PDF and DOCX) through the on-device path
  on an Android device/emulator, confirm extracted fields populate correctly
  and remain editable, and confirm the fallback actually engages when the
  model is deliberately made to fail (e.g., airplane mode during first-time
  model download, to distinguish "model unavailable" from "model returned
  bad output").

## Out of scope for this change

- Training or fine-tuning any model (see Academic fallback above — this is
  the trigger condition for a *future*, separate piece of work, not part of
  this one).
- iOS support (confirmed not required for this project).
- Removing or archiving `nlp_service/`.
