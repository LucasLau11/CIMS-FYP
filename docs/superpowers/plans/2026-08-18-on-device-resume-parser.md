# On-Device Resume Parser (Gemma) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the ngrok-tunneled FastAPI+spaCy NLP tier in `resume_parser_service.dart` with an on-device Gemma LLM call via the `flutter_gemma` package, keeping the existing regex parser as the automatic fallback.

**Architecture:** A new `GemmaResumeExtractor` singleton owns the entire Gemma lifecycle (engine init, model download with progress, prompting, JSON parsing/validation) as a self-contained unit — `resume_parser_service.dart` stays regex-only and untouched except for removing the dead ngrok-URL plumbing. The student profile screen orchestrates: try Gemma (downloading the model on first use, with user consent) → on any failure fall through to the untouched regex parser, exactly as today's `parseViaNlp` → `parse` fallback already works.

**Tech Stack:** Flutter/Dart, `flutter_gemma` ^1.5.9 (on-device LLM runtime), `flutter_gemma_litertlm` (LiteRT-LM inference engine, recommended for Android), Gemma 3 1B IT model (~0.5GB, `.litertlm` format, downloaded on first use from Hugging Face).

**Spec:** [docs/superpowers/specs/2026-08-18-on-device-resume-parser-design.md](../specs/2026-08-18-on-device-resume-parser-design.md)

## Global Constraints

- Must work fully offline at inference time — no server, no hosting, no ngrok.
- Must cost nothing — no billing, no paid API.
- Must be genuine on-device ML (Gemma), not just regex/keyword matching.
- No training required — uses a pretrained model via prompting.
- Android-only — no iOS work.
- `ParsedResumeData.source` values are exactly `'gemma'` or `'regex'` (renamed from `'nlp'`/`'regex'`).
- `nlp_service/` and task #88 ("NLP Phase B: skills dataset + custom NER training") are **not touched** — preserved as the academic fallback.
- Any Gemma-path failure (network/model-load/malformed JSON/validation failure) is non-fatal and silently falls through to the existing regex parser — the user never sees a hard failure from this path.
- Every extracted field remains editable by the student regardless of source — no UI behavior change here.
- The Gemma model is downloaded on first use, not bundled in the APK.

---

## File Structure

- **Create** `lib/services/gemma_resume_extractor.dart` — owns the Gemma engine lifecycle, model download, prompting, and JSON validation. Kept separate from `resume_parser_service.dart` so the existing regex-only file (already documented as "no AI/network calls involved") stays that way, and so the LLM lifecycle (which needs engine init, download progress, chat sessions) doesn't blur into the regex extractors' single responsibility.
- **Create** `test/gemma_resume_extractor_test.dart` — unit tests for the pure JSON-validation function (no model/device needed).
- **Modify** `lib/services/resume_parser_service.dart` — remove `parseViaNlp`, `getNlpServiceUrl`, `setNlpServiceUrl`, `_defaultNlpServiceBaseUrl`, `_nlpServiceUrlPrefsKey`, and the now-unused `http`/`shared_preferences` imports. `extractText`, `parse`, and every private `_extract*` regex helper stay byte-for-byte unchanged.
- **Modify** `lib/screens/student/student_profile_screen.dart` — remove the dev-only `_showNlpServiceUrlEditor` and its long-press wiring; update `_offerResumeScan` to try `GemmaResumeExtractor` (with a download-consent + progress dialog on first use) before falling back to `ResumeParserService.instance.parse`.
- **Modify** `pubspec.yaml` — add `flutter_gemma` and `flutter_gemma_litertlm`.

---

## Task 1: `GemmaResumeExtractor` — JSON validation (TDD) + class skeleton

**Files:**
- Create: `lib/services/gemma_resume_extractor.dart`
- Create: `test/gemma_resume_extractor_test.dart`
- Modify: `pubspec.yaml`

