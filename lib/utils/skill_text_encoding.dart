/// How resume text becomes numbers for the on-device TensorFlow Lite skill tagger, and how the
/// model's answer becomes skills again.
///
/// THIS IS A LINE-FOR-LINE TWIN of nlp_service/tf_model/text_encoding.py (tokens, ids, windows,
/// decoding) and of chunk_text / looks_like_skill in nlp_service/skill_labels.py. If the two drift
/// apart the phone silently disagrees with how the model was trained, so
/// test/skill_text_encoding_test.dart checks this file against answers written by the Python code
/// (test/fixtures/skill_encoding_golden.json, made by nlp_service/tf_model/make_golden.py).
library;

class SkillToken {
  const SkillToken(this.start, this.end, this.text);
  final int start;
  final int end;
  final String text;
}

class SkillTextEncoding {
  SkillTextEncoding._();

  /// Tokens per window fed to the model, and characters kept per token (must match the model).
  static const int maxLen = 192;
  static const int maxChars = 16;
  static const int pad = 0;
  static const int unk = 1;

  // token: a run of [A-Za-z0-9_]  or one other non-space character
  static final RegExp _token = RegExp(r'[A-Za-z0-9_]+|[^\sA-Za-z0-9_]', unicode: true);

  static List<SkillToken> tokenize(String text) =>
      [for (final m in _token.allMatches(text)) SkillToken(m.start, m.end, m.group(0)!)];

  /// Word id (lower-cased token) and character ids (first 16 characters, case kept) for each token.
  static ({List<int> words, List<List<int>> chars}) encode(
    List<String> tokens,
    Map<String, int> wordVocab,
    Map<String, int> charVocab,
  ) {
    final words = <int>[];
    final chars = <List<int>>[];
    for (final t in tokens) {
      words.add(wordVocab[t.toLowerCase()] ?? unk);
      final ids = <int>[
        for (final r in t.runes.take(maxChars)) charVocab[String.fromCharCode(r)] ?? unk,
      ];
      while (ids.length < maxChars) {
        ids.add(pad);
      }
      chars.add(ids);
    }
    return (words: words, chars: chars);
  }

  /// Index ranges that cut [nTokens] tokens into windows of at most [size].
  static List<(int, int)> windows(int nTokens, [int size = maxLen]) {
    final out = <(int, int)>[];
    for (var a = 0; a < (nTokens > 0 ? nTokens : 1); a += size) {
      out.add((a, a + size < nTokens ? a + size : nTokens));
    }
    return out;
  }

  /// One label per token from the model's [outside, first, inside] probabilities: "outside" when the
  /// model is at least [outsideThreshold] sure of that, otherwise the likelier of first / inside.
  static List<int> labelsFromProbs(List<List<double>> probs, [double outsideThreshold = 0.5]) => [
        for (final p in probs) p[0] >= outsideThreshold ? 0 : (p[1] >= p[2] ? 1 : 2),
      ];

  /// Character spans (start, end) of the skills a label sequence marks:
  /// 0 = outside, 1 = first token of a skill, 2 = inside a skill.
  static List<(int, int)> decodeSpans(List<int> labels, List<SkillToken> tokens) {
    final spans = <(int, int)>[];
    int? start;
    int? end;
    final n = labels.length < tokens.length ? labels.length : tokens.length;
    for (var i = 0; i < n; i++) {
      final lab = labels[i];
      final t = tokens[i];
      if (lab == 1 || (lab == 2 && start == null)) {
        if (start != null) spans.add((start, end!));
        start = t.start;
        end = t.end;
      } else if (lab == 2) {
        end = t.end;
      } else {
        if (start != null) spans.add((start, end!));
        start = null;
        end = null;
      }
    }
    if (start != null) spans.add((start, end!));
    return spans;
  }

