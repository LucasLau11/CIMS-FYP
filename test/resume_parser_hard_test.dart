import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/services/resume_parser_service.dart';

/// Scores the app's regex parser on the HARDER fake resumes (nlp_service/eval/hard_resumes.json,
/// made by `python nlp_service/eval/generate_hard.py`). Each resume records which habit it used for
/// every field ("DOB written as 12th March 2002", "phone on the line after its label", ...), so the
/// report says exactly which habits still fail. Scoring matches nlp_service/eval/score.py.
///
/// The report is written to nlp_service/eval/HARD_RESULTS.md.
String _norm(Object? s) => (s?.toString() ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
String _digits(Object? s) => (s?.toString() ?? '').replaceAll(RegExp(r'\D'), '');

bool _containsEither(Object? pred, Object? truth) {
  final p = _norm(pred), t = _norm(truth);
  return p.isNotEmpty && (p.contains(t) || t.contains(p));
}

void main() {
  final input = File('nlp_service/eval/hard_resumes.json');

  test('regex parser on the hard fake resumes', () {
    if (!input.existsSync()) {
      markTestSkipped('run: python nlp_service/eval/generate_hard.py');
      return;
    }
    final data = (jsonDecode(input.readAsStringSync()) as List).cast<Map<String, dynamic>>();
    final parser = ResumeParserService.instance;

    final total = <String, int>{};
    final correct = <String, int>{};
    final byVariantTotal = <String, int>{};
    final byVariantCorrect = <String, int>{};
    final examples = <String, List<String>>{};
    var skTp = 0, skFp = 0, skFn = 0, wTp = 0, wFp = 0, wFn = 0;

    void record(String field, String variant, bool ok, String Function() describe) {
      total.update(field, (v) => v + 1, ifAbsent: () => 1);
      byVariantTotal.update('$field|$variant', (v) => v + 1, ifAbsent: () => 1);
      if (ok) {
        correct.update(field, (v) => v + 1, ifAbsent: () => 1);
        byVariantCorrect.update('$field|$variant', (v) => v + 1, ifAbsent: () => 1);
      } else {
        final list = examples.putIfAbsent('$field|$variant', () => []);
        if (list.length < 2) list.add(describe());
      }
    }

    for (final r in data) {
      final t = r['truth'] as Map<String, dynamic>;
      final v = (r['variants'] as Map).cast<String, String>();
      final p = parser.parse(r['text'] as String);

      record('fullName', v['name']!, _norm(p.fullName) == _norm(t['fullName']), () => 'got "${p.fullName}" want "${t['fullName']}"');
      final wantPhone = _digits(t['phone']);
      final gotPhone = _digits(p.phone);
      record('phone', v['phone']!, gotPhone.isNotEmpty && gotPhone.length >= 9 && gotPhone.substring(gotPhone.length - 9) == wantPhone.substring(wantPhone.length - 9),
          () => 'got "${p.phone}" want "${t['phone']}"');
      record('address', v['address']!, _containsEither(p.address, t['address']), () => 'got "${p.address}" want "${t['address']}"');
      record('dateOfBirth', v['dob']!, p.dateOfBirth?.toIso8601String().substring(0, 10) == t['dateOfBirth'],
          () => 'got "${p.dateOfBirth?.toIso8601String().substring(0, 10)}" want "${t['dateOfBirth']}"');
      record('programme', v['programme']!, _containsEither(p.programme, t['programme']), () => 'got "${p.programme}" want "${t['programme']}"');
      record('faculty', v['programme']!, _containsEither(p.faculty, t['faculty']), () => 'got "${p.faculty}" want "${t['faculty']}"');
      record('semester', v['semester']!, p.semester == t['semester'], () => 'got ${p.semester} want ${t['semester']}');
      record('cgpa', v['cgpa']!, p.cgpa != null && (p.cgpa! - (t['cgpa'] as num)).abs() < 0.005, () => 'got ${p.cgpa} want ${t['cgpa']}');

      final truthSk = {for (final s in t['skills'] as List) _norm(s)};
      final predSk = {for (final s in p.skills) _norm(s)};
      final tp = truthSk.intersection(predSk).length;
      skTp += tp;
      skFp += predSk.difference(truthSk).length;
      skFn += truthSk.difference(predSk).length;
      record('skills (exact set)', v['skills']!, truthSk.length == predSk.length && tp == truthSk.length,
          () => 'missing ${truthSk.difference(predSk).toList()} extra ${predSk.difference(truthSk).toList()}');

      final truthW = {for (final w in t['workExperience'] as List) '${_norm(w['position'])}|${_norm(w['companyName'])}'};
      final predW = {for (final w in p.workExperience) '${_norm(w.position)}|${_norm(w.companyName)}'};
      wTp += truthW.intersection(predW).length;
      wFp += predW.difference(truthW).length;
      wFn += truthW.difference(predW).length;
      record('work history (exact set)', v['work']!, truthW.length == predW.length && truthW.intersection(predW).length == truthW.length,
          () => 'want $truthW got $predW');
    }

    double f1(int tp, int fp, int fn) {
      final pr = tp + fp == 0 ? 0.0 : tp / (tp + fp);
      final rc = tp + fn == 0 ? 0.0 : tp / (tp + fn);
      return pr + rc == 0 ? 0.0 : 2 * pr * rc / (pr + rc);
    }

    final b = StringBuffer()
      ..writeln('# Regex parser on the HARD fake resumes\n')
      ..writeln('${data.length} generated resumes that use the habits of real student resumes (see `generate_hard.py`).')
      ..writeln('Scored automatically; nobody labelled anything by hand. Generated resumes show how the parser copes with these habits, not how it does on every real resume.\n')
      ..writeln('| Field | Correct |')
      ..writeln('|---|---|');
    for (final f in total.keys) {
      b.writeln('| $f | ${(100 * correct[f]! / total[f]!).toStringAsFixed(1)}% (${correct[f]}/${total[f]}) |');
    }
    b
      ..writeln('\nSkills F1 ${f1(skTp, skFp, skFn).toStringAsFixed(3)} · work history F1 ${f1(wTp, wFp, wFn).toStringAsFixed(3)}\n')
      ..writeln('## Habits that still fail\n')
      ..writeln('| Field | Habit | Correct | Example |')
      ..writeln('|---|---|---|---|');
    final failing = byVariantTotal.keys.where((k) => (byVariantCorrect[k] ?? 0) < byVariantTotal[k]!).toList()
      ..sort((a, c) => ((byVariantCorrect[a] ?? 0) / byVariantTotal[a]!).compareTo((byVariantCorrect[c] ?? 0) / byVariantTotal[c]!));
    for (final k in failing) {
      final parts = k.split('|');
      b.writeln('| ${parts[0]} | ${parts[1]} | ${byVariantCorrect[k] ?? 0}/${byVariantTotal[k]} | ${(examples[k] ?? []).take(1).join('').replaceAll('|', '/').replaceAll('\n', ' ')} |');
    }
    File('nlp_service/eval/HARD_RESULTS.md').writeAsStringSync(b.toString());
    // ignore: avoid_print
    print(b);

    // The floor the parser must keep: a change that makes any of these habits fail again is a regression.
    for (final f in total.keys) {
      expect(correct[f]! / total[f]!, greaterThanOrEqualTo(0.95), reason: '$f fell below 95% on the hard resumes');
    }
  });
}
