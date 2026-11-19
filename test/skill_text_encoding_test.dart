import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/utils/skill_text_encoding.dart';

/// The Dart encoding must give exactly the answers the Python code gave when the model was trained.
/// The expected values come from test/fixtures/skill_encoding_golden.json, written by
/// nlp_service/tf_model/make_golden.py. Regenerate it there if the Python side changes on purpose.
void main() {
  final golden = jsonDecode(File('test/fixtures/skill_encoding_golden.json').readAsStringSync()) as Map<String, dynamic>;
  final words = (golden['vocab']['words'] as Map).map((k, v) => MapEntry(k as String, v as int));
  final chars = (golden['vocab']['chars'] as Map).map((k, v) => MapEntry(k as String, v as int));
  final cases = (golden['cases'] as List).cast<Map<String, dynamic>>();

  group('tokens and ids match the Python reference', () {
    for (var i = 0; i < cases.length; i++) {
      final c = cases[i];
      final text = c['text'] as String;
      test('text #$i', () {
        final tokens = SkillTextEncoding.tokenize(text);
        expect(
          [for (final t in tokens) [t.start, t.end, t.text]],
          (c['tokens'] as List),
          reason: 'tokenize',
        );
        final enc = SkillTextEncoding.encode([for (final t in tokens) t.text], words, chars);
        expect(enc.words, (c['wordIds'] as List).cast<int>(), reason: 'word ids');
        expect(enc.chars, [for (final row in c['charIds'] as List) (row as List).cast<int>()], reason: 'char ids');
        expect(enc.chars.every((r) => r.length == SkillTextEncoding.maxChars), isTrue);
      });

      test('chunks and windows of text #$i', () {
        final chunks = SkillTextEncoding.chunkText(text, maxChars: 300);
        expect([for (final ch in chunks) [ch.$1, ch.$2]], (c['chunks'] as List), reason: 'chunkText');
        final n = SkillTextEncoding.tokenize(text).length;
        expect([for (final w in SkillTextEncoding.windows(n, 7)) [w.$1, w.$2]], (c['windows'] as List), reason: 'windows');
      });
    }
  });

  test('label sequences decode to the same character spans', () {
    for (final d in (golden['decode'] as List).cast<Map<String, dynamic>>()) {
      final tokens = [for (final t in d['tokens'] as List) SkillToken(t[0] as int, t[1] as int, t[2] as String)];
      final spans = SkillTextEncoding.decodeSpans((d['labels'] as List).cast<int>(), tokens);
      expect([for (final s in spans) [s.$1, s.$2]], (d['spans'] as List), reason: '${d['labels']}');
    }
  });

  test('probabilities become the same labels as in Python', () {
    for (final c in (golden['probCases'] as List).cast<Map<String, dynamic>>()) {
      final probs = [for (final row in c['probs'] as List) (row as List).map((v) => (v as num).toDouble()).toList()];
      expect(SkillTextEncoding.labelsFromProbs(probs, (c['threshold'] as num).toDouble()), (c['labels'] as List).cast<int>(),
          reason: 'threshold ${c['threshold']}');
    }
  });

  test('the skill sanity check agrees with Python on every item', () {
    for (final pair in (golden['items'] as List)) {
      expect(SkillTextEncoding.looksLikeSkill(pair[0] as String), pair[1] as bool, reason: '"${pair[0]}"');
    }
  });

  test('cleanItem strips stray punctuation', () {
    expect(SkillTextEncoding.cleanItem('  • Python. '), 'Python');
    expect(SkillTextEncoding.cleanItem('C++,'), 'C++');
    expect(SkillTextEncoding.cleanItem('(Node.js)'), '(Node.js)');
  });
}
