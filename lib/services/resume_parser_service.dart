import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:docx_to_text/docx_to_text.dart';
import '../utils/known_terms.dart';
import 'skill_tagger_service.dart';

/// One work experience entry found in a resume. Fields the extractor
/// couldn't confidently split out are left null — the caller shows these
/// pre-filled but always editable, same as every other parsed field.
class ParsedWorkExperience {
  final String? position;
  final String? companyName;
  final int? startYear;
  final int? endYear;
  final bool isCurrent;
  final String? description;

  ParsedWorkExperience({
    this.position,
    this.companyName,
    this.startYear,
    this.endYear,
    this.isCurrent = false,
    this.description,
  });
}

/// Fields the parser was able to find in the resume. Any field left null
/// means the regex patterns didn't find it — the caller should leave that
/// field untouched rather than overwrite it with something empty.
class ParsedResumeData {
  final String? fullName;
  final String? phone;
  final String? address;
  final DateTime? dateOfBirth;
  final String? programme;
  final String? faculty;
  final int? semester;
  final double? cgpa;
  final List<String> skills;
  final List<ParsedWorkExperience> workExperience;

  /// 'nlp' if this came from the hybrid spaCy+regex service, 'regex' if it
  /// came from the local-only fallback parser below. Shown in the UI so
  /// it's clear which one produced a given result — also the basis for the
  /// regex-vs-NLP comparison in the FYP report.
  final String source;

  ParsedResumeData({
    this.fullName,
    this.phone,
    this.address,
    this.dateOfBirth,
    this.programme,
    this.faculty,
    this.semester,
    this.cgpa,
    this.skills = const [],
    this.workExperience = const [],
    this.source = 'regex',
  });

  bool get foundAnything =>
      fullName != null ||
          phone != null ||
          address != null ||
          dateOfBirth != null ||
          programme != null ||
          faculty != null ||
          semester != null ||
          cgpa != null ||
          skills.isNotEmpty ||
          workExperience.isNotEmpty;
}

/// Regex-only resume parsing — no AI/network calls involved. This means
/// it reliably catches clearly-labelled fields (e.g. "Phone: 012-345 6789")
/// but can't reliably understand unlabelled free-form text the way an LLM
/// could. Fields that aren't found are simply left null for manual entry.
class ResumeParserService {
  ResumeParserService._();
  static final ResumeParserService instance = ResumeParserService._();

  /// Base URL of the hybrid spaCy+regex NLP service (nlp_service/). This is
  /// an ngrok tunnel that gets a new URL every time it's restarted (ngrok's
  /// free tier doesn't offer a permanent one), so it's stored on-device and
  /// editable at runtime — see [getNlpServiceUrl]/[setNlpServiceUrl] —
  /// rather than compiled into the app, which would need a full rebuild
  /// and reinstall every time it changed (a real problem when testing on a
  /// physical phone, not just an emulator hot-reloading from source).
  static const String _defaultNlpServiceBaseUrl = 'https://entrust-nimble-squash.ngrok-free.dev';
  static const String _nlpServiceUrlPrefsKey = 'cims_nlp_service_url';

