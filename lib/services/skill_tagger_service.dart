import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../utils/skill_text_encoding.dart';

/// Finds skills in resume text with the small neural network that was trained for this project
/// (nlp_service/tf_model, exported to TensorFlow Lite): 2 MB, no internet, no server.
///
/// It is a helper, never a requirement. If the model cannot load or run for any reason, [extract]
/// quietly returns nothing and the resume scan carries on with what the regex parser found.
class SkillTaggerService {
  SkillTaggerService._();
  static final SkillTaggerService instance = SkillTaggerService._();

  static const String _modelAsset = 'assets/models/skill_tagger.tflite';
  static const String _vocabAsset = 'assets/models/skill_vocab.json';

  Interpreter? _interpreter;
  Map<String, int> _words = const {};
  Map<String, int> _chars = const {};
  double _outsideThreshold = 0.5;
  int _wordsInput = 0;
  int _charsInput = 1;
  Future<bool>? _loading;

  Future<bool> _ensureLoaded() => _loading ??= _load();

  Future<bool> _load() async {
    try {
      final vocab = jsonDecode(await rootBundle.loadString(_vocabAsset)) as Map<String, dynamic>;
      _words = (vocab['words'] as Map).map((k, v) => MapEntry(k as String, v as int));
      _chars = (vocab['chars'] as Map).map((k, v) => MapEntry(k as String, v as int));
      _outsideThreshold = (vocab['outside_threshold'] as num?)?.toDouble() ?? 0.5;

      final interpreter = await Interpreter.fromAsset(_modelAsset);
      final inputs = interpreter.getInputTensors();
      // the model takes the word ids (2-D) and the character ids (3-D); find which input is which
      _wordsInput = inputs.indexWhere((t) => t.shape.length == 2);
      _charsInput = inputs.indexWhere((t) => t.shape.length == 3);
      if (inputs.length != 2 || _wordsInput < 0 || _charsInput < 0) return false;
      _interpreter = interpreter;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Whether the model is installed and can run on this device.
  Future<bool> get isAvailable => _ensureLoaded();

  /// The skills the model finds in [text], cleaned the same way as on the laptop. Empty when the
  /// model is unavailable or finds none.
  Future<List<String>> extract(String text, {int limit = 40}) async {
    try {
      if (!await _ensureLoaded()) return const [];
      final seen = <String>{};
      final found = <String>[];
      for (final chunk in SkillTextEncoding.chunkText(text)) {
        final tokens = SkillTextEncoding.tokenize(chunk.$2);
        if (tokens.isEmpty) continue;
        for (final (a, b) in SkillTextEncoding.decodeSpans(_labels(tokens), tokens)) {
          final item = SkillTextEncoding.cleanItem(chunk.$2.substring(a, b));
          if (item.isNotEmpty && SkillTextEncoding.looksLikeSkill(item) && seen.add(item.toLowerCase())) {
            found.add(item);
            if (found.length >= limit) return found;
          }
        }
      }
      return found;
    } catch (_) {
      return const [];
    }
  }

  List<int> _labels(List<SkillToken> tokens) {
    final labels = <int>[];
    for (final (a, b) in SkillTextEncoding.windows(tokens.length)) {
      final part = tokens.sublist(a, b);
      final enc = SkillTextEncoding.encode([for (final t in part) t.text], _words, _chars);

      final words = List<int>.filled(SkillTextEncoding.maxLen, 0)..setRange(0, part.length, enc.words);
      final chars = [
        for (var i = 0; i < SkillTextEncoding.maxLen; i++)
          i < part.length ? enc.chars[i] : List<int>.filled(SkillTextEncoding.maxChars, 0),
      ];
      final output = [
        List.generate(SkillTextEncoding.maxLen, (_) => List<double>.filled(3, 0)),
      ];

      final inputs = List<Object>.filled(2, 0);
      inputs[_wordsInput] = [words];
      inputs[_charsInput] = [chars];
      _interpreter!.runForMultipleInputs(inputs, {0: output});

      labels.addAll(SkillTextEncoding.labelsFromProbs(output[0].sublist(0, part.length), _outsideThreshold));
    }
    return labels;
  }
}
