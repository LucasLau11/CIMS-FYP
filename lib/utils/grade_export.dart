import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import '../services/supervisor_data_service.dart';
import '../theme/app_theme.dart';
import 'csv_export.dart';
import 'error_text.dart';
import 'lang.dart';

// ======================================================================================
// Downloading student grades: one student as a PDF grade slip, a whole intake as a spreadsheet (CSV) or as
// one PDF with a grade slip per student. Administrators can download any student, academic supervisors their own.
// ======================================================================================

/// What a grade slip shows about one student: who, and the summary `student_grade_summary` returns.
class GradeSlip {
  const GradeSlip({required this.studentName, required this.grade, this.regNo, this.programme, this.intake});

  final String studentName;
  final String? regNo;
  final String? programme;
  final String? intake;

  /// The JSON of `student_grade_summary`: company, monthly, final, company_points, academic_points, total, complete.
  final Map<String, dynamic> grade;
}

String _num(Object? v) {
  if (v is! num) return '-';
  final d = v.toDouble();
  return d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toStringAsFixed(1);
}

/// The standard PDF fonts hold Latin letters only: anything else (for example Chinese characters in a name) would not
/// print, so it is shown as "?" rather than breaking the file.
String _safe(String? text) {
  final t = (text ?? '').replaceAll(RegExp(r'[\r\t]'), ' ');
  final buffer = StringBuffer();
  for (final rune in t.runes) {
    buffer.write((rune == 10 || (rune >= 32 && rune <= 126) || (rune >= 160 && rune <= 255)) ? String.fromCharCode(rune) : '?');
  }
  return buffer.toString();
}

String _humanize(String key) {
  final words = key.replaceAll('_', ' ').trim();
  return words.isEmpty ? key : words[0].toUpperCase() + words.substring(1);
}

String _status(Object? status) {
  switch (status) {
    case 'approved':
      return 'Graded';
    case 'rejected':
      return 'Rejected';
    default:
      return 'Waiting for grade';
  }
}

class _Cursor {
  _Cursor(this.page, this.width);
  sf.PdfPage page;
  double y = 0;
  final double width;
}

sf.PdfLayoutFormat get _paginate => sf.PdfLayoutFormat(layoutType: sf.PdfLayoutType.paginate);

void _text(_Cursor c, String text, sf.PdfFont font, {double gap = 4, sf.PdfBrush? brush}) {
  final element = sf.PdfTextElement(text: _safe(text), font: font, brush: brush ?? sf.PdfBrushes.black);
  final result = element.draw(page: c.page, bounds: Rect.fromLTWH(0, c.y, c.width, 0), format: _paginate);
  if (result != null) {
    c.page = result.page;
    c.y = result.bounds.bottom + gap;
  }
}

void _table(_Cursor c, List<String> header, List<List<String>> rows, sf.PdfFont font, sf.PdfFont boldFont, {List<double>? widths, int boldLastRows = 0}) {
  final grid = sf.PdfGrid();
  grid.columns.add(count: header.length);
  grid.style = sf.PdfGridStyle(cellPadding: sf.PdfPaddings(left: 5, right: 5, top: 3, bottom: 3), font: font);
  grid.headers.add(1);
  final headerRow = grid.headers[0];
  for (var i = 0; i < header.length; i++) {
    headerRow.cells[i].value = _safe(header[i]);
    headerRow.cells[i].style = sf.PdfGridCellStyle(font: boldFont, backgroundBrush: sf.PdfBrushes.lightGray);
  }
  for (var r = 0; r < rows.length; r++) {
    final row = grid.rows.add();
    for (var i = 0; i < header.length; i++) {
      row.cells[i].value = _safe(i < rows[r].length ? rows[r][i] : '');
      if (r >= rows.length - boldLastRows) row.cells[i].style = sf.PdfGridCellStyle(font: boldFont);
    }
  }
  if (widths != null && widths.length == header.length) {
    final total = widths.fold<double>(0, (a, b) => a + b);
    for (var i = 0; i < widths.length; i++) {
      grid.columns[i].width = c.width * widths[i] / total;
    }
  }
  final result = grid.draw(page: c.page, bounds: Rect.fromLTWH(0, c.y, c.width, 0), format: _paginate);
  if (result != null) {
    c.page = result.page;
    c.y = result.bounds.bottom + 10;
  }
}

