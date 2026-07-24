import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:docx_to_text/docx_to_text.dart';

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

  ParsedResumeData({
    this.fullName,
    this.phone,
    this.address,
    this.dateOfBirth,
    this.programme,
    this.faculty,
    this.semester,
    this.cgpa,
  });

  bool get foundAnything =>
      fullName != null ||
          phone != null ||
          address != null ||
          dateOfBirth != null ||
          programme != null ||
          faculty != null ||
          semester != null ||
          cgpa != null;
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
    );
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
    return match?.group(0)?.trim();
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

    // Fall back to scanning for a line that looks like a Malaysian
    // address even without an explicit label: it has a 5-digit postcode
    // and/or a common street-type keyword.
    final streetKeywords = RegExp(
      r'\b(jalan|jln|lorong|lrg|taman|tmn|persiaran|lot|no\.?\s?\d|blok|unit|apartment|kondominium)\b',
      caseSensitive: false,
    );
    final postcode = RegExp(r'\b\d{5}\b');
    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.length > 150) continue;
      if (streetKeywords.hasMatch(line) && postcode.hasMatch(line)) return line;
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