import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../utils/grading_rubric.dart';
import '../utils/lang.dart';
import '../utils/validators.dart';
import 'common/validated_field.dart';

/// What the academic supervisor gives when approving a report: a mark for every criterion of the
/// university's rubric (see grading_rubric.dart) and a comment for the student (required). The marks of a progress report
/// add up to 10, those of the final report to 30.
class ReportGrade {
  const ReportGrade({required this.marks, required this.total, required this.comment});

  /// criterion key -> mark ("submission", "content", "written", "awareness")
  final Map<String, int> marks;
  final int total;
  final String comment;
}

Future<ReportGrade?> showApproveReportDialog(BuildContext context, {required bool isFinal, DateTime? receivedAt}) {
  return showDialog<ReportGrade>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ApproveReportDialog(isFinal: isFinal, receivedAt: receivedAt),
  );
}

class _ApproveReportDialog extends StatefulWidget {
  const _ApproveReportDialog({required this.isFinal, this.receivedAt});
  final bool isFinal;
  final DateTime? receivedAt;

  @override
  State<_ApproveReportDialog> createState() => _ApproveReportDialogState();
}

class _ApproveReportDialogState extends State<_ApproveReportDialog> {
  final _comment = TextEditingController();
  final _commentKey = GlobalKey<FormFieldState<String>>();
  final Map<String, int> _marks = {};
  bool _tried = false;

  List<RubricCriterion> get _criteria => rubricFor(isFinal: widget.isFinal);
  int get _total => _marks.values.fold(0, (a, b) => a + b);
  int get _max => rubricMaxTotal(isFinal: widget.isFinal);

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _confirm() {
    setState(() => _tried = true);
    // The comment is compulsory: show what is missing under the field as well as under the criteria.
    final commentOk = _commentKey.currentState?.validate() ?? false;
    if (_marks.length != _criteria.length || !commentOk) return;
    Navigator.pop(context, ReportGrade(marks: Map.of(_marks), total: _total, comment: _comment.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final received = widget.receivedAt;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        widget.isFinal
            ? tr('Grade the final report', ms: 'Gred laporan akhir', zh: '为期末报告评分')
            : tr('Grade the progress report', ms: 'Gred laporan kemajuan', zh: '为进度报告评分'),
        style: AppTextStyles.h3,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (received != null)
                Text(
                  tr('Received on ${received.day.toString().padLeft(2, '0')}/${received.month.toString().padLeft(2, '0')}/${received.year}',
                      ms: 'Diterima pada ${received.day.toString().padLeft(2, '0')}/${received.month.toString().padLeft(2, '0')}/${received.year}',
                      zh: '收到日期：${received.day.toString().padLeft(2, '0')}/${received.month.toString().padLeft(2, '0')}/${received.year}'),
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              const SizedBox(height: 4),
              Text(
                widget.isFinal
                    ? tr('The final report is worth 30 marks of the student\'s 100.', ms: 'Laporan akhir bernilai 30 markah daripada 100 markah pelajar.', zh: '期末报告占学生 100 分中的 30 分。')
                    : tr('A progress report is worth 10 marks; the average over all progress reports counts towards the student\'s 100.',
                        ms: 'Satu laporan kemajuan bernilai 10 markah; purata semua laporan kemajuan dikira dalam 100 markah pelajar.',
                        zh: '每份进度报告满分 10 分；所有进度报告的平均分计入学生的 100 分。'),
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 12),
              for (final c in _criteria) ...[
                Text(c.name(), style: AppTextStyles.label),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (var m = 0; m <= c.maxMark; m++)
                      ChoiceChip(
                        label: Text('$m'),
                        selected: _marks[c.key] == m,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _marks[c.key] = m),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (_marks[c.key] != null && c.bandOf(_marks[c.key]!) != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '${c.bandOf(_marks[c.key]!)!.label()}: ${c.bandOf(_marks[c.key]!)!.text()}',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.4, color: AppColors.primaryText),
                    ),
                  )
                else
                  Text(
                    _tried
                        ? tr('Choose a mark from 0 to ${c.maxMark}.', ms: 'Pilih markah dari 0 hingga ${c.maxMark}.', zh: '请选择 0 到 ${c.maxMark} 的分数。')
                        : tr('Out of ${c.maxMark}', ms: 'Daripada ${c.maxMark}', zh: '满分 ${c.maxMark}'),
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: _tried ? AppColors.error : AppColors.textMuted),
                  ),
                const SizedBox(height: 14),
              ],
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Expanded(child: Text(tr('Total', ms: 'Jumlah', zh: '总分'), style: AppTextStyles.label)),
                    Text('$_total / $_max', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ValidatedField(
                key: _commentKey,
                controller: _comment,
                fieldValidator: (v) => Validators.text(v, field: 'The comment', min: 10, max: 500),
                maxLines: 3,
                maxLength: 500,
                showSuccess: false,
                labelText: tr('Comment for the student (required)', ms: 'Komen untuk pelajar (wajib)', zh: '给学生的评语（必填）'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(tt('Cancel'))),
        ElevatedButton(onPressed: _confirm, child: Text(l10n.supApprove)),
      ],
    );
  }
}