/// A PDF with one grade slip per student (a new page for each; a long one runs onto more pages).
Uint8List buildGradeSlipsPdf(List<GradeSlip> slips, {DateTime? generatedAt}) {
  final document = sf.PdfDocument();
  document.pageSettings.margins.all = 40;
  final title = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 18, style: sf.PdfFontStyle.bold);
  final heading = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 12, style: sf.PdfFontStyle.bold);
  final body = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 10);
  final bold = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 10, style: sf.PdfFontStyle.bold);
  final small = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 8);
  final when = generatedAt ?? DateTime.now();
  final stamp = '${when.day.toString().padLeft(2, '0')}/${when.month.toString().padLeft(2, '0')}/${when.year}';

  try {
    for (final slip in slips) {
      final page = document.pages.add();
      final c = _Cursor(page, page.getClientSize().width);
      final g = slip.grade;
      final company = Map<String, dynamic>.from((g['company'] as Map?) ?? const {});
      final monthly = Map<String, dynamic>.from((g['monthly'] as Map?) ?? const {});
      final fin = Map<String, dynamic>.from((g['final'] as Map?) ?? const {});

      _text(c, 'Internship grade slip', title, gap: 6);
      _text(c, slip.studentName, heading, gap: 2);
      final details = [
        if (slip.regNo != null && slip.regNo!.isNotEmpty) 'Reg. no.: ${slip.regNo}',
        if (slip.programme != null && slip.programme!.isNotEmpty) slip.programme!,
        if (slip.intake != null && slip.intake!.isNotEmpty) 'Intake: ${slip.intake}',
      ];
      if (details.isNotEmpty) _text(c, details.join('   |   '), body, gap: 10);

      _table(
        c,
        ['Part', 'Mark', 'Out of'],
        [
          ['Company evaluation (company supervisor)', _num(g['company_points']), '60'],
          ['Progress reports (average of the monthly reports)', _num((monthly['points'])), '10'],
          ['Final report', _num(fin['points']), '30'],
          ['Academic supervisor total', _num(g['academic_points']), '40'],
          ['Total', _num(g['total']), '100'],
        ],
        body,
        bold,
        widths: [6, 1.5, 1.5],
        boldLastRows: 1,
      );
      _text(c, g['complete'] == true ? 'Status: complete (every part has been graded).' : 'Status: not complete yet (a part is still to be graded).', body, gap: 12);

      // company evaluation
      _text(c, 'Company evaluation', heading, gap: 4);
      if (company['evaluated'] == true) {
        final attendance = 'Days absent: ${company['attendance_with'] ?? '-'} with permission, ${company['attendance_without'] ?? '-'} without permission';
        _text(
            c,
            'Evaluated by ${company['evaluator'] ?? '-'}${company['designation'] != null ? ' (${company['designation']})' : ''}.   Overall grade: ${company['overall_grade'] ?? '-'}.   $attendance.',
            body,
            gap: 6);
        final scores = company['scores'];
        if (scores is Map && scores.isNotEmpty) {
          _table(c, ['Criterion', 'Mark (0-6)'], [for (final e in scores.entries) [_humanize(e.key.toString()), _num(e.value)]], body, bold, widths: [6, 2]);
        }
        final comments = (company['comments'] as String?)?.trim();
        if (comments != null && comments.isNotEmpty) _text(c, 'Comments: $comments', body, gap: 4);
        final training = (company['training_notes'] as String?)?.trim();
        if (training != null && training.isNotEmpty) _text(c, 'Training: $training', body, gap: 10);
      } else {
        _text(c, 'The company supervisor has not evaluated this student yet.', body, gap: 10);
      }

      // monthly reports
      final required = monthly['required'];
      _text(c, 'Progress reports${required is num ? ' (${_num(required)} required by the intake, ${_num(monthly['graded'])} graded)' : ''}', heading, gap: 4);
      final monthlyItems = (monthly['items'] as List?) ?? const [];
      if (monthlyItems.isEmpty) {
        _text(c, 'No progress report has been submitted yet.', body, gap: 10);
      } else {
        _table(
          c,
          ['Report', 'Mark', 'Status', 'Comment'],
          [
            for (final i in monthlyItems.whereType<Map>())
              [(i['period'] ?? '-').toString(), i['grade'] == null ? '-' : '${_num(i['grade'])} / 10', _status(i['status']), (i['feedback'] ?? '').toString()],
          ],
          body,
          bold,
          widths: [2.5, 1.2, 2, 5],
        );
      }

      // final report
      _text(c, 'Final report', heading, gap: 4);
      final finalItems = (fin['items'] as List?) ?? const [];
      if (finalItems.isEmpty) {
        _text(c, 'The final report has not been submitted yet.', body, gap: 10);
      } else {
        _table(
          c,
          ['Report', 'Mark', 'Status', 'Comment'],
          [
            for (final i in finalItems.whereType<Map>())
              [(i['period'] ?? '-').toString(), i['grade'] == null ? '-' : '${_num(i['grade'])} / 30', _status(i['status']), (i['feedback'] ?? '').toString()],
          ],
          body,
          bold,
          widths: [2.5, 1.2, 2, 5],
        );
      }

      _text(c, 'Generated on $stamp from CIMS.', small, gap: 0, brush: sf.PdfBrushes.gray);
    }
    return Uint8List.fromList(document.saveSync());
  } finally {
    document.dispose();
  }
}

