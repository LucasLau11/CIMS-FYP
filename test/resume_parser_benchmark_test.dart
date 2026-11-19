import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/services/resume_parser_service.dart';

/// Runs the app's built-in regex parser on the fake resumes in
/// nlp_service/eval/synthetic_resumes.json and saves what it found to
/// nlp_service/eval/predictions_dart_regex.json. nlp_service/eval/score.py then scores it against
/// the true answers next to the spaCy parser, so both are measured the same way.
///
/// Regenerate the resumes with:  python nlp_service/eval/generate_synthetic.py
void main() {
  final input = File('nlp_service/eval/synthetic_resumes.json');

  test('the regex parser runs on every fake resume and its answers are saved for scoring', () {
    if (!input.existsSync()) {
      markTestSkipped('nlp_service/eval/synthetic_resumes.json does not exist yet.');
      return;
    }
    final data = (jsonDecode(input.readAsStringSync()) as List).cast<Map<String, dynamic>>();
    final stopwatch = Stopwatch()..start();
    final predictions = <String, dynamic>{};

    for (final r in data) {
      final p = ResumeParserService.instance.parse(r['text'] as String);
      predictions['${r['id']}'] = {
        'fullName': p.fullName,
        'phone': p.phone,
        'address': p.address,
        'dateOfBirth': p.dateOfBirth?.toIso8601String().substring(0, 10),
        'programme': p.programme,
        'faculty': p.faculty,
        'semester': p.semester,
        'cgpa': p.cgpa,
        'skills': p.skills,
        'workExperience': [
          for (final w in p.workExperience)
            {'position': w.position, 'companyName': w.companyName, 'startYear': w.startYear, 'endYear': w.endYear, 'isCurrent': w.isCurrent},
        ],
      };
    }
    stopwatch.stop();

    File('nlp_service/eval/predictions_dart_regex.json').writeAsStringSync(
      const JsonEncoder.withIndent(' ').convert({
        'name': 'dart_regex',
        'seconds_per_resume': double.parse((stopwatch.elapsedMicroseconds / 1e6 / data.length).toStringAsFixed(5)),
        'predictions': predictions,
      }),
    );
    expect(predictions.length, data.length);
  });
}
