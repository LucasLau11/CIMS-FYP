import 'package:flutter/material.dart';

import '../services/supervisor_data_service.dart';
import '../theme/app_theme.dart';
import '../utils/error_text.dart';
import '../utils/grade_export.dart';
import '../utils/grading_rubric.dart';
import '../utils/lang.dart';
import '../widgets/common/shared_widgets.dart';

String _n(num? v) {
  if (v == null) return '-';
  final d = v.toDouble();
  return d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toStringAsFixed(1);
}

/// One student's overall grade and where it comes from, for administrators (every student) and
/// academic supervisors (their own students): the company evaluation is worth 60 of the 100 points,
/// the academic supervisor's grades 40 (monthly reports 20 as an average, the final report 20).
class StudentGradeScreen extends StatelessWidget {
  const StudentGradeScreen({super.key, required this.studentId, required this.studentName});

  final String studentId;
  final String studentName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: tr('Evaluation and grade', ms: 'Penilaian dan gred', zh: '评估与成绩'),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.download_outlined, color: Colors.white),
              tooltip: tr('Download grade slip (PDF)', ms: 'Muat turun slip gred (PDF)', zh: '下载成绩单（PDF）'),
              onPressed: () => downloadStudentGradePdf(context, studentId: studentId, studentName: studentName),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              ProfileAvatar(name: studentName, radius: 22),
              const SizedBox(width: 12),
              Expanded(child: Text(studentName, style: AppTextStyles.h3, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 16),
          StudentGradeBody(studentId: studentId),
        ],
      ),
    );
  }
}

/// The grade breakdown itself (no page around it), so it can also sit inside a student's page.
class StudentGradeBody extends StatefulWidget {
  const StudentGradeBody({super.key, required this.studentId});
  final String studentId;

  @override
  State<StudentGradeBody> createState() => _StudentGradeBodyState();
}