/// A spreadsheet of an intake's grades, one row per student (the rows of `intake_grade_overview`).
String buildGradesCsv(List<Map<String, dynamic>> rows) {
  String n(Object? v) => v is num ? _num(v) : '';
  return toCsv([
    [
      'Student',
      'Reg. no.',
      'Programme',
      'Internship status',
      'Company evaluation (60)',
      'Progress reports (10)',
      'Final report (30)',
      'Academic total (40)',
      'Total (100)',
      'Company overall grade',
      'Progress reports graded',
      'Progress reports required',
      'Complete',
    ],
    for (final r in rows)
      [
        r['full_name'],
        r['student_reg_no'],
        r['programme'],
        r['internship_status'],
        n(r['company_points']),
        n(r['monthly_points']),
        n(r['final_points']),
        n(r['academic_points']),
        n(r['total']),
        r['overall_grade'],
        r['monthly_graded'],
        r['monthly_required'],
        r['complete'] == true ? 'Yes' : 'No',
      ],
  ]);
}

// ---------------------------------------------------------------------------------------- saving

enum SaveOutcome { saved, cancelled, failed }

/// Lets the person choose where to save the file (the phone's "Save as"); when that is not possible the file is written
/// to a temporary folder and opened, so it can be shared or saved from the app that opens it.
Future<SaveOutcome> saveBytes({required String fileName, required Uint8List bytes, required String extension}) async {
  try {
    final path = await FilePicker.saveFile(
      dialogTitle: tr('Save', ms: 'Simpan', zh: '保存'),
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: [extension],
      bytes: bytes,
    );
    return path == null ? SaveOutcome.cancelled : SaveOutcome.saved;
  } catch (_) {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(bytes, flush: true);
      final result = await OpenFile.open(file.path);
      return result.type == ResultType.done ? SaveOutcome.saved : SaveOutcome.failed;
    } catch (_) {
      return SaveOutcome.failed;
    }
  }
}