**Interfaces:**
- Produces: `GemmaResumeExtractor.instance` (singleton), `Future<bool> isModelDownloaded()`, `Future<void> downloadModel({required void Function(int progress) onProgress})`, `Future<ParsedResumeData?> extract(String resumeText)`, and the static pure function `GemmaResumeExtractor.parseAndValidateJson(String raw) -> ParsedResumeData?` used directly by tests.
- Consumes: `ParsedResumeData` / `ParsedWorkExperience` from `lib/services/resume_parser_service.dart` (existing classes, unchanged — see their current definitions at `lib/services/resume_parser_service.dart:11-75`).

- [ ] **Step 1: Add the two new dependencies**

Edit `pubspec.yaml`, in the `dependencies:` block right after `http: ^1.2.2` (matches this project's existing one-line-per-package style):

```yaml
  http: ^1.2.2
  flutter_gemma: ^1.5.9
  flutter_gemma_litertlm: ^0.1.0
```

Run:
```bash
flutter pub get
```
Expected: resolves cleanly. If `flutter_gemma_litertlm` resolves to a different version than `^0.1.0`, accept whatever `flutter pub get` picks (it's a newer, fast-moving companion package to `flutter_gemma` — pin to whatever `pub get` resolves) and update the version constraint in `pubspec.yaml` to match.

- [ ] **Step 2: Write the failing tests for JSON validation**

Create `test/gemma_resume_extractor_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/services/gemma_resume_extractor.dart';

void main() {
  group('GemmaResumeExtractor.parseAndValidateJson', () {
    test('accepts a fully valid response', () {
      const raw = '''
      {"fullName": "Tan Wei Ming", "phone": "012-345 6789", "address": "12 Jalan Ampang, KL",
       "dateOfBirth": "2001-05-14", "programme": "Bachelor of Software Engineering",
       "faculty": "Faculty of Computing", "semester": 6, "cgpa": 3.65,
       "skills": ["Flutter", "Dart", "SQL"],
       "workExperience": [{"position": "Intern", "companyName": "Acme Sdn Bhd",
         "startYear": 2023, "endYear": 2024, "isCurrent": false, "description": "Built things"}]}
      ''';
      final result = GemmaResumeExtractor.parseAndValidateJson(raw);
      expect(result, isNotNull);
      expect(result!.fullName, 'Tan Wei Ming');
      expect(result.source, 'gemma');
      expect(result.skills, ['Flutter', 'Dart', 'SQL']);
      expect(result.workExperience, hasLength(1));
      expect(result.workExperience.first.companyName, 'Acme Sdn Bhd');
      expect(result.dateOfBirth, DateTime(2001, 5, 14));
    });

    test('accepts a partially-null response (still valid shape)', () {
      const raw = '''
      {"fullName": "Lee Mei Ling", "phone": null, "address": null, "dateOfBirth": null,
       "programme": null, "faculty": null, "semester": null, "cgpa": null,
       "skills": [], "workExperience": []}
      ''';
      final result = GemmaResumeExtractor.parseAndValidateJson(raw);
      expect(result, isNotNull);
      expect(result!.fullName, 'Lee Mei Ling');
      expect(result.phone, isNull);
      expect(result.skills, isEmpty);
      expect(result.source, 'gemma');
    });

    test('extracts JSON even when wrapped in prose or a code fence', () {
      const raw = '''
      Sure, here is the extracted data:
      ```json
      {"fullName": "Ali", "phone": null, "address": null, "dateOfBirth": null,
       "programme": null, "faculty": null, "semester": null, "cgpa": null,
       "skills": [], "workExperience": []}
      ```
      Let me know if you need anything else.
      ''';
      final result = GemmaResumeExtractor.parseAndValidateJson(raw);
      expect(result, isNotNull);
      expect(result!.fullName, 'Ali');
    });

    test('rejects malformed JSON', () {
      const raw = 'this is not json at all';
      expect(GemmaResumeExtractor.parseAndValidateJson(raw), isNull);
    });

    test('rejects JSON missing required keys', () {
      const raw = '{"fullName": "Ali"}';
      expect(GemmaResumeExtractor.parseAndValidateJson(raw), isNull);
    });

    test('rejects JSON where skills is not a list', () {
      const raw = '''
      {"fullName": null, "phone": null, "address": null, "dateOfBirth": null,
       "programme": null, "faculty": null, "semester": null, "cgpa": null,
       "skills": "Flutter, Dart", "workExperience": []}
      ''';
      expect(GemmaResumeExtractor.parseAndValidateJson(raw), isNull);
    });

    test('rejects JSON where a workExperience entry is not an object', () {
      const raw = '''
      {"fullName": null, "phone": null, "address": null, "dateOfBirth": null,
       "programme": null, "faculty": null, "semester": null, "cgpa": null,
       "skills": [], "workExperience": ["just a string"]}
      ''';
      expect(GemmaResumeExtractor.parseAndValidateJson(raw), isNull);
    });
  });
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run:
```bash
flutter test test/gemma_resume_extractor_test.dart
```
Expected: FAIL — `gemma_resume_extractor.dart` doesn't exist yet (import error).

- [ ] **Step 4: Implement `GemmaResumeExtractor`**

Create `lib/services/gemma_resume_extractor.dart`:

```dart
import 'dart:convert';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'resume_parser_service.dart' show ParsedResumeData, ParsedWorkExperience;

/// On-device Gemma-based resume extraction. Runs fully locally via the
/// `flutter_gemma` package (LiteRT-LM engine) after a one-time model
/// download — no server, no network calls at inference time. Every method
/// here is expected to be wrapped in a try/catch by the caller and fall
/// back to [ResumeParserService.parse] on any failure; nothing in this
/// class is allowed to leave the app in a broken state.
class GemmaResumeExtractor {
  GemmaResumeExtractor._();
  static final GemmaResumeExtractor instance = GemmaResumeExtractor._();

  /// Gemma 3 1B, instruction-tuned, LiteRT-LM format — the smallest Gemma
  /// variant suitable for instruction-following, per the design spec's
  /// "download on first use, don't bundle in APK" decision.
  static const String _modelUrl =
      'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/model.litertlm';
  static const String _modelId = 'Gemma3-1B-IT';

  bool _engineInitialized = false;

  Future<void> _ensureEngineInitialized() async {
    if (_engineInitialized) return;
    await FlutterGemma.initialize(inferenceEngines: const [LiteRtLmEngine()]);
    _engineInitialized = true;
  }

  Future<bool> isModelDownloaded() async {
    await _ensureEngineInitialized();
    return FlutterGemma.isModelInstalled(_modelId);
  }

  /// Downloads the model, reporting 0-100 progress via [onProgress]. Throws
  /// on any download failure — callers should catch and treat this the
  /// same as any other Gemma-path failure (fall back to regex).
  Future<void> downloadModel({required void Function(int progress) onProgress}) async {
    await _ensureEngineInitialized();
    await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
        .fromNetwork(_modelUrl)
        .withProgress(onProgress)
        .install();
  }

  /// Prompts the on-device model to extract structured fields from
  /// [resumeText]. Returns null (never throws past this point) if the
  /// model's response doesn't parse into the expected shape — callers
  /// still need to catch model-load/inference exceptions separately.
  Future<ParsedResumeData?> extract(String resumeText) async {
    await _ensureEngineInitialized();
    final model = await FlutterGemma.getActiveModel(maxTokens: 1024);
    final chat = await model.createChat();
    try {
      await chat.addQueryChunk(Message.text(text: _buildPrompt(resumeText), isUser: true));
      final response = await chat.generateChatResponse();
      final raw = response is TextResponse ? response.token : '';
      return parseAndValidateJson(raw);
    } finally {
      await chat.close();
    }
  }

  String _buildPrompt(String resumeText) => '''
Extract the following fields from this resume text and respond with ONLY a
single JSON object and nothing else — no explanation, no markdown fence.
Use exactly this shape (use null for anything not found):
{"fullName": string|null, "phone": string|null, "address": string|null,
 "dateOfBirth": string|null (format YYYY-MM-DD), "programme": string|null,
 "faculty": string|null, "semester": number|null, "cgpa": number|null,
 "skills": string[], "workExperience": [{"position": string|null,
 "companyName": string|null, "startYear": number|null, "endYear": number|null,
 "isCurrent": boolean, "description": string|null}]}

Resume text:
$resumeText
''';

  /// Parses [raw] as JSON and validates it against the expected resume
  /// shape. Returns null if the JSON is malformed, not an object, missing
  /// a required key, or has a wrong-typed field — the caller falls back
  /// to the regex parser in that case rather than surfacing a
  /// partially-broken result. Pure function — no model/device needed,
  /// which is what makes it directly unit-testable.
  static ParsedResumeData? parseAndValidateJson(String raw) {
    final jsonText = _extractJsonObject(raw);
    if (jsonText == null) return null;

    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map<String, dynamic>) return null;
      json = decoded;
    } catch (_) {
      return null;
    }

    const requiredKeys = [
      'fullName', 'phone', 'address', 'dateOfBirth', 'programme',
      'faculty', 'semester', 'cgpa', 'skills', 'workExperience',
    ];
    if (!requiredKeys.every(json.containsKey)) return null;
    if (json['skills'] is! List) return null;
    if (json['workExperience'] is! List) return null;

    try {
      final skills = (json['skills'] as List).map((e) => e.toString()).toList();
      final workExperience = (json['workExperience'] as List).map((w) {
        if (w is! Map) throw const FormatException('workExperience entry not an object');
        final map = Map<String, dynamic>.from(w);
        return ParsedWorkExperience(
          position: map['position'] as String?,
          companyName: map['companyName'] as String?,
          startYear: (map['startYear'] as num?)?.toInt(),
          endYear: (map['endYear'] as num?)?.toInt(),
          isCurrent: map['isCurrent'] as bool? ?? false,
          description: map['description'] as String?,
        );
      }).toList();

      return ParsedResumeData(
        fullName: json['fullName'] as String?,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        dateOfBirth: json['dateOfBirth'] != null ? DateTime.tryParse(json['dateOfBirth'] as String) : null,
        programme: json['programme'] as String?,
        faculty: json['faculty'] as String?,
        semester: (json['semester'] as num?)?.toInt(),
        cgpa: (json['cgpa'] as num?)?.toDouble(),
        skills: skills,
        workExperience: workExperience,
        source: 'gemma',
      );
    } catch (_) {
      return null;
    }
  }

  /// The model sometimes wraps its JSON in prose or a ```json fence
  /// despite being asked for JSON only — this pulls out the first {...}
  /// block so parsing doesn't fail on decorated output.
  static String? _extractJsonObject(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end == -1 || end < start) return null;
    return raw.substring(start, end + 1);
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run:
```bash
flutter test test/gemma_resume_extractor_test.dart
```
Expected: all 7 tests PASS.

- [ ] **Step 6: Update `ParsedResumeData.source` doc comment**

In `lib/services/resume_parser_service.dart`, the `source` field's doc comment (currently lines 44-48) still says `'nlp'` — this task only adds the new extractor, so leave the rename of the actual value to Task 3 (which removes `parseViaNlp` in the same file). No change needed here yet — noted so the implementer doesn't do it twice.

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/services/gemma_resume_extractor.dart test/gemma_resume_extractor_test.dart
git commit -m "feat: add GemmaResumeExtractor with tested JSON validation"
```

---

## Task 2: On-device verification (human checkpoint — requires Android device/emulator)

This task exists because `flutter_gemma`'s exact runtime behavior for two specific points can only be confirmed by actually running it — the design spec explicitly flagged this risk. Everything else in this plan depends on this task passing.

**What needs confirming:**
1. Whether `FlutterGemma.installModel(...).install()` automatically makes that model the "active model" `FlutterGemma.getActiveModel()` returns, or whether a separate activation call is needed (undocumented in the current API reference).
2. Whether the `litert-community/Gemma3-1B-IT` Hugging Face mirror used in `_modelUrl` requires a Hugging Face access token to download, or is publicly accessible.

**Files:**
- Modify (temporarily): `lib/main.dart` — add a debug-only verification hook, removed at the end of this task.

- [ ] **Step 1: Add a temporary debug hook**

In `lib/main.dart`, inside the `main()` function, right after `WidgetsFlutterBinding.ensureInitialized();`, temporarily add:

```dart
  // TEMPORARY — Task 2 device verification, removed at end of this task.
  if (kDebugMode) {
    unawaited(() async {
      final extractor = GemmaResumeExtractor.instance;
      debugPrint('[gemma-check] downloading model...');
      await extractor.downloadModel(onProgress: (p) => debugPrint('[gemma-check] progress: $p%'));
      debugPrint('[gemma-check] download complete, running extraction...');
      final result = await extractor.extract(
        'Tan Wei Ming\nPhone: 012-345 6789\nAddress: 12 Jalan Ampang, 50450 Kuala Lumpur\n'
        'Programme: Bachelor of Software Engineering (Hons)\nSemester: 6\nCGPA: 3.65\n\n'
        'Technical Skills\nFlutter, Dart, SQL, Git\n\n'
        'Work Experience\nSoftware Intern, Acme Sdn Bhd, Jun 2023 - Aug 2023\nBuilt an internal dashboard.',
      );
      debugPrint('[gemma-check] result: fullName=${result?.fullName}, phone=${result?.phone}, '
          'skills=${result?.skills}, workExperience=${result?.workExperience.length}');
    }());
  }
```

Add the required imports at the top of `lib/main.dart`:
```dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'services/gemma_resume_extractor.dart';
```
(Adjust the relative import path if `main.dart` already imports sibling files differently — check the existing import block in `lib/main.dart` for the convention used.)

- [ ] **Step 2: Run on a real Android device or emulator**

```bash
flutter run
```
Watch the console for the `[gemma-check]` lines. This needs an internet connection for the ~0.5GB download and takes a few minutes on the first run.

- [ ] **Step 3: Resolve activation behavior**

If `[gemma-check] result: ...` prints non-null-ish output (any of `fullName`/`phone`/`skills` populated), `install()` already activates the model — no code change needed, `GemmaResumeExtractor.extract` in Task 1 is correct as written.

If `getActiveModel()` throws (e.g. "no active model") immediately after `downloadModel()` returns, the API needs an explicit activation call. Check the console/exception message and `flutter_gemma`'s current README (`flutter pub deps` then look at `.pub-cache` or run `dart doc` won't help — check https://pub.dev/packages/flutter_gemma for the "Set active model" section, which the reference used to write this plan could not fully confirm) for the correct call — likely something on `FlutterGemma` or on the `InferenceInstallation` object returned by `.install()`. Add whatever call is needed inside `GemmaResumeExtractor.downloadModel()` right after `.install()` completes, e.g.:
```dart
final installation = await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
    .fromNetwork(_modelUrl)
    .withProgress(onProgress)
    .install();
// If a separate activation call turns out to be required, add it here
// using whatever method/property `installation` or `FlutterGemma` exposes
// for it, confirmed against the installed package version's actual API.
```

- [ ] **Step 4: Resolve the Hugging Face token requirement**

If the download in Step 2 fails with a 401/403, the mirror requires a token. In that case:
- Add a `String? huggingFaceToken` parameter to `GemmaResumeExtractor.downloadModel()` and pass it through to `.fromNetwork(_modelUrl, token: huggingFaceToken)`.
- Since this project has no existing secrets-management pattern for Flutter (OneSignal's App ID was hardcoded directly per `SDD Task 8`), hardcode a free personal Hugging Face access token (Settings → Access Tokens → read-only, on huggingface.co, no billing) as a constant in `GemmaResumeExtractor`, following the same precedent as the OneSignal App ID.
- If the download in Step 2 already succeeds with no token, skip this — leave `_modelUrl`'s call with no `token:` argument, as written in Task 1.

- [ ] **Step 5: Remove the temporary debug hook**

Revert the `lib/main.dart` changes from Step 1 completely (remove the `if (kDebugMode)` block and the three added imports, unless `dart:async`/`kDebugMode` are already used elsewhere in the file for other reasons — check before removing).

- [ ] **Step 6: Commit**

If Steps 3-4 required changes to `gemma_resume_extractor.dart`:
```bash
git add lib/services/gemma_resume_extractor.dart
git commit -m "fix: adjust GemmaResumeExtractor for confirmed on-device API behavior"
```
If no changes were needed (main.dart is back to its original state, `git diff` is empty), no commit is needed for this task.

---

## Task 3: Wire `GemmaResumeExtractor` into `resume_parser_service.dart`

**Files:**
- Modify: `lib/services/resume_parser_service.dart:1-148` (imports and the NLP-tier block only — everything from `extractText` at line 150 onward is untouched)

**Interfaces:**
- Consumes: nothing new — this task only removes dead code.
- Produces: `ParsedResumeData.source` doc comment now says `'gemma'` instead of `'nlp'`.

- [ ] **Step 1: Remove the ngrok NLP-tier code**

In `lib/services/resume_parser_service.dart`, delete:
- The imports `import 'package:http/http.dart' as http;` and `import 'package:shared_preferences/shared_preferences.dart';` (lines 3-4) — nothing else in this file uses them once the block below is removed.
- The entire block from the `_defaultNlpServiceBaseUrl` constant through the end of `parseViaNlp` (current lines 85-148: the two constants, `getNlpServiceUrl`, `setNlpServiceUrl`, and `parseViaNlp`).

- [ ] **Step 2: Update the `source` field doc comment**

Change (current lines 44-48):
```dart
  /// 'nlp' if this came from the hybrid spaCy+regex service, 'regex' if it
  /// came from the local-only fallback parser below. Shown in the UI so
  /// it's clear which one produced a given result — also the basis for the
  /// regex-vs-NLP comparison in the FYP report.
  final String source;
```
to:
```dart
  /// 'gemma' if this came from the on-device Gemma extractor
  /// (see GemmaResumeExtractor), 'regex' if it came from the local-only
  /// fallback parser below. Shown in the UI so it's clear which one
  /// produced a given result — also the basis for the regex-vs-Gemma
  /// comparison in the FYP report.
  final String source;
```

- [ ] **Step 3: Verify the file still analyzes clean**

Run:
```bash
flutter analyze lib/services/resume_parser_service.dart
```
Expected: no errors (in particular, no "unused import" warnings for `http`/`shared_preferences`, confirming Step 1 removed every usage).

- [ ] **Step 4: Commit**

```bash
git add lib/services/resume_parser_service.dart
git commit -m "refactor: remove ngrok NLP tier from resume_parser_service"
```

---

## Task 4: Update `student_profile_screen.dart` call site

**Files:**
- Modify: `lib/screens/student/student_profile_screen.dart:1029-1061` (remove), `:1063-1079` (rewrite), `:1589-1592` (simplify), plus one new import

**Interfaces:**
- Consumes: `GemmaResumeExtractor.instance.isModelDownloaded()`, `.downloadModel({required onProgress})`, `.extract(String)` from Task 1; `ResumeParserService.instance.extractText`/`.parse` (unchanged, existing).

- [ ] **Step 1: Add the import**

Near the top of `lib/screens/student/student_profile_screen.dart`, alongside the existing `import '.../resume_parser_service.dart';`-style imports, add:
```dart
import '../../services/gemma_resume_extractor.dart';
```
(Match whatever relative path prefix the existing `resume_parser_service.dart` import in this file already uses.)

- [ ] **Step 2: Delete `_showNlpServiceUrlEditor`**

Delete the entire method (current lines 1029-1061), including its doc comment (`/// Dev-only access point...`).

- [ ] **Step 3: Simplify the long-press wiring**

Change (current lines 1589-1592):
```dart
                  GestureDetector(
                    onLongPress: _showNlpServiceUrlEditor,
                    child: SectionHeader(title: l10n.resume),
                  ),
```
to:
```dart
                  SectionHeader(title: l10n.resume),
```

- [ ] **Step 4: Add the download-consent and progress dialogs**

Add these two new private methods to the `_StudentProfileScreenState` class (place them right before `_offerResumeScan`, which is rewritten in the next step):

```dart
  Future<bool?> _confirmModelDownload() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Download AI model?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text(
          'Smart resume scanning needs a one-time ~500MB download. It runs '
          'fully on this device afterwards, so future scans work offline. Continue?',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Not now')),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Download')),
        ],
      ),
    );
  }

  Future<void> _downloadModelWithProgress() async {
    final progressNotifier = ValueNotifier<int>(0);
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Downloading model…', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: ValueListenableBuilder<int>(
          valueListenable: progressNotifier,
          builder: (context, progress, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: progress / 100),
              const SizedBox(height: 8),
              Text('$progress%', style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
            ],
          ),
        ),
      ),
    );
    try {
      await GemmaResumeExtractor.instance.downloadModel(
        onProgress: (p) => progressNotifier.value = p,
      );
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }
```

- [ ] **Step 5: Rewrite `_offerResumeScan`'s parsing block**

Change (current lines 1063-1079):
```dart
  Future<void> _offerResumeScan(File file) async {
    final l10n = AppLocalizations.of(context)!;
    ParsedResumeData data;
    try {
      final text = await ResumeParserService.instance.extractText(file);
      try {
        data = await ResumeParserService.instance.parseViaNlp(text);
      } catch (_) {
        // NLP service unreachable (offline, tunnel restarted, timed out,
        // etc.) — silently fall back to the local regex-only parser rather
        // than losing the autofill feature entirely.
        data = ResumeParserService.instance.parse(text);
      }
    } catch (e) {
      // Non-fatal — scanning is a bonus feature, upload already succeeded.
      return;
    }
```
to:
```dart
  Future<void> _offerResumeScan(File file) async {
    final l10n = AppLocalizations.of(context)!;
    ParsedResumeData data;
    try {
      final text = await ResumeParserService.instance.extractText(file);
      try {
        if (!await GemmaResumeExtractor.instance.isModelDownloaded()) {
          final consented = await _confirmModelDownload();
          if (consented != true) throw Exception('Model download declined');
          await _downloadModelWithProgress();
        }
        final gemmaResult = await GemmaResumeExtractor.instance.extract(text);
        if (gemmaResult == null) throw Exception('Gemma extraction returned no valid data');
        data = gemmaResult;
      } catch (_) {
        // Gemma unavailable (model not downloaded and declined, download
        // failed, inference failed, or invalid output) — silently fall
        // back to the local regex-only parser rather than losing the
        // autofill feature entirely.
        data = ResumeParserService.instance.parse(text);
      }
    } catch (e) {
      // Non-fatal — scanning is a bonus feature, upload already succeeded.
      return;
    }
```
Everything after this block (the `if (!data.foundAnything || !mounted) return;` line onward) is unchanged.

- [ ] **Step 6: Verify the file analyzes clean**

Run:
```bash
flutter analyze lib/screens/student/student_profile_screen.dart
```
Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add lib/screens/student/student_profile_screen.dart
git commit -m "feat: use on-device Gemma extractor for resume autofill, with regex fallback"
```

---

## Task 5: Full regression verification (human checkpoint — Android device/emulator)

**Files:** none (verification only)

- [ ] **Step 1: Static verification**

```bash
flutter analyze
```
Expected: no new errors/warnings versus the pre-change baseline.

- [ ] **Step 2: Golden path — PDF resume**

On a real Android device or emulator: log in as a student, go to Profile → upload a real PDF resume. Confirm:
- The "Download AI model?" dialog appears (first time only).
- After confirming, a progress dialog shows and completes.
- The autofill dialog then shows extracted fields (name, phone, address, programme, skills, work experience where present in the sample resume).
- Every field is still editable after accepting.

- [ ] **Step 3: Golden path — DOCX resume**

Repeat Step 2 with a `.docx` resume. The model is already downloaded from Step 2, so no download dialog should reappear — extraction should go straight to the results dialog.

- [ ] **Step 4: Fallback path — decline download**

Uninstall/reinstall the app (or clear its data) to reset the "model downloaded" state, upload a resume, and tap "Not now" on the download-consent dialog. Confirm the autofill dialog still appears, populated by the regex parser (fewer/different fields than the Gemma path, but not a crash or silent no-op).

- [ ] **Step 5: Fallback path — download interrupted**

Reset app data again, upload a resume, confirm the download, then enable Airplane Mode partway through the progress dialog. Confirm the app doesn't hang or crash — it should eventually fail the download and fall through to the regex-parsed autofill dialog (per Step 4's behavior), not leave the user stuck on the progress dialog.

- [ ] **Step 6: Confirm `nlp_service/` is untouched**

```bash
git status nlp_service/
git diff --stat nlp_service/
```
Expected: no output — this plan made zero changes there, per the Global Constraints.

- [ ] **Step 7: Fix any issues found, then commit**

If Steps 2-5 surfaced any bugs, fix them in the relevant file from Tasks 1/3/4, re-run the affected steps above, then:
```bash
git add -A
git commit -m "fix: address issues found in on-device resume parser regression testing"
```
If nothing needed fixing, no commit is needed for this task.

---

## Self-Review Notes

- **Spec coverage:** Data flow steps 1-5 → Tasks 1/3/4. Component changes (resume_parser_service.dart, settings UI removal, flutter_gemma dependency) → Tasks 1/3/4. Error handling (any failure falls through to regex, non-fatal) → Task 4 Step 5. Testing approach (unit-level JSON validation + manual device testing including deliberate fallback triggers) → Task 1 + Task 5. Academic fallback (`nlp_service/` untouched) → Global Constraints + Task 5 Step 6 explicit check. Out-of-scope items (training, iOS, archiving `nlp_service/`) → not referenced anywhere in this plan, correctly.
- **Placeholder scan:** The two genuinely unconfirmable-without-a-device facts (model auto-activation, HF token requirement) are isolated into Task 2 as concrete, testable, pass/fail verification steps with explicit code changes for either outcome — not vague "TBD"s. Every other task has complete, real code using method signatures confirmed against the installed package's actual API documentation (fetched live during planning, not recalled from training data).
- **Type consistency:** `GemmaResumeExtractor.instance`, `.isModelDownloaded()`, `.downloadModel({required onProgress})`, `.extract(String) -> Future<ParsedResumeData?>`, and the static `.parseAndValidateJson(String) -> ParsedResumeData?` are defined once in Task 1 and used identically (same names, same signatures) in Task 2's verification hook and Task 4's call site. `ParsedResumeData`/`ParsedWorkExperience` field names match the existing, unmodified class definitions in `resume_parser_service.dart`.

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-08-18-on-device-resume-parser.md`. Two execution options:

1. **Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration
2. **Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
