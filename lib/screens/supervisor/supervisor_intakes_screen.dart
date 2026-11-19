import 'package:flutter/material.dart';

import '../../services/supervisor_data_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/error_text.dart';
import '../../utils/grade_export.dart';
import '../../utils/lang.dart';
import '../../widgets/common/shared_widgets.dart';
import '../student_grade_screen.dart';

String _date(Object? iso) {
  final d = DateTime.tryParse('$iso');
  return d == null ? '' : '${d.day}/${d.month}/${d.year}';
}

String _score(Object? v) {
  final d = double.tryParse('$v') ?? 0;
  return d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toStringAsFixed(1);
}

/// The academic supervisor's intakes: only the ones in which they have students. Opening an intake
/// lists THEIR students in it with each one's overall grade; opening a student shows the evaluation
/// and grade in detail.
class SupervisorIntakesScreen extends StatefulWidget {
  const SupervisorIntakesScreen({super.key});

  @override
  State<SupervisorIntakesScreen> createState() => _SupervisorIntakesScreenState();
}

class _SupervisorIntakesScreenState extends State<SupervisorIntakesScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _intakes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final intakes = await SupervisorDataService.instance.getSupervisorIntakes();
      if (!mounted) return;
      setState(() {
        _intakes = intakes;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: tt('Intakes')),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: TextStyle(color: AppColors.error))))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _intakes.isEmpty
                      ? ListView(children: [
                          EmptyState(
                            icon: Icons.groups_outlined,
                            title: tr('No intakes yet', ms: 'Belum ada pengambilan', zh: '暂无实习批次'),
                            description: tr('Intakes appear here once the administrator places your students in one.',
                                ms: 'Pengambilan akan muncul di sini apabila pentadbir meletakkan pelajar anda di dalamnya.',
                                zh: '管理员把您的学生分到某个批次后，批次会显示在这里。'),
                          ),
                        ])
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _intakes.length,
                          itemBuilder: (_, i) {
                            final intake = _intakes[i];
                            return AccentCard(
                              accentColor: AppColors.primary,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _SupervisorIntakeStudents(intake: intake))),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(intake['name'] as String,
                                            style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                        const SizedBox(height: 4),
                                        Text('${_date(intake['start_date'])} – ${_date(intake['end_date'])}', style: AppTextStyles.caption),
                                        const SizedBox(height: 4),
                                        Text(tr('${intake['student_count']} of your students', ms: '${intake['student_count']} pelajar anda', zh: '您的 ${intake['student_count']} 名学生'),
                                            style: AppTextStyles.caption),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: AppColors.textMuted),
                                ],
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}

class _SupervisorIntakeStudents extends StatefulWidget {
  const _SupervisorIntakeStudents({required this.intake});
  final Map<String, dynamic> intake;

  @override
  State<_SupervisorIntakeStudents> createState() => _SupervisorIntakeStudentsState();
}

class _SupervisorIntakeStudentsState extends State<_SupervisorIntakeStudents> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final students = await SupervisorDataService.instance.getIntakeGrades(widget.intake['id'] as String);
      if (!mounted) return;
      setState(() {
        _students = students;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: widget.intake['name'] as String,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            tooltip: tr('Download grades', ms: 'Muat turun gred', zh: '下载成绩'),
            onSelected: (value) => downloadIntakeGrades(context, intakeId: widget.intake['id'] as String, intakeName: widget.intake['name'] as String, pdf: value == 'pdf'),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'csv', child: Text(tr('Spreadsheet (CSV) of all students', ms: 'Hamparan (CSV) semua pelajar', zh: '全部学生电子表格（CSV）'))),
              PopupMenuItem(value: 'pdf', child: Text(tr('Grade slips of all students (PDF)', ms: 'Slip gred semua pelajar (PDF)', zh: '全部学生成绩单（PDF）'))),
            ],
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: TextStyle(color: AppColors.error))))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('${_date(widget.intake['start_date'])} – ${_date(widget.intake['end_date'])}', style: AppTextStyles.bodySecondary),
                      ),
                      for (final s in _students)
                        AccentCard(
                          accentColor: s['complete'] == true ? AppColors.success : AppColors.warning,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentGradeScreen(
                                studentId: s['student_id'] as String,
                                studentName: (s['full_name'] as String?)?.isNotEmpty == true ? s['full_name'] as String : 'Unnamed student',
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              ProfileAvatar(name: (s['full_name'] as String?) ?? '?', radius: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text((s['full_name'] as String?)?.isNotEmpty == true ? s['full_name'] as String : 'Unnamed student',
                                        style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    Text((s['programme'] as String?) ?? '', style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              Text('${_score(s['total'])} / 100',
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
                              Icon(Icons.chevron_right, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
