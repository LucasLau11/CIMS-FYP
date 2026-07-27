import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:docx_to_text/docx_to_text.dart';

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

  ParsedResumeData parse(String text) {
    return ParsedResumeData(
      fullName: _extractName(text),
      phone: _extractPhone(text),
      address: _extractAddress(text),
      dateOfBirth: _extractDob(text),
      programme: _extractProgramme(text),
      faculty: _extractLabelled(text, ['faculty']),
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
    'skills & competencies', 'competencies', 'expertise', 'skills',
  ];

  static const List<String> _workHeadings = [
    'professional experience', 'work experience', 'employment history',
    'work history', 'relevant experience', 'experience',
  ];

  static const List<String> _allSectionHeadings = [
    ..._skillsHeadings,
    ..._workHeadings,
    'education', 'academic background', 'qualifications',
    'projects', 'certifications', 'certificates', 'achievements', 'awards',
    'activities', 'extracurricular', 'co-curricular', 'hobbies', 'interests',
    'languages', 'publications', 'references', 'summary', 'objective',
    'profile', 'about me', 'personal details', 'personal information',
  ];

  /// Finds a section by heading alias and returns the lines that follow it,
  /// up to (but excluding) the next recognised section heading. Returns
  /// null if none of [headingAliases] appear as a standalone line.
  List<String>? _extractSection(String text, List<String> headingAliases) {
    final lines = text.split('\n');
    // Longest alias first so e.g. "core competencies" matches before a
    // looser single-word alias would.
    final sorted = [...headingAliases]..sort((a, b) => b.length.compareTo(a.length));

    int? headingIndex;
    for (var i = 0; i < lines.length; i++) {
      final cleaned = lines[i].trim().toLowerCase().replaceAll(RegExp(r'[:\-–—]+$'), '').trim();
      if (cleaned.isEmpty || cleaned.length > 40) continue;
      if (sorted.any((alias) => cleaned == alias)) {
        headingIndex = i;
        break;
      }
    }
    if (headingIndex == null) return null;

    final collected = <String>[];
    for (var i = headingIndex + 1; i < lines.length; i++) {
      final raw = lines[i];
      final cleaned = raw.trim().toLowerCase().replaceAll(RegExp(r'[:\-–—]+$'), '').trim();
      if (cleaned.isNotEmpty && cleaned.length <= 40 && _allSectionHeadings.contains(cleaned)) {
        break; // hit the next section
      }
      collected.add(raw);
      if (collected.length >= 40) break; // safety bound
    }
    return collected;
  }

  List<String> _extractSkills(String text) {
    final blockLines = _extractSection(text, _skillsHeadings);
    if (blockLines == null) return [];

    final tokens = <String>[];
    final seen = <String>{};
    for (final rawLine in blockLines) {
      // Strip a leading bullet glyph before splitting the rest of the line
      // on delimiters — plain hyphens are left alone since compound skill
      // names ("front-end", "problem-solving") legitimately contain them.
      final line = rawLine.trim().replaceFirst(RegExp(r'^[•▪◦·*\-]\s+'), '');
      if (line.isEmpty) continue;
      for (final part in line.split(RegExp(r'[,;|/]|\s{2,}'))) {
        final token = part.trim().replaceAll(RegExp(r'^[•▪◦·*]+|[.]+$'), '').trim();
        if (token.isEmpty || token.length < 2 || token.length > 30) continue;
        if (!RegExp(r'[A-Za-z]').hasMatch(token)) continue; // skip pure numbers/symbols
        final key = token.toLowerCase();
        if (seen.add(key)) tokens.add(token);
      }
      if (tokens.length >= 40) break;
    }
    return tokens;
  }

  // Matches a date range like "Jun 2022 - Aug 2022", "2022 – Present",
  // "January 2021 to December 2022", "2020-2021".
  static final RegExp _dateRangePattern = RegExp(
    r'((?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?\s+)?(\d{4})\s*(?:-|–|—|to)\s*'
    r'((?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?\s+)?(present|current|now|\d{4})',
    caseSensitive: false,
  );

  List<ParsedWorkExperience> _extractWorkExperience(String text) {
    final blockLines = _extractSection(text, _workHeadings);
    if (blockLines == null || blockLines.isEmpty) return [];

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
      final startYear = int.tryParse(dateMatch.group(2)!);
      final endRaw = dateMatch.group(4)!;
      final isCurrent = RegExp(r'present|current|now', caseSensitive: false).hasMatch(endRaw);
      final endYear = isCurrent ? null : int.tryParse(endRaw);

      // The title/company usually sits on the anchor line itself (with the
      // date trimmed off) or, if the date was on its own line, on the line
      // immediately before it.
      final dateStripped = blockLines[anchorLine].replaceRange(dateMatch.start, dateMatch.end, '').trim();
      final titleLine = dateStripped.isNotEmpty
          ? dateStripped
          : (anchorLine > 0 ? blockLines[anchorLine - 1].trim() : '');

      String? position;
      String? company;
      final cleanedTitle = titleLine.replaceAll(RegExp(r'^[•▪◦·*\-]\s+'), '').replaceAll(RegExp(r'[()\[\]]'), '').trim();
      if (cleanedTitle.isNotEmpty) {
        final splitMatch = RegExp(r'^(.*?)\s+(?:at|@|,|-|–|—|\|)\s+(.*)$').firstMatch(cleanedTitle);
        if (splitMatch != null) {
          position = splitMatch.group(1)?.trim();
          company = splitMatch.group(2)?.trim();
        } else {
          position = cleanedTitle;
        }
      }

      final descriptionLines = <String>[];
      for (var i = anchorLine + 1; i < nextAnchor; i++) {
        final l = blockLines[i].trim();
        if (l.isEmpty) continue;
        descriptionLines.add(l.replaceFirst(RegExp(r'^[•▪◦·*\-]\s+'), ''));
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

  String? _extractName(String text) {
    // Heuristic: resumes conventionally put the candidate's name as the
    // very first non-empty line, in Title Case or ALL CAPS, without
    // digits/symbols. Allows 2-5 words since Malaysian names commonly
    // carry three or four given/family name parts.
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    for (final line in lines.take(6)) {
      if (line.length > 60) continue; // unlikely to be just a name
      if (RegExp(r'[0-9@]').hasMatch(line)) continue; // has digits/email, skip
      // Strip a leading bullet/icon glyph some templates prefix the name with.
      final cleaned = line.replaceFirst(RegExp(r'^[^\w]+'), '').trim();
      if (cleaned.isEmpty) continue;
      final words = cleaned.split(RegExp(r'\s+'));
      if (words.length < 2 || words.length > 5) continue;
      final looksLikeName = words.every((w) => RegExp(r"^[A-Za-z][a-zA-Z.'-]*$").hasMatch(w));
      if (looksLikeName) return cleaned;
    }
    return null;
  }

  String? _extractPhone(String text) {
    // Try an explicitly labelled field first — most reliable when present.
    final labelled = _extractLabelled(text, ['phone', 'mobile', 'contact no', 'contact number', 'tel', 'h/p', 'hp']);
    if (labelled != null) {
      final digitMatch = RegExp(r'[\d][\d\s\-]{7,}\d').firstMatch(labelled);
      if (digitMatch != null) return digitMatch.group(0)!.trim();
    }
    // Fall back to a general Malaysian mobile number pattern anywhere in
    // the text. Tolerant of a space or dash after the +60 country code
    // (e.g. "+60 12-345 6789"), which the stricter original pattern missed.
    final match = RegExp(
      r'(\+?60[\s\-]?)?0?1[0-9][\s\-]?[0-9]{3,4}[\s\-]?[0-9]{3,4}',
    ).firstMatch(text);
    if (match != null) return match.group(0)?.trim();
    // Broader international fallback — a run of 8-15 digits with optional
    // spaces/dashes/parentheses and an optional leading +, not preceded by
    // another digit (avoids matching the middle of a longer number/ID).
    final intlMatch = RegExp(r'(?<![\d])\+?\(?\d{1,4}\)?[\s\-]?\d{2,4}[\s\-]?\d{2,4}[\s\-]?\d{0,4}').firstMatch(text);
    return intlMatch?.group(0)?.trim();
  }

  DateTime? _extractDob(String text) {
    final labelMatch = RegExp(
      r'(?:date of birth|dob|d\.o\.b)\s*[:\-]?\s*'
      r'(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}|'
      r'[A-Za-z]+\s+\d{1,2},?\s+\d{4})',
      caseSensitive: false,
    ).firstMatch(text);
    if (labelMatch == null) return null;

    final raw = labelMatch.group(1)!;
    // Try a few common formats.
    for (final pattern in [
      RegExp(r'^(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})$'),
    ]) {
      final m = pattern.firstMatch(raw);
      if (m != null) {
        var year = int.parse(m.group(3)!);
        if (year < 100) year += 2000;
        final day = int.parse(m.group(1)!);
        final month = int.parse(m.group(2)!);
        try {
          return DateTime(year, month, day);
        } catch (_) {
          return null;
        }
      }
    }
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  String? _extractAddress(String text) {
    final labelled = _extractLabelled(
      text,
      ['address', 'residential address', 'home address', 'current address', 'location', 'residing at'],
    );
    if (labelled != null) return labelled;

    // Fall back to scanning for a line that looks like an address even
    // without an explicit label: a 5-digit postcode, a common Malaysian
    // street-type keyword, or a generic "City, State/Country" pattern.
    final streetKeywords = RegExp(
      r'\b(jalan|jln|lorong|lrg|taman|tmn|persiaran|lot|no\.?\s?\d|blok|unit|apartment|kondominium|street|avenue|road|drive|boulevard)\b',
      caseSensitive: false,
    );
    final postcode = RegExp(r'\b\d{5}\b');
    final cityStatePattern = RegExp(r'^[A-Za-z\s]{3,30},\s*[A-Za-z\s]{2,30}$');
    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.length > 150) continue;
      if (streetKeywords.hasMatch(line) && postcode.hasMatch(line)) return line;
      if (streetKeywords.hasMatch(line) && line.length > 15) return line;
    }
    // Last resort: a short "City, State" style line near the top of the
    // resume (common when the address is abbreviated to just a locality).
    final topLines = text.split('\n').take(10).map((l) => l.trim());
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
    // "Bachelor of Software Engineering (Hons), TAR UMT, 2022-2025".
    final degreeLine = RegExp(
      r'^.*\b(bachelor|diploma|master|foundation)\b.*$',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(text);
    if (degreeLine == null) return null;
    final line = degreeLine.group(0)!.trim();
    if (line.isEmpty || line.length > 150) return null;
    // Trim to just before a comma/pipe separator if the line also lists
    // the institution or dates after the degree name.
    final cut = RegExp(r'^[^,|]+').firstMatch(line);
    return (cut?.group(0) ?? line).trim();
  }

  String? _extractLabelled(String text, List<String> labels) {
    for (final label in labels) {
      final match = RegExp(
        '$label\\s*[:\\-]\\s*(.+)',
        caseSensitive: false,
      ).firstMatch(text);
      if (match != null) {
        final value = match.group(1)!.trim();
        if (value.isNotEmpty && value.length < 150) return value;
      }
    }
    return null;
  }

  int? _extractSemester(String text) {
    final match = RegExp(r'semester\s*[:\-]?\s*(\d{1,2})', caseSensitive: false).firstMatch(text);
    if (match == null) return null;
    final value = int.tryParse(match.group(1)!);
    if (value == null || value < 1 || value > 4) return null;
    return value;
  }

  double? _extractCgpa(String text) {
    final match = RegExp(r'c?gpa\s*[:\-]?\s*(\d\.\d{1,2})', caseSensitive: false).firstMatch(text);
    if (match == null) return null;
    final value = double.tryParse(match.group(1)!);
    if (value == null || value < 0 || value > 4.0) return null;
    return value;
  }
}