String _fileSafe(String text) {
  final cleaned = text.trim().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  return cleaned.isEmpty ? 'student' : cleaned;
}

String _dateStamp() {
  final d = DateTime.now();
  return '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------------------- screens call these

void _toast(BuildContext context, String text, {bool error = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: error ? AppColors.error : AppColors.primary));
}

Future<T?> _withProgress<T>(BuildContext context, Future<T> Function() task) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(canPop: false, child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
  );
  try {
    return await task();
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}

void _report(BuildContext context, SaveOutcome outcome) {
  switch (outcome) {
    case SaveOutcome.saved:
      _toast(context, tr('Saved.', ms: 'Disimpan.', zh: '已保存。'));
      break;
    case SaveOutcome.cancelled:
      break;
    case SaveOutcome.failed:
      _toast(context, tr('Could not save the file.', ms: 'Tidak dapat menyimpan fail.', zh: '无法保存文件。'), error: true);
      break;
  }
}

/// One student's grade slip as a PDF.
Future<void> downloadStudentGradePdf(BuildContext context, {required String studentId, required String studentName, String? regNo, String? programme}) async {
  try {
    final bytes = await _withProgress(context, () async {
      final grade = await SupervisorDataService.instance.getStudentGrade(studentId);
      return buildGradeSlipsPdf([GradeSlip(studentName: studentName, regNo: regNo, programme: programme, grade: grade)]);
    });
    if (bytes == null || !context.mounted) return;
    _report(context, await saveBytes(fileName: 'grade_${_fileSafe(studentName)}_${_dateStamp()}.pdf', bytes: bytes, extension: 'pdf'));
  } catch (e) {
    if (!context.mounted) return;
    _toast(context, '${tr('Could not prepare the grade slip', ms: 'Tidak dapat menyediakan slip gred', zh: '无法生成成绩单')}: ${friendlyError(e)}', error: true);
  }
}

/// All students of an intake (or only the ones in [studentIds]): a spreadsheet, or one PDF with a grade slip each.
Future<void> downloadIntakeGrades(BuildContext context, {required String intakeId, required String intakeName, required bool pdf, Set<String>? studentIds}) async {
  try {
    final result = await _withProgress<({Uint8List bytes, int count})?>(context, () async {
      var rows = await SupervisorDataService.instance.getIntakeGrades(intakeId);
      if (studentIds != null) rows = rows.where((r) => studentIds.contains(r['student_id'])).toList();
      if (rows.isEmpty) return null;
      if (!pdf) return (bytes: Uint8List.fromList(utf8.encode(buildGradesCsv(rows))), count: rows.length);
      final slips = <GradeSlip>[];
      for (final r in rows) {
        final grade = await SupervisorDataService.instance.getStudentGrade(r['student_id'] as String);
        slips.add(GradeSlip(
          studentName: (r['full_name'] as String?)?.isNotEmpty == true ? r['full_name'] as String : 'Unnamed student',
          regNo: r['student_reg_no'] as String?,
          programme: r['programme'] as String?,
          intake: intakeName,
          grade: grade,
        ));
      }
      return (bytes: buildGradeSlipsPdf(slips), count: rows.length);
    });
    if (!context.mounted) return;
    if (result == null) {
      _toast(context, tr('There are no students to download.', ms: 'Tiada pelajar untuk dimuat turun.', zh: '没有可下载的学生。'), error: true);
      return;
    }
    final name = 'grades_${_fileSafe(intakeName)}_${_dateStamp()}.${pdf ? 'pdf' : 'csv'}';
    _report(context, await saveBytes(fileName: name, bytes: result.bytes, extension: pdf ? 'pdf' : 'csv'));
  } catch (e) {
    if (!context.mounted) return;
    _toast(context, '${tr('Could not prepare the download', ms: 'Tidak dapat menyediakan muat turun', zh: '无法准备下载')}: ${friendlyError(e)}', error: true);
  }
}