class _StudentGradeBodyState extends State<StudentGradeBody> {
  Map<String, dynamic>? _g;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final g = await SupervisorDataService.instance.getStudentGrade(widget.studentId);
      if (!mounted) return;
      setState(() {
        _g = g;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e);
        _loading = false;
      });
    }
  }

  Widget _box({required Widget child}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: child,
      );

  Widget _part({required String title, required String points, required String of, required List<Widget> lines}) => _box(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                Text('$points / $of', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
              ],
            ),
            const SizedBox(height: 8),
            ...lines,
          ],
        ),
      );

  Widget _line(String text, {bool muted = false}) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(text, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: muted ? AppColors.textMuted : AppColors.textSecondary)),
      );

  List<Widget> _reportLines(List items, String emptyText, {required bool isFinal}) {
    if (items.isEmpty) return [_line(emptyText, muted: true)];
    return [
      for (final raw in items)
        Builder(builder: (_) {
          final i = raw as Map<String, dynamic>;
          final graded = i['grade'] != null;
          final status = i['status'] as String? ?? 'submitted';
          final right = graded
              ? '${_n(i['grade'] as num)} / ${rubricMaxTotal(isFinal: isFinal)}'
              : status == 'rejected'
                  ? tr('Rejected', ms: 'Ditolak', zh: '已拒绝')
                  : tr('Not graded yet', ms: 'Belum digred', zh: '尚未评分');
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(i['period'] as String? ?? '', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textPrimary))),
                    Text(right,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: graded ? AppColors.success : AppColors.textMuted)),
                  ],
                ),
                if (graded && i['marks'] is Map) _line(marksSummary(i['marks'] as Map, isFinal: isFinal), muted: true),
              ],
            ),
          );
        }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(padding: const EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (_error != null || _g == null) {
      return Text(_error ?? '', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.error));
    }
    final g = _g!;
    final company = g['company'] as Map<String, dynamic>;
    final monthly = g['monthly'] as Map<String, dynamic>;
    final fin = g['final'] as Map<String, dynamic>;
    final total = (g['total'] as num).toDouble();
    final complete = g['complete'] == true;
    final evaluated = company['evaluated'] == true;
    final scores = (company['scores'] as Map?)?.cast<String, dynamic>() ?? const {};
    final comments = company['comments'] as String?;
    final mAvg = monthly['average'] as num?;
    final mGraded = monthly['graded'] as int? ?? 0;
    final mReports = monthly['reports'] as int? ?? 0;
    final mRequired = (monthly['required'] as num?)?.toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _box(
          child: Column(
            children: [
              Text(tr('Overall grade', ms: 'Gred keseluruhan', zh: '总成绩'), style: AppTextStyles.caption),
              const SizedBox(height: 4),
              Text('${_n(total)} / 100', style: TextStyle(fontFamily: 'Poppins', fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: (total / 100).clamp(0, 1), minHeight: 8, backgroundColor: AppColors.surfaceVariant, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                complete
                    ? tr('All parts have been graded.', ms: 'Semua bahagian telah digred.', zh: '所有部分都已评分。')
                    : tr('Still in progress: the total grows as the parts below are graded.',
                        ms: 'Masih berjalan: jumlah bertambah apabila bahagian di bawah digred.', zh: '进行中：下面各部分评分后，总分会增加。'),
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: complete ? AppColors.success : AppColors.warning),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        _part(
          title: tr('Company evaluation (60%)', ms: 'Penilaian syarikat (60%)', zh: '公司评估（60%）'),
          points: _n(company['points'] as num?),
          of: '60',
          lines: evaluated && company['rubric'] == true
              ? [
                  _line(tr('${_n(company['percent'] as num?)}% of the company\'s 60 marks',
                      ms: '${_n(company['percent'] as num?)}% daripada 60 markah syarikat', zh: '占公司 60 分的 ${_n(company['percent'] as num?)}%')),
                  if (company['evaluator'] != null)
                    _line(
                        tr('By ${company['evaluator']}${company['designation'] != null ? ' (${company['designation']})' : ''}',
                            ms: 'Oleh ${company['evaluator']}${company['designation'] != null ? ' (${company['designation']})' : ''}',
                            zh: '评估人：${company['evaluator']}${company['designation'] != null ? '（${company['designation']}）' : ''}'),
                        muted: true),
                  for (final c in companyEvaluationRubric)
                    if (scores[c.key] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Expanded(child: Text(c.shortName(), style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textPrimary))),
                            Text('${_n(scores[c.key] as num?)} / ${c.maxMark}',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
                          ],
                        ),
                      ),
                  const SizedBox(height: 8),
                  _line(tr('Absent with permission: ${company['attendance_with'] ?? '-'} days · without permission: ${company['attendance_without'] ?? '-'} days',
                      ms: 'Tidak hadir dengan kebenaran: ${company['attendance_with'] ?? '-'} hari · tanpa kebenaran: ${company['attendance_without'] ?? '-'} hari',
                      zh: '请假缺勤：${company['attendance_with'] ?? '-'} 天 · 旷工：${company['attendance_without'] ?? '-'} 天')),
                  if (company['overall_grade'] != null)
                    _line(tr('Overall grade given by the company: ${company['overall_grade']}', ms: 'Gred keseluruhan daripada syarikat: ${company['overall_grade']}', zh: '公司给出的总评等级：${company['overall_grade']}')),
                  if ((company['training_notes'] as String?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    _line(tr('Training: ${company['training_notes']}', ms: 'Latihan: ${company['training_notes']}', zh: '培训：${company['training_notes']}'), muted: true),
                  ],
                  if (comments != null && comments.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('"$comments"', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                  ],
                ]
              : evaluated
              ? [
                  _line(tr('Average score ${_n(company['average'] as num?)} out of 5 (${_n(company['percent'] as num?)}%)',
                      ms: 'Skor purata ${_n(company['average'] as num?)} daripada 5 (${_n(company['percent'] as num?)}%)',
                      zh: '平均分 ${_n(company['average'] as num?)} / 5（${_n(company['percent'] as num?)}%）')),
                  if (company['evaluator'] != null)
                    _line(tr('By ${company['evaluator']}', ms: 'Oleh ${company['evaluator']}', zh: '评估人：${company['evaluator']}'), muted: true),
                  for (final e in scores.entries)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Expanded(child: Text(e.key, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textPrimary))),
                          Text('${_n(e.value as num?)} / 5', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
                        ],
                      ),
                    ),
                  if (comments != null && comments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('"$comments"', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                  ],
                ]
              : [_line(tr('The company supervisor has not evaluated this student yet.', ms: 'Penyelia syarikat belum menilai pelajar ini.', zh: '公司导师尚未评估该学生。'), muted: true)],
        ),
        _part(
          title: tr('Progress reports (10%)', ms: 'Laporan kemajuan (10%)', zh: '进度报告（10%）'),
          points: _n(monthly['points'] as num?),
          of: '10',
          lines: [
            _line(mAvg == null
                ? tr('No progress report has been graded yet.', ms: 'Belum ada laporan kemajuan yang digred.', zh: '尚无已评分的进度报告。')
                : tr('Average ${_n(mAvg)} / 10 over $mGraded graded of $mReports reports',
                    ms: 'Purata ${_n(mAvg)} / 10 daripada $mGraded yang digred dalam $mReports laporan',
                    zh: '平均 ${_n(mAvg)} / 10（$mReports 份报告中已评 $mGraded 份）')),
            if (mRequired != null)
              _line(
                  tr('Required by the intake: $mRequired monthly report${mRequired == 1 ? '' : 's'} ($mGraded graded)',
                      ms: 'Diperlukan oleh intake: $mRequired laporan bulanan ($mGraded digred)',
                      zh: '批次要求：$mRequired 份月度报告（已评 $mGraded 份）'),
                  muted: true),
            ..._reportLines(monthly['items'] as List? ?? const [], tr('No progress reports submitted yet.', ms: 'Belum ada laporan kemajuan.', zh: '尚未提交进度报告。'), isFinal: false),
          ],
        ),
        _part(
          title: tr('Final report (30%)', ms: 'Laporan akhir (30%)', zh: '期末报告（30%）'),
          points: _n(fin['points'] as num?),
          of: '30',
          lines: _reportLines(fin['items'] as List? ?? const [], tr('The final report has not been submitted yet.', ms: 'Laporan akhir belum dihantar.', zh: '尚未提交期末报告。'), isFinal: true),
        ),
      ],
    );
  }
}