  /// Splits a resume into windows of whole lines: (offset of the window, window text).
  static List<(int, String)> chunkText(String text, {int maxChars = 600}) {
    final chunks = <(int, String)>[];
    var curLen = 0;
    var pos = 0;
    var bufStart = 0;
    String trimEnd(String s) {
      var e = s.length;
      while (e > 0 && s.codeUnitAt(e - 1) == 0x0A) {
        e--;
      }
      return s.substring(0, e);
    }

    for (final ln in text.split('\n')) {
      final add = ln.length + 1;
      if (curLen + add > maxChars && curLen > 0) {
        chunks.add((bufStart, trimEnd(text.substring(bufStart, pos))));
        bufStart = pos;
        curLen = 0;
      }
      curLen += add;
      pos += add;
    }
    if (pos > bufStart) {
      chunks.add((bufStart, trimEnd(text.substring(bufStart, pos > text.length ? text.length : pos))));
    }
    return [for (final c in chunks) if (c.$2.trim().isNotEmpty) c];
  }

  // ------------------------------------------------------- the final sanity check on a found item

  static const List<String> _skillsHeadings = [
    'technical skills', 'key skills', 'core competencies', 'areas of expertise',
    'skills & competencies', 'skills and competencies', 'competencies', 'expertise',
    'professional skills', 'computer skills', 'technical proficiencies', 'skill highlights',
    'highlights', 'skills summary', 'summary of skills', 'skills',
  ];

  static const List<String> _otherHeadings = [
    'professional experience', 'work experience', 'employment history', 'work history',
    'relevant experience', 'experience', 'education', 'academic background', 'qualifications',
    'education and training', 'projects', 'certifications', 'certificates', 'achievements',
    'awards', 'activities', 'extracurricular', 'co-curricular', 'hobbies', 'interests',
    'languages', 'publications', 'references', 'summary', 'professional summary', 'objective',
    'profile', 'about me', 'personal details', 'personal information', 'accomplishments',
    'affiliations', 'additional information', 'interests and hobbies',
  ];

  static final Set<String> _allHeadings = {..._skillsHeadings, ..._otherHeadings};

  static const Set<String> _stop = {
    'a', 'an', 'and', 'or', 'the', 'of', 'to', 'in', 'on', 'at', 'for', 'with', 'by', 'from', 'as',
    'is', 'are', 'was', 'be', 'been', 'that', 'this', 'which', 'who', 'i', 'my', 'our', 'their',
    'also', 'etc', 'including', 'such', 'using', 'use', 'per', 'within', 'into', 'over',
  };

  static String _normHeading(String line) =>
      line.trim().toLowerCase().replaceFirst(RegExp(r'[:\-–—\s]+$'), '').trim();

  /// Whether a found item is short and noun-like enough to be a skill (not a sentence, a date...).
  static bool looksLikeSkill(String raw) {
    final item = raw.trim();
    if (item.length < 2 || item.length > 40) return false;
    final words = item.split(RegExp(r'\s+'));
    if (words.length > 5) return false;
    if (!RegExp(r'[A-Za-z]').hasMatch(item)) return false;
    if (RegExp(r'^[\d\W]+$').hasMatch(item)) return false;
    if (item.endsWith('.') && words.length > 3) return false;
    if (_allHeadings.contains(_normHeading(item))) return false;
    if (RegExp(r'\b(19|20)\d{2}\b').hasMatch(item)) return false;
    if (RegExp(r'@|https?://|www\.').hasMatch(item)) return false;
    if ('('.allMatches(item).length != ')'.allMatches(item).length || item.contains(':')) return false;
    final first = words.first.toLowerCase().replaceAll(RegExp(r'\W'), '');
    final last = words.last.toLowerCase().replaceAll(RegExp(r'\W'), '');
    if (_stop.contains(first) || _stop.contains(last)) return false;
    if (!RegExp(r'^[A-Za-z0-9(+#.]').hasMatch(item) || item.contains('\u{FFFD}')) return false;
    return true;
  }

  /// Trims stray punctuation off a found span: leading symbols, trailing dots, colons, commas.
  static String cleanItem(String raw) => raw
      .trim()
      .replaceFirst(RegExp(r'^[^\w(+#.]+'), '')
      .replaceFirst(RegExp(r'[\s.:;,]+$'), '');
}