  Future<String> getNlpServiceUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nlpServiceUrlPrefsKey) ?? _defaultNlpServiceBaseUrl;
  }

  Future<void> setNlpServiceUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    // Strip a trailing slash so "$base/parse-resume" never ends up with "//".
    await prefs.setString(_nlpServiceUrlPrefsKey, url.trim().replaceFirst(RegExp(r'/+$'), ''));
  }

  /// Calls the NLP service's /parse-resume endpoint. Throws on any
  /// failure (network error, timeout, bad response) — callers should catch
  /// and fall back to [parse] (the local regex-only parser), never let a
  /// scan silently do nothing.
  Future<ParsedResumeData> parseViaNlp(String text) async {
    final baseUrl = await getNlpServiceUrl();
    final response = await http
        .post(
          Uri.parse('$baseUrl/parse-resume'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('NLP service returned ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ParsedResumeData(
      fullName: json['fullName'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.tryParse(json['dateOfBirth'] as String) : null,
      programme: json['programme'] as String?,
      faculty: json['faculty'] as String?,
      semester: json['semester'] as int?,
      cgpa: (json['cgpa'] as num?)?.toDouble(),
      skills: (json['skills'] as List).cast<String>(),
      workExperience: (json['workExperience'] as List).map((w) {
        final map = w as Map<String, dynamic>;
        return ParsedWorkExperience(
          position: map['position'] as String?,
          companyName: map['companyName'] as String?,
          startYear: map['startYear'] as int?,
          endYear: map['endYear'] as int?,
          isCurrent: map['isCurrent'] as bool? ?? false,
          description: map['description'] as String?,
        );
      }).toList(),
      source: 'nlp',
    );
  }

  /// Extracts raw text from a PDF or DOCX file.
  Future<String> extractText(File file) async {
    final ext = file.path.split('.').last.toLowerCase();
    final bytes = await file.readAsBytes();

    if (ext == 'pdf') {
      final document = PdfDocument(inputBytes: bytes);
      final text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } else if (ext == 'docx') {
      return docxToText(bytes);
    }
    throw Exception('Unsupported file type for text extraction: $ext');
  }

  /// The regex parser, plus the small on-device neural network (nlp_service/tf_model, TensorFlow
  /// Lite) for resumes that have no skills list, where the regex parser finds no skills. Same plan as
  /// the laptop service: rules first, the model only as the second try. If the model is not available
  /// the result is exactly [parse]'s.
  Future<ParsedResumeData> parseOnDevice(String text) async {
    final base = parse(text);
    if (base.skills.isNotEmpty) return base;
    final skills = await SkillTaggerService.instance.extract(text);
    if (skills.isEmpty) return base;
    return ParsedResumeData(
      fullName: base.fullName,
      phone: base.phone,
      address: base.address,
      dateOfBirth: base.dateOfBirth,
      programme: base.programme,
      faculty: base.faculty,
      semester: base.semester,
      cgpa: base.cgpa,
      skills: skills,
      workExperience: base.workExperience,
      source: 'regex+model',
    );
  }

  ParsedResumeData parse(String text) {
    return ParsedResumeData(
      fullName: _extractName(text),
      phone: _extractPhone(text),
      address: _extractAddress(text),
      dateOfBirth: _extractDob(text),
      programme: _extractProgramme(text),
      faculty: _extractFaculty(text),
      semester: _extractSemester(text),
      cgpa: _extractCgpa(text),
      skills: _extractSkills(text),
      workExperience: _extractWorkExperience(text),
    );
  }

  // -----------------------------------------------------------------
  // Section heading aliases — resumes label the same section many
  // different ways (confirmed against common resume-writing guides).
  // -----------------------------------------------------------------

  static const List<String> _skillsHeadings = [
    'technical skills', 'key skills', 'core competencies', 'areas of expertise',
    'skills & competencies', 'skills and competencies', 'competencies', 'expertise',
    'skills & tools', 'skills and tools', 'it skills', 'computer skills', 'skills summary',
    'soft skills', 'hard skills', 'technical proficiency', 'technologies',
    'tools & technologies', 'tools and technologies', 'skills',
  ];

  static const List<String> _workHeadings = [
    'professional experience', 'work experience', 'employment history',
    'work history', 'relevant experience', 'experience',
    // Malaysian students usually call it industrial training or an internship
    'industrial training', 'internship experience', 'internships', 'internship',
    'work experience & internships', 'work experience and internships',
    'industrial attachment', 'practical training', 'training',
  ];

  static const List<String> _allSectionHeadings = [
    ..._skillsHeadings,
    ..._workHeadings,
    'education', 'academic background', 'qualifications',
    'projects', 'certifications', 'certificates', 'achievements', 'awards',
    'activities', 'extracurricular', 'co-curricular', 'hobbies', 'interests',
    'languages', 'publications', 'references', 'summary', 'objective',
    'profile', 'about me', 'personal details', 'personal information',
    'curriculum vitae', 'resume', 'cv', 'contact', 'contact information', 'contact details',
    'career objective', 'personal profile', 'declaration',
    'referees', 'referee', 'reference', 'character reference', 'character references', 'professional references',
    'additional information', 'other information', 'volunteer', 'volunteering', 'volunteer experience',
    'extracurricular activities', 'extra-curricular activities', 'co-curricular activities', 'cocurricular activities',
    'activities & achievements', 'awards & achievements', 'awards and achievements', 'honours', 'honors',
    'honours & awards', 'honors & awards', 'scholarships', 'academic projects', 'personal projects',
    'personal particulars', 'particulars', 'biodata', 'hobbies & interests', 'hobbies and interests',
    'languages spoken', 'language proficiency', 'licenses & certifications', 'courses', 'awards & scholarships',
  ];

  /// Words that mark a line as a section heading even when the exact wording is not in the list above
  /// ("AWARDS, HONOURS & CO-CURRICULAR", "REFEREE"); used only for lines written in capitals or ending in ':'.
  /// The strong ones are never a skill; the weak ones ("PROJECT MANAGEMENT", "LANGUAGES") are checked against the
  /// skills vocabulary first.
  static final RegExp _headingStemStrong = RegExp(
    r'\b(?:referees?|references?|activities|achievements?|awards?|honou?rs?|declaration|particulars|volunteer\w*|curricular|'
    r'scholarships?|publications?|hobbies|biodata|education|experience)\b',
    caseSensitive: false,
  );
  static final RegExp _headingStemWeak = RegExp(r'\b(?:projects?|certifications?|certificates?|interests?|languages?)\b', caseSensitive: false);

  /// True when [raw] is a heading line: a known heading, or a short line in capitals / ending in ':' that
  /// contains a heading word.
  static bool _isHeadingLine(String raw) {
    final t = raw.trim();
    final key = _headingKey(t);
    if (key.isEmpty || key.length > 45) return false;
    if (key.length <= 40 && _allSectionHeadings.contains(key)) return true;
    if (t.split(RegExp(r'\s+')).length > 7) return false;
    final shouty = t == t.toUpperCase() && RegExp(r'[A-Z]').hasMatch(t);
    if (!shouty && !t.endsWith(':')) return false;
    if (_headingStemStrong.hasMatch(key)) return true;
    if (key.split(RegExp(r'[^a-z+#.]+')).any(kSkillWords.contains)) return false;
    return _headingStemWeak.hasMatch(key);
  }

  /// A page number or page footer ("Page 1 of 2", "— 1 —") that a PDF puts into the text.
  static final RegExp _pageFooter = RegExp(r'^(?:page\s+\d+(?:\s*(?:of|/)\s*\d+)?|[—–-]+\s*\d+\s*[—–-]+)$', caseSensitive: false);

  static String _headingKey(String line) => line.trim().toLowerCase().replaceAll(RegExp(r'[:\-–—]+$'), '').trim();

  /// Every section whose heading is one of [headingAliases]: the lines that follow each heading,
  /// up to (but excluding) the next recognised heading. Empty when no heading appears as a
  /// standalone line.
  List<List<String>> _extractSections(String text, List<String> headingAliases) {
    final lines = text.split('\n');
    final blocks = <List<String>>[];
    for (var i = 0; i < lines.length; i++) {
      final cleaned = _headingKey(lines[i]);
      if (cleaned.isEmpty || cleaned.length > 40 || !headingAliases.contains(cleaned)) continue;
      final collected = <String>[];
      for (var j = i + 1; j < lines.length; j++) {
        final raw = lines[j];
        if (_isHeadingLine(raw)) break; // next section
        if (_pageFooter.hasMatch(raw.trim())) continue;
        collected.add(raw);
        if (collected.length >= 40) break; // safety bound
      }
      blocks.add(collected);
    }
    return blocks;
  }

  /// "Skills: Python, Java, SQL" written on ONE line (no heading line with a list under it).
  List<String> _inlineSkillLines(String text) {
    final aliases = [..._skillsHeadings]..sort((a, b) => b.length.compareTo(a.length));
    final pattern = RegExp('^\\s*(?:${aliases.map(RegExp.escape).join('|')})\\s*:\\s*(.+)\$', caseSensitive: false, multiLine: true);
    return [for (final m in pattern.allMatches(text)) m.group(1)!];
  }

  /// Short abbreviations joined by a slash that are ONE skill ("CI/CD", "UI/UX", "TCP/IP"); any
  /// other "A/B" is two skills written together ("HTML/CSS").
  static final RegExp _slashCompound = RegExp(r'^[A-Z0-9+#.]{1,6}/[A-Z0-9+#.]{1,6}$');

  /// A proficiency level written after a skill: "Python (Advanced)", "SQL - Intermediate", "Java (3 years)".
  static final RegExp _skillLevel = RegExp(
    r'\s*(?:[\(\[]\s*(?:advanced|intermediate|beginner|basic|proficient|expert|fluent|familiar|good|native|\d+\+?\s*(?:years?|yrs?))[^\)\]]*[\)\]]'
    r'|[\-–—:]\s*(?:advanced|intermediate|beginner|basic|proficient|expert|fluent|familiar|good))\s*$',
    caseSensitive: false,
  );

  static final RegExp _junkSkillA = RegExp(
    r'@|https?:|www\.|linkedin|github\.com|\d{5,}|upon request|references? (?:are )?(?:available|provided)|\b(?:tel|phone|mobile|email|address)\b',
    caseSensitive: false,
  );
  static final RegExp _junkSkillB = RegExp(r'^(?:Mr|Mrs|Ms|Miss|Dr|Prof|Encik|Puan|Cik|Tuan|Datin|Dato)\.?\s+[A-Z][a-z]');

  /// True when [token] cannot be a skill: contact details, a referee ("Dr. Ahmad, Senior Lecturer"), a sentence.
  static bool _junkSkill(String token) {
    if (_junkSkillA.hasMatch(token) || _junkSkillB.hasMatch(token)) return true;
    return token.split(RegExp(r'\s+')).length > 5;
  }

  List<String> _extractSkills(String text) {
    final blockLines = <String>[
      ..._inlineSkillLines(text),
      for (final block in _extractSections(text, _skillsHeadings)) ...block,
    ];
    if (blockLines.isEmpty) return [];

    final tokens = <String>[];
    final seen = <String>{};
    for (final rawLine in blockLines) {
      // Strip a leading bullet glyph before splitting the rest of the line
      // on delimiters — plain hyphens are left alone since compound skill
      // names ("front-end", "problem-solving") legitimately contain them.
      final line = rawLine.trim().replaceFirst(RegExp(r'^[•▪◦·●○■*\-]\s+'), '');
      if (line.isEmpty) continue;
      for (final part in line.split(RegExp(r'[,;|]|\s{2,}'))) {
        var cleaned = part.trim().replaceAll(RegExp(r'^[•▪◦·●○■*]+|[.]+$'), '').trim();
        // "Programming: Python" (a category label in front of the first item) -> "Python".
        cleaned = cleaned.replaceFirst(RegExp(r'^[A-Za-z][A-Za-z &/]{2,24}:\s*'), '');
        // "Python (Advanced)" -> "Python".
        cleaned = cleaned.replaceFirst(_skillLevel, '').trim();
        final pieces = cleaned.contains('/') && !_slashCompound.hasMatch(cleaned) ? cleaned.split(RegExp(r'\s*/\s*')) : [cleaned];
        for (final piece in pieces) {
          final token = piece.trim().replaceFirst(_skillLevel, '').trim();
          if (token.isEmpty || token.length < 1 || token.length > 30) continue;
          if (!RegExp(r'[A-Za-z]').hasMatch(token)) continue; // skip pure numbers/symbols
          if (_junkSkill(token)) continue; // an email, a phone, a referee's name, "available upon request"...
          final key = token.toLowerCase();
          if (seen.add(key)) tokens.add(token);
        }
      }
      if (tokens.length >= 40) break;
    }
    return tokens;
  }

  static const String _monthWord = r'(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?';

  // Matches a date range like "Jun 2022 - Aug 2022", "2022 – Present",
  // "January 2021 to December 2022", "2020-2021", or months inside one
  // year: "Jun – Aug 2024".
  static final RegExp _dateRangePattern = RegExp(
    '(?:($_monthWord)\\s+)?(\\d{4})\\s*(?:-|–|—|to)\\s*(?:($_monthWord)\\s+)?(present|current|now|\\d{4})'
    '|($_monthWord)\\s*(?:-|–|—|to)\\s*($_monthWord)\\s+(\\d{4})',
    caseSensitive: false,
  );

  List<ParsedWorkExperience> _extractWorkExperience(String text) {
    final entries = <ParsedWorkExperience>[];
    for (final block in _extractSections(text, _workHeadings)) {
      entries.addAll(_workEntriesOf(block));
      if (entries.length >= 8) break;
    }
    return entries.take(8).toList();
  }

  /// "Position, Company" / "Position at Company" / "Position | Company" / "Position - Company".
  (String?, String?) _splitTitle(String title) {
    final m = RegExp(r'^(.*?)(?:\s+(?:at|@|-|–|—|\|)\s+|\s*,\s+)(.*)$').firstMatch(title);
    if (m == null) return (title, null);
    return (m.group(1)?.trim(), m.group(2)?.trim());
  }

  static final RegExp _bulletStart = RegExp(r'^[•▪◦·●○■*\-]\s*');

  List<ParsedWorkExperience> _workEntriesOf(List<String> blockLines) {
    if (blockLines.isEmpty) return [];

    // Find every line that contains a date range — each one anchors one
    // job entry. Everything between two anchors (or start/end of block)
    // belongs to that entry.
    final anchorIndexes = <int>[];
    for (var i = 0; i < blockLines.length; i++) {
      if (_dateRangePattern.hasMatch(blockLines[i])) anchorIndexes.add(i);
    }
    if (anchorIndexes.isEmpty) {
      // No recognisable dates — still surface the section as one
      // best-effort entry so the user has something to edit rather than
      // nothing at all.
      final nonEmpty = blockLines.map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (nonEmpty.isEmpty) return [];
      return [
        ParsedWorkExperience(
          position: nonEmpty.first.length <= 60 ? nonEmpty.first : null,
          description: nonEmpty.join('\n'),
        ),
      ];
    }

    final entries = <ParsedWorkExperience>[];
    for (var a = 0; a < anchorIndexes.length && entries.length < 8; a++) {
      final anchorLine = anchorIndexes[a];
      final nextAnchor = a + 1 < anchorIndexes.length ? anchorIndexes[a + 1] : blockLines.length;

      final dateMatch = _dateRangePattern.firstMatch(blockLines[anchorLine])!;
      int? startYear;
      int? endYear;
      var isCurrent = false;
      if (dateMatch.group(7) != null) {
        // "Jun – Aug 2024": both months fall in one year
        startYear = endYear = int.tryParse(dateMatch.group(7)!);
      } else {
        startYear = int.tryParse(dateMatch.group(2)!);
        final endRaw = dateMatch.group(4)!;
        isCurrent = RegExp(r'present|current|now', caseSensitive: false).hasMatch(endRaw);
        endYear = isCurrent ? null : int.tryParse(endRaw);
      }

      // What is left of the line once the dates are taken out; stray separators and brackets go too.
      final dateStripped = blockLines[anchorLine]
          .replaceRange(dateMatch.start, dateMatch.end, ' ')
          .replaceAll(RegExp(r'[()\[\]]'), ' ')
          .replaceFirst(_bulletStart, '')
          .replaceAll(RegExp(r'^[\s:,;|\-–—]+|[\s:,;|\-–—]+$'), '')
          .replaceAll(RegExp(r'\s{2,}'), ' ')
          .trim();

      String? position;
      String? company;
      if (dateStripped.isEmpty) {
        // The date was on its own line: the title is the line just before it.
        final prev = anchorLine > 0 ? blockLines[anchorLine - 1].trim().replaceFirst(_bulletStart, '') : '';
        if (prev.isNotEmpty) (position, company) = _splitTitle(prev);
      } else {
        (position, company) = _splitTitle(dateStripped);
        if (company == null) {
          // "Position" on one line, "Company, dates" on the next.
          String? prev;
          for (var k = anchorLine - 1; k >= 0; k--) {
            final l = blockLines[k].trim();
            if (l.isEmpty) continue;
            prev = l;
            break;
          }
          final prevIsTitle = prev != null &&
              !_bulletStart.hasMatch(prev) &&
              !_dateRangePattern.hasMatch(prev) &&
              prev.length <= 80 &&
              !prev.endsWith('.');
          if (prevIsTitle) {
            company = dateStripped;
            position = prev;
          }
        }
      }

      final descriptionLines = <String>[];
      for (var i = anchorLine + 1; i < nextAnchor; i++) {
        final l = blockLines[i].trim();
        if (l.isEmpty) continue;
        descriptionLines.add(l.replaceFirst(RegExp(r'^[•▪◦·●○■*\-]\s*'), ''));
      }
      final description = descriptionLines.isEmpty ? null : descriptionLines.join('\n');

      if ((position?.isNotEmpty ?? false) || (company?.isNotEmpty ?? false) || description != null) {
        entries.add(ParsedWorkExperience(
          position: (position?.isEmpty ?? true) ? null : position,
          companyName: (company?.isEmpty ?? true) ? null : company,
          startYear: startYear,
          endYear: endYear,
          isCurrent: isCurrent,
          description: description,
        ));
      }
    }
    return entries;
  }

  // -----------------------------------------------------------------
  // Individual field extractors — all best-effort, regex-based.
  // -----------------------------------------------------------------

  static final RegExp _titleBeforeName = RegExp(r'^(?:mr|ms|mrs|miss|dr|encik|puan|cik|tuan|en|pn)\.?\s+', caseSensitive: false);

  /// The name in [candidate] when the whole text looks like a person's name, else null.
  String? _asName(String candidate) {
    // Strip a leading bullet/icon glyph some templates prefix the name with.
    var cleaned = candidate.trim().replaceFirst(RegExp(r'^[^\w]+'), '').trim();
    // "Resume of Siti ...", "Curriculum Vitae - Siti ..." -> the name after it.
    cleaned = cleaned.replaceFirst(RegExp(r'^(?:resume|curriculum vitae|cv)(?:\s+of)?\s*[:\-–]?\s*', caseSensitive: false), '').trim();
    // A title in front of the name ("Ms. Siti ...", "Encik Ali ...") is not part of it.
    cleaned = cleaned.replaceFirst(_titleBeforeName, '');
    if (cleaned.isEmpty || cleaned.length > 60) return null;
    if (RegExp(r'[0-9@]').hasMatch(cleaned)) return null; // digits/email: not a name
    if (_allSectionHeadings.contains(_headingKey(cleaned))) return null; // "Personal Details", "Curriculum Vitae"...
    final words = cleaned.split(RegExp(r'\s+'));
    if (words.length < 2 || words.length > 5) return null;
    // "a/l", "a/p", "s/o", "d/o" ("son/daughter of") are normal inside Malaysian names.
    final looksLikeName = words.every((w) => RegExp(r"^(?:[A-Za-z][a-zA-Z.'-]*|[asd]/[lpo])$", caseSensitive: false).hasMatch(w));
    if (!looksLikeName) return null;
    // A person's name is written with capitals ("Siti Aminah", "LIM WEI JIE"); only these small
    // words stay lower-case inside it ("Ali bin Abu", "Priya a/p Rajan", "Jan van Dyk").
    const particles = {'bin', 'binti', 'bte', 'bt', 'a/l', 'a/p', 's/o', 'd/o', 'al', 'el', 'de', 'van', 'von', 'ibn', 'abu'};
    if (words.any((w) => !particles.contains(w.toLowerCase()) && !RegExp(r'^[A-Z]').hasMatch(w))) return null;
    // A job title or a resume heading is not a person ("INFORMATION TECHNOLOGY MANAGER", "Core Accomplishments").
    if (words.any((w) => _notNameWords.contains(w.toLowerCase().replaceAll('.', '')))) return null;
    // A list of skills ("Python Java", "Microsoft Office", "Problem Solving") or a place is not a person.
    if (words.any((w) => kSkillWords.contains(w.toLowerCase().replaceAll(RegExp(r'[^a-z+#.]'), '')))) return null;
    if (kSkillPhrases.contains(cleaned.toLowerCase())) return null;
    if (words.any((w) => _placeWords.contains(w.toLowerCase().replaceAll('.', '')))) return null;
    return cleaned;
  }

  static const Set<String> _placeWords = {
    'kuala', 'lumpur', 'selangor', 'johor', 'bahru', 'penang', 'pinang', 'perak', 'kedah', 'kelantan', 'terengganu', 'pahang',
    'sabah', 'sarawak', 'melaka', 'malacca', 'sembilan', 'putrajaya', 'labuan', 'malaysia', 'singapore', 'petaling', 'cheras',
    'ipoh', 'kuching', 'seremban', 'klang', 'subang', 'bangsar', 'damansara', 'ampang', 'kajang', 'cyberjaya', 'perlis', 'kangar',
    'jalan', 'lorong', 'bandar', 'kampung', 'wilayah', 'persekutuan', 'darul', 'ehsan', 'street', 'road', 'avenue',
  };

  static const Set<String> _notNameWords = {
    'technology', 'technologies', 'manager', 'engineer', 'engineering', 'specialist', 'director', 'technician', 'coordinator',
    'developer', 'analyst', 'intern', 'internship', 'assistant', 'administrator', 'officer', 'executive', 'consultant',
    'designer', 'accountant', 'supervisor', 'associate', 'senior', 'junior', 'lead', 'chief', 'summary', 'overview',
    'accomplishments', 'experience', 'education', 'skills', 'objective', 'profile', 'company', 'project', 'projects',
    'management', 'operations', 'services', 'support', 'quality', 'program', 'programme', 'team', 'highlights', 'qualifications',
    'professional', 'career', 'personal', 'details', 'information', 'contact', 'references', 'achievements', 'certifications',
    'declaration', 'vitae', 'curriculum', 'resume', 'student', 'graduate', 'fresh', 'seeking', 'university', 'college',
    'sdn', 'bhd', 'berhad', 'limited', 'ltd', 'inc', 'corporation',
    'teacher', 'representative', 'generalist', 'merchandiser', 'sales', 'hr', 'rep', 'advisor', 'candidate', 'strengths',
    'proficiency', 'relations', 'department', 'startup', 'finance', 'accounting', 'marketing', 'clerk', 'nurse', 'driver',
    'worker', 'operator', 'agent', 'architect', 'trainer', 'instructor', 'tutor', 'lecturer', 'technologist', 'programmer',
    'tester', 'scientist', 'planner', 'buyer', 'cashier', 'receptionist', 'secretary', 'sr', 'jr', 'phd', 'computer', 'client',
    'center', 'centre', 'office', 'directory', 'microsoft',
  };

  /// [text] without the References / Referees section at the end: the people named there (and their
  /// phone numbers) are not the candidate.
  static String _beforeReferences(String text) {
    final lines = text.split('\n');
    final heading = RegExp(r'^(?:character\s+|professional\s+|academic\s+)?(?:references?|referees?)\s*[:\-–]?$', caseSensitive: false);
    for (var i = 5; i < lines.length; i++) {
      if (heading.hasMatch(lines[i].trim())) return lines.take(i).join('\n');
    }
    return text;
  }

  /// The parts of a line that could be the name: the whole line, then each part of "NAME | Job title",
  /// "NAME • email", "NAME – Software Developer".
  static List<String> _nameCandidates(String line) {
    final parts = line.split(RegExp(r'\s*[|•·–—]\s*|\s+-\s+|\s+/\s+')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    return parts.length > 1 ? [line, ...parts] : [line];
  }

  static bool _looksLikeContactOrRole(String line) =>
      line.contains('@') ||
      RegExp(r'\d{3}[\s\-]?\d{3,4}').hasMatch(line) ||
      RegExp(r'\b(?:student|undergraduate|graduate|developer|engineer|analyst|intern|designer|manager|programmer|executive)\b', caseSensitive: false)
          .hasMatch(line);

  String? _extractName(String text) {
    final body = _beforeReferences(text);
    final lines = body.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    // What the skills section lists is never the name ("Python Java" can look like a two-word name).
    final skillKeys = _extractSkills(body).map((s) => s.toLowerCase()).toSet();
    String? ok(String? name) => name == null || skillKeys.contains(name.toLowerCase()) ? null : name;

    // 1. An explicit "Name: ..." / "Full name: ..." line near the top is the most reliable.
    for (final line in lines.take(25)) {
      final m = RegExp(r'^(?:full\s+)?name\s*[:\-–]\s*(.+)$', caseSensitive: false).firstMatch(line);
      if (m != null) {
        final name = ok(_asName(m.group(1)!));
        if (name != null) return name;
      }
    }
    // 2. Resumes put the candidate's name at the very top (after at most a title line such as
    // "CURRICULUM VITAE" or an address / contact line), usually in Title Case or ALL CAPS, sometimes
    // followed by a job title on the same line ("LAU YIK HONG | Software Developer").
    for (final line in lines.take(8)) {
      if (line.length > 90) continue;
      for (final part in _nameCandidates(line)) {
        if (part.length > 60) continue;
        final name = ok(_asName(part));
        if (name != null) return name;
      }
    }
    // 3. Two-column templates put a sidebar (contact, skills) before the name in the extracted text, so
    // the name is further down. Accept a name-shaped line there only when it is written in capitals, or
    // sits next to a contact / job-title line.
    for (var i = 8; i < lines.length && i < 40; i++) {
      final line = lines[i];
      if (line.length > 60) continue;
      final name = ok(_asName(line));
      if (name == null) continue;
      final shouty = line == line.toUpperCase();
      final near = [i - 1, i + 1].any((k) => k >= 0 && k < lines.length && _looksLikeContactOrRole(lines[k]));
      if (shouty || near) return name;
    }
    return null;
  }

  /// "Faculty: ..." or a line / bracket that says "Faculty of <name>".
  String? _extractFaculty(String text) {
    final labelled = _extractLabelled(text, ['faculty']);
    if (labelled != null) return labelled;
    final m = RegExp(r'\b(Faculty of [A-Z][A-Za-z ,&]+?)(?=\)|\.|\n|$)', multiLine: true).firstMatch(text);
    return m?.group(1)?.trim();
  }

  /// A run of digits that might be a phone number: digits, spaces, hyphens and brackets, optionally after "+".
  static final RegExp _phoneRun = RegExp(r'(?<![\w@])(?:\+\s?)?\(?\d[\d\s\-()]{5,}\d(?![\w@])');

  /// True when [candidate] is written the way people write phone numbers in Malaysia (and, with a "+" country
  /// code, abroad): "+60 12-345 6789", "012-3456789", "03-1234 5678", "+65 9123 4567". A postcode (5 digits), an
  /// IC number, a date or a year range is not.
  static bool _isPhone(String candidate) {
    final plus = candidate.trimLeft().startsWith('+');
    final d = candidate.replaceAll(RegExp(r'\D'), '');
    if (d.length < 9 || d.length > 14) return false;
    bool national(String n) => RegExp(r'^1\d{8,9}$').hasMatch(n) || RegExp(r'^[3-9]\d{7,8}$').hasMatch(n);
    if (plus) {
      if (d.startsWith('60')) return national(d.substring(2));
      return !d.startsWith('0'); // another country's number, written with its + code
    }
    if (d.startsWith('60')) return d.length >= 11 && national(d.substring(2)); // 60123456789
    if (d.startsWith('0')) return national(d.substring(1)); // 0123456789, 03-12345678
    return false;
  }

  /// The first phone number written in [line], or null.
  static String? _phoneIn(String line) {
    final cleaned = line.replaceAll('(+60)', '+60').replaceAll('(+6)', '+6');
    for (final m in _phoneRun.allMatches(cleaned)) {
      // The run may hold a postcode or a year next to the number ("11900 012-345 6789"): try every
      // stretch of its space-separated groups, earliest start and longest first.
      final groups = m.group(0)!.trim().split(RegExp(r'\s+'));
      for (var i = 0; i < groups.length; i++) {
        for (var j = groups.length; j > i; j--) {
          final candidate = groups.sublist(i, j).join(' ');
          if (_isPhone(candidate)) return candidate;
        }
      }
    }
    return null;
  }

  String? _extractPhone(String text) {
    final body = _beforeReferences(text);
    // Try an explicitly labelled field first — most reliable when present.
    final labelled = _extractLabelled(body, ['phone number', 'phone', 'mobile no', 'mobile', 'contact no', 'contact number', 'tel', 'h/p', 'hp', 'contact']);
    if (labelled != null) {
      final p = _phoneIn(labelled);
      if (p != null) return p;
    }
    // Otherwise the first number in the text that is written like a phone number (top of the page first).
    for (final line in body.split('\n')) {
      final p = _phoneIn(line);
      if (p != null) return p;
    }
    return null;
  }

  static const Map<String, int> _months = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, 'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  DateTime? _validDate(int year, int month, int day) {
    if (year < 100) year += year > 50 ? 1900 : 2000;
    if (year < 1940 || year > DateTime.now().year || month < 1 || month > 12 || day < 1) return null;
    final date = DateTime(year, month, day);
    return date.month == month && date.day == day ? date : null; // rejects 31 Feb and the like
  }

  DateTime? _extractDob(String text) {
    final label = RegExp(r'(?:date\s+of\s+birth|d\.?\s?o\.?\s?b\.?|birth\s*date|birthday|born)\b\s*(?:on)?\s*[:\-–]?\s*(.{6,40})', caseSensitive: false)
        .firstMatch(text);
    if (label == null) return null;
    final raw = label.group(1)!;

    // 2002-03-12
    var m = RegExp(r'(\d{4})[\/\-.](\d{1,2})[\/\-.](\d{1,2})').firstMatch(raw);
    if (m != null) return _validDate(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
    // 12/03/2002, 12-03-02, 12.03.2002
    m = RegExp(r'(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{2,4})').firstMatch(raw);
    if (m != null) return _validDate(int.parse(m.group(3)!), int.parse(m.group(2)!), int.parse(m.group(1)!));
    // 12 March 2002, 12th Mar 2002
    m = RegExp(r'(\d{1,2})(?:st|nd|rd|th)?\s+([A-Za-z]{3,9})\.?,?\s+(\d{4})').firstMatch(raw);
    if (m != null) {
      final month = _months[m.group(2)!.substring(0, 3).toLowerCase()];
      if (month != null) return _validDate(int.parse(m.group(3)!), month, int.parse(m.group(1)!));
    }
    // March 12, 2002
    m = RegExp(r'([A-Za-z]{3,9})\.?\s+(\d{1,2})(?:st|nd|rd|th)?,?\s+(\d{4})').firstMatch(raw);
    if (m != null) {
      final month = _months[m.group(1)!.substring(0, 3).toLowerCase()];
      if (month != null) return _validDate(int.parse(m.group(3)!), month, int.parse(m.group(2)!));
    }
    return null;
  }

  static final RegExp _postcode = RegExp(r'\b\d{5}\b');

  String? _extractAddress(String text) {
    final lines = text.split('\n');
    final labelled = _extractLabelled(
      text,
      ['residential address', 'home address', 'current address', 'permanent address', 'correspondence address', 'address', 'residing at', 'location'],
    );
    if (labelled != null) {
      // The address often continues on the next line ("Address: No. 12, Jalan X" / "50450 Kuala Lumpur").
      final index = lines.indexWhere((l) => l.contains(labelled));
      if (index >= 0 && index + 1 < lines.length && !_postcode.hasMatch(labelled)) {
        final next = lines[index + 1].trim();
        final nextKey = _headingKey(next);
        if (next.isNotEmpty &&
            next.length <= 90 &&
            !next.contains(':') &&
            !_allSectionHeadings.contains(nextKey) &&
            (_postcode.hasMatch(next) || next.contains(','))) {
          return '$labelled, $next';
        }
      }
      return labelled;
    }

    // Fall back to scanning for a line that looks like an address even
    // without an explicit label: a 5-digit postcode, a common Malaysian
    // street-type keyword, or a generic "City, State/Country" pattern.
    final streetKeywords = RegExp(
      r'\b(jalan|jln|lorong|lrg|taman|tmn|persiaran|lot|no\.?\s?\d|blok|unit|apartment|kondominium|street|avenue|road|drive|boulevard)\b',
      caseSensitive: false,
    );
    final cityStatePattern = RegExp(r'^[A-Za-z\s]{3,30},\s*[A-Za-z\s]{2,30}$');
    for (final rawLine in lines) {
      if (rawLine.trim().isEmpty || rawLine.length > 220) continue;
      // A contact line may hold several things ("No. 2, Jalan X, 40000 Shah Alam  /  Tel 012...  /  a@b.com"):
      // look at each part on its own so the phone and the email do not end up in the address.
      for (final part in rawLine.split(RegExp(r'\s+/\s+|\s*[|•·]\s*|\s{3,}'))) {
        final line = part.trim();
        if (line.isEmpty || line.length > 150 || line.contains('@')) continue;
        if (streetKeywords.hasMatch(line) && _postcode.hasMatch(line)) return line;
        if (streetKeywords.hasMatch(line) && line.length > 15) return line;
      }
    }
    // Last resort: a short "City, State" style line near the top of the
    // resume (common when the address is abbreviated to just a locality).
    final topLines = lines.take(10).map((l) => l.trim());
    for (final line in topLines) {
      if (cityStatePattern.hasMatch(line)) return line;
    }
    return null;
  }

  String? _extractProgramme(String text) {
    final labelled = _extractLabelled(text, ['programme', 'program', 'course', 'field of study', 'major']);
    if (labelled != null) return labelled;

    // Fall back to a line naming a degree type even without a "Programme:"
    // label — common under an unlabelled "Education" section, e.g.
    // "Bachelor of Software Engineering (Hons), TAR UMT, 2022-2025" or
    // "Currently pursuing Bachelor of ... at TAR UMT."
    final degree = RegExp(
      r'\b((?:bachelor|diploma|master|foundation|certificate)\b[^,|\n]*?)(?=\s+(?:at|from|@)\s+|\s*[,|]|\.?\s*$|\n)',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(text);
    if (degree == null) return null;
    final line = degree.group(1)!.trim();
    if (line.isEmpty || line.length > 150) return null;
    return line;
  }

  /// The value after one of [labels] ("Phone: 012...", "Address - ...", "Tel\n012..."). The label must
  /// not be the tail of a longer word ("hotel:" is not "tel:") and "Email Address:" is not "Address:".
  /// When nothing follows the label on its line, the next non-empty line is the value.
  String? _extractLabelled(String text, List<String> labels) {
    final lines = text.split('\n');
    for (final label in labels) {
      final escaped = RegExp.escape(label);
      final sameLine = RegExp('(?<![A-Za-z])(?<!e-?mail\\s)$escaped\\s*[:\\-–]\\s*(.+)', caseSensitive: false);
      final match = sameLine.firstMatch(text);
      if (match != null) {
        final value = match.group(1)!.trim();
        if (value.isNotEmpty && value.length < 150) return value;
      }
      // label alone on its line: "Phone" / "Residential Address:" and the value below it
      final alone = RegExp('^\\s*$escaped\\s*[:\\-–]?\\s*\$', caseSensitive: false);
      for (var i = 0; i < lines.length - 1; i++) {
        if (!alone.hasMatch(lines[i])) continue;
        for (var j = i + 1; j < lines.length && j <= i + 2; j++) {
          final value = lines[j].trim();
          if (value.isEmpty) continue;
          if (value.length < 150 && !_allSectionHeadings.contains(_headingKey(value))) return value;
          break;
        }
      }
    }
    return null;
  }

  int? _extractSemester(String text) {
    for (final m in RegExp(r'\bsem(?:ester)?\.?\s*[:\-]?\s*(\d{1,2})\b', caseSensitive: false).allMatches(text)) {
      final value = int.tryParse(m.group(1)!);
      if (value != null && value >= 1 && value <= 4) return value; // the app offers semesters 1 to 4
    }
    return null;
  }

  double? _extractCgpa(String text) {
    const label = r'(?:c\.?g\.?p\.?a\.?|cumulative\s+(?:grade\s+point\s+average|gpa)|grade\s+point\s+average|gpa)';
    // CGPA: 3.45 / CGPA of 3.45 / CGPA (3.45) / GPA 3.45/4.0 / Current CGPA - 3.45
    final after = RegExp('\\b$label[^\\d\\n]{0,30}?(\\d\\.\\d{1,2})(?!\\d)', caseSensitive: false);
    // 3.45 CGPA / 3.45/4.00 CGPA
    final before = RegExp('(\\d\\.\\d{1,2})\\s*(?:/\\s*4(?:\\.0+)?\\s*)?$label\\b', caseSensitive: false);
    for (final re in [after, before]) {
      for (final m in re.allMatches(text)) {
        final value = double.tryParse(m.group(1)!);
        if (value != null && value > 0 && value <= 4.0) return value;
      }
    }
    return null;
  }
}
