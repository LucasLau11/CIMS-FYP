import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../services/company_supervisor_data_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/error_text.dart';
import '../../utils/format_utils.dart';
import '../../utils/grading_rubric.dart';
import '../../utils/lang.dart';
import '../../utils/validators.dart';
import '../../widgets/common/validated_field.dart';

/// The company supervisor's evaluation of an intern, on the university's company assessment form:
/// 10 criteria marked 0-6 (60 marks, the company's share of the overall grade), the intern's attendance,
/// an overall grade (A, B+, B, C or F), other comments and a few words about the training. It can be
/// submitted once.
class CompanySupervisorEvaluateScreen extends StatefulWidget {
  final Map<String, dynamic> intern;

  const CompanySupervisorEvaluateScreen({super.key, required this.intern});

  @override
  State<CompanySupervisorEvaluateScreen> createState() => _CompanySupervisorEvaluateScreenState();
}

class _CompanySupervisorEvaluateScreenState extends State<CompanySupervisorEvaluateScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, int> _marks = {};
  final _absentWith = TextEditingController(text: '0');
  final _absentWithout = TextEditingController(text: '0');
  final _comments = TextEditingController();
  final _training = TextEditingController();
  final _designation = TextEditingController();
  String? _overallGrade;
  bool _tried = false;
  bool _submitted = false;
  bool _isSubmitting = false;

  List<RubricCriterion> get _criteria => companyEvaluationRubric;
  int get _total => _marks.values.fold(0, (a, b) => a + b);

  @override
  void dispose() {
    _absentWith.dispose();
    _absentWithout.dispose();
    _comments.dispose();
    _training.dispose();
    _designation.dispose();
    super.dispose();
  }

  String? _daysError(String v) {
    final n = int.tryParse(v.trim());
    if (n == null || n < 0 || n > 400) {
      return tr('Enter a whole number of days (0 or more).', ms: 'Masukkan bilangan hari yang bulat (0 atau lebih).', zh: '请输入天数（0 或以上的整数）。');
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() => _tried = true);
    final fieldsOk = _formKey.currentState?.validate() ?? false;
    if (!fieldsOk || _marks.length != _criteria.length || _overallGrade == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('Please mark every criterion, choose the overall grade and fill in the highlighted fields.',
            ms: 'Sila beri markah untuk setiap kriteria, pilih gred keseluruhan dan isi medan yang diserlahkan.',
            zh: '请为每项标准打分、选择总评等级并填写标出的字段。')),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await CompanySupervisorDataService.instance.submitEvaluation(
        studentId: widget.intern['id'] as String,
        marks: Map.of(_marks),
        absentWithPermission: int.parse(_absentWith.text.trim()),
        absentWithoutPermission: int.parse(_absentWithout.text.trim()),
        overallGrade: _overallGrade!,
        comments: _comments.text.trim(),
        trainingNotes: _training.text.trim(),
        designation: _designation.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitted = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tt('Could not submit evaluation')}: ${friendlyError(e)}'), backgroundColor: AppColors.error));
    }
  }

  Widget _card({required Widget child}) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccessScreen();
    final l10n = AppLocalizations.of(context)!;
    final name = widget.intern['full_name'] as String;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(l10n.csEvaluateIntern, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.infoBg,
                  child: Text(logoLetter(name), style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      Text((widget.intern['programme'] as String?) ?? (widget.intern['role_title'] as String?) ?? '', style: AppTextStyles.bodySecondary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.primaryText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr('Mark each criterion from 0 to 6. The 10 marks add up to 60, the company\'s share of the student\'s grade. An evaluation cannot be changed once submitted.',
                          ms: 'Beri markah 0 hingga 6 untuk setiap kriteria. 10 markah itu berjumlah 60, bahagian syarikat dalam gred pelajar. Penilaian tidak boleh diubah selepas dihantar.',
                          zh: '每项标准打 0 到 6 分，10 项合计 60 分，即公司占学生成绩的部分。评估提交后不能修改。'),
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.primaryText),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final c in _criteria)
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name(), style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 8),
                    if (_marks[c.key] != null && c.bandOf(_marks[c.key]!) != null)
                      Text('${c.bandOf(_marks[c.key]!)!.label()}: ${c.bandOf(_marks[c.key]!)!.text()}',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.4, color: AppColors.primaryText))
                    else
                      Text(
                        _tried ? tr('Choose a mark from 0 to 6.', ms: 'Pilih markah dari 0 hingga 6.', zh: '请选择 0 到 6 的分数。') : tr('Out of 6', ms: 'Daripada 6', zh: '满分 6'),
                        style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: _tried ? AppColors.error : AppColors.textMuted),
                      ),
                  ],
                ),
              ),
            _card(
              child: Row(
                children: [
                  Expanded(child: Text(tr('Total', ms: 'Jumlah', zh: '总分'), style: AppTextStyles.label)),
                  Text('$_total / $companyEvaluationMaxTotal', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(tr('11. Student\'s attendance', ms: '11. Kehadiran pelajar', zh: '11. 学生出勤'), style: AppTextStyles.h3),
            const SizedBox(height: 8),
            ValidatedField(
              controller: _absentWith,
              fieldValidator: _daysError,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              showSuccess: false,
              labelText: tr('Number of days absent with permission', ms: 'Bilangan hari tidak hadir dengan kebenaran', zh: '请假缺勤天数（有批准）'),
            ),
            const SizedBox(height: 12),
            ValidatedField(
              controller: _absentWithout,
              fieldValidator: _daysError,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              showSuccess: false,
              labelText: tr('Number of days absent without permission', ms: 'Bilangan hari tidak hadir tanpa kebenaran', zh: '旷工天数（无批准）'),
            ),
            const SizedBox(height: 20),
            Text(tr('12. Overall grade for this student trainee', ms: '12. Gred keseluruhan untuk pelajar latihan ini', zh: '12. 对该实习生的总评等级'), style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final g in kOverallGrades)
                  ChoiceChip(
                    label: Text('${g.$1} · ${overallGradeRating(g.$2)}'),
                    selected: _overallGrade == g.$1,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _overallGrade = g.$1),
                  ),
              ],
            ),
            if (_tried && _overallGrade == null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(tr('Choose the overall grade.', ms: 'Pilih gred keseluruhan.', zh: '请选择总评等级。'),
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
              ),
            const SizedBox(height: 20),
            Text(tr('13. Other comments about this student trainee', ms: '13. Komen lain tentang pelajar latihan ini', zh: '13. 关于该实习生的其他意见'), style: AppTextStyles.h3),
            const SizedBox(height: 8),
            ValidatedField(
              controller: _comments,
              fieldValidator: (v) => Validators.text(v, field: 'The comment', min: 10, max: 1000),
              maxLines: 4,
              maxLength: 1000,
              showSuccess: false,
              hintText: tr('Required', ms: 'Wajib', zh: '必填'),
            ),
            const SizedBox(height: 14),
            Text(
              tr('14. The type of training the student underwent (nature of work, department attached to, duration of attachment)',
                  ms: '14. Jenis latihan yang dilalui pelajar (sifat kerja, jabatan, tempoh latihan)',
                  zh: '14. 学生接受的培训类型（工作性质、所属部门、实习时长等）'),
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 8),
            ValidatedField(
              controller: _training,
              fieldValidator: (v) => Validators.text(v, field: 'Description', min: 10, max: 1000),
              maxLines: 4,
              maxLength: 1000,
              showSuccess: false,
            ),
            const SizedBox(height: 14),
            ValidatedField(
              controller: _designation,
              fieldValidator: (v) => Validators.text(v, field: 'Designation', min: 2, max: 100),
              textCapitalization: TextCapitalization.words,
              showSuccess: false,
              labelText: tr('Your designation', ms: 'Jawatan anda', zh: '您的职位'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(l10n.csSubmitEvaluation),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    final l10n = AppLocalizations.of(context)!;
    // However this screen is left (the button, or the phone's back gesture), it tells the page behind it that the
    // evaluation was submitted, so that page closes the evaluation at once.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, true);
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
                child: Icon(Icons.check_circle_outline, color: AppColors.success, size: 44),
              ),
              const SizedBox(height: 24),
              Text(l10n.csEvaluationSubmitted, style: AppTextStyles.h2, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                l10n.csEvaluationRecorded(widget.intern['full_name'] as String),
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.csBackToIntern),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
