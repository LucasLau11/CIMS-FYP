import 'package:flutter/material.dart';
import '../../utils/validators.dart';
import '../../widgets/common/validated_field.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/admin_data_service.dart';
import '../../utils/format_utils.dart';
import '../../utils/error_text.dart';
import '../../utils/grade_export.dart';
import '../../utils/lang.dart';
import '../../services/supervisor_data_service.dart';
import '../student_grade_screen.dart';

/// Admin defines intake cohorts (a start/end window) and assigns students
/// to one — the window student_internship_status() (see migration
/// 00022_intakes_and_evaluation_gating.sql) uses to derive whether a
/// student's internship is ongoing/completed/failed/not_started, which in
/// turn gates when supervisors can submit an evaluation.
class AdminIntakesScreen extends StatefulWidget {
  const AdminIntakesScreen({super.key});

  @override
  State<AdminIntakesScreen> createState() => _AdminIntakesScreenState();
}

String _formatDate(String isoDate) {
  final d = DateTime.parse(isoDate);
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

class _AdminIntakesScreenState extends State<AdminIntakesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _intakes = [];
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final intakes = await AdminDataService.instance.getIntakes();
      final students = await AdminDataService.instance.getStudentsWithIntakeStatus();
      if (!mounted) return;
      setState(() {
        _intakes = intakes;
        _students = students;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  int _studentCount(String intakeId) => _students.where((s) => s['intake_id'] == intakeId).length;

  Future<void> _createIntake() async {
    final nameController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    String? errorText;
    bool attempted = false;
    final formKey = GlobalKey<FormState>();

    // Live rules for the dates, shown under the date rows.
    String? startError() => startDate == null ? 'Choose a start date.' : null;
    String? endError() {
      if (endDate == null) return 'Choose an end date.';
      final order = Validators.endAfterStart(startDate, endDate);
      if (order != null) return order;
      if (startDate != null) {
        final days = endDate!.difference(startDate!).inDays;
        if (days < 30) return 'An intake must last at least 30 days (this one is $days).';
        if (days > 400) return 'An intake can last at most 400 days (this one is $days).';
      }
      return null;
    }

    Widget fieldError(String? message) => message == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(message, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
          );

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New intake', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Form(
            key: formKey,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValidatedField(
                controller: nameController,
                fieldValidator: (v) {
                  final rule = Validators.text(v, field: 'Intake name', min: 3, max: 60);
                  if (rule != null) return rule;
                  final taken = _intakes.any((i) => (i['name'] as String).trim().toLowerCase() == v.trim().toLowerCase());
                  return taken ? 'An intake with this name already exists.' : null;
                },
                textCapitalization: TextCapitalization.words,
                maxLength: 60,
                labelText: tt('Name'),
                hintText: 'e.g. March 2026 Intake',
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(startDate == null ? 'Start date' : _formatDate(startDate!.toIso8601String())),
                trailing: const Icon(Icons.calendar_today_outlined, size: 18),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (picked != null) setDialogState(() => startDate = picked);
                },
              ),
              if (attempted || startDate != null) fieldError(startError()),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(endDate == null ? 'End date' : _formatDate(endDate!.toIso8601String())),
                trailing: const Icon(Icons.calendar_today_outlined, size: 18),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? (startDate ?? DateTime.now()).add(const Duration(days: 90)),
                    firstDate: startDate ?? DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 1095)),
                  );
                  if (picked != null) setDialogState(() => endDate = picked);
                },
              ),
              if (attempted || endDate != null) fieldError(endError()),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(errorText!, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
              ],
            ],
          ),
          ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(tt('Cancel'))),
            ElevatedButton(
              onPressed: () async {
                setDialogState(() => attempted = true);
                final nameOk = formKey.currentState?.validate() ?? false;
                if (!nameOk || startError() != null || endError() != null) return;
                try {
                  await AdminDataService.instance.createIntake(name: nameController.text.trim(), startDate: startDate!, endDate: endDate!);
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext, true);
                } catch (e) {
                  setDialogState(() => errorText = 'Could not create: ${friendlyError(e)}');
                }
              },
              child: Text(tt('Create')),
            ),
          ],
        ),
      ),
    );

    if (created == true) _load();
  }

  Future<void> _deleteIntake(Map<String, dynamic> intake) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete intake?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text('"${intake['name']}" will be removed. Students assigned to it become unassigned, not deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(tt('Cancel'))),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(tt('Delete'), style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AdminDataService.instance.deleteIntake(intake['id'] as String);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tt('Could not delete')}: ${friendlyError(e)}'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _openIntake(Map<String, dynamic> intake) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => _IntakeStudentsScreen(intake: intake)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: tt('Intakes'),
        actions: [IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: _createIntake)],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: _intakes.isEmpty
                  ? ListView(
                      children: [
                        EmptyState(
                          icon: Icons.groups_outlined,
                          title: tt('No intakes yet'),
                          description: 'Create an intake to define a cohort\'s internship start and end dates.',
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _intakes.length,
                      itemBuilder: (_, i) {
                        final intake = _intakes[i];
                        return AccentCard(
                          accentColor: AppColors.primary,
                          onTap: () => _openIntake(intake),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(intake['name'] as String,
                                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                    const SizedBox(height: 4),
                                    Text('${_formatDate(intake['start_date'] as String)} – ${_formatDate(intake['end_date'] as String)}',
                                        style: AppTextStyles.caption),
                                    const SizedBox(height: 4),
                                    Text(
                                        () {
                                          final m = intakeMonths(DateTime.parse(intake['start_date'] as String), DateTime.parse(intake['end_date'] as String));
                                          return '$m month${m == 1 ? '' : 's'} · $m monthly report${m == 1 ? '' : 's'} required';
                                        }(),
                                        style: AppTextStyles.caption),
                                    const SizedBox(height: 4),
                                    Text('${_studentCount(intake['id'] as String)} student(s)', style: AppTextStyles.caption),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, size: 20, color: AppColors.textMuted),
                                onPressed: () => _deleteIntake(intake),
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

String _gradeText(Object? v) {
  final d = double.tryParse('$v') ?? 0;
  return d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toStringAsFixed(1);
}

StatusBadge _statusBadge(String status) {
  switch (status) {
    case 'completed':
      return StatusBadge(label: tt('Completed'), backgroundColor: AppColors.successBg, textColor: AppColors.success);
    case 'ongoing':
      return StatusBadge(label: tt('Ongoing'), backgroundColor: AppColors.infoBg, textColor: AppColors.info);
    case 'failed':
      return StatusBadge(label: tt('Failed'), backgroundColor: AppColors.errorBg, textColor: AppColors.error);
    case 'not_started':
      return StatusBadge(label: tt('Not started'), backgroundColor: AppColors.warningBg, textColor: AppColors.warning);
    default:
      return StatusBadge(label: tt('Unassigned'), backgroundColor: AppColors.surfaceVariant, textColor: AppColors.textMuted);
  }
}

class _IntakeStudentsScreen extends StatefulWidget {
  final Map<String, dynamic> intake;
  const _IntakeStudentsScreen({required this.intake});

  @override
  State<_IntakeStudentsScreen> createState() => _IntakeStudentsScreenState();
}

class _IntakeStudentsScreenState extends State<_IntakeStudentsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allStudents = [];
  // student id -> overall grade (out of 100) and whether every part has been graded
  Map<String, Map<String, dynamic>> _grades = {};

  String get _intakeId => widget.intake['id'] as String;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final students = await AdminDataService.instance.getStudentsWithIntakeStatus();
      Map<String, Map<String, dynamic>> grades = {};
      try {
        final rows = await SupervisorDataService.instance.getIntakeGrades(_intakeId);
        grades = {for (final r in rows) r['student_id'] as String: r};
      } catch (_) {
        // the grades are an extra: the list still works without them
      }
      if (!mounted) return;
      setState(() {
        _allStudents = students;
        _grades = grades;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _assigned => _allStudents.where((s) => s['intake_id'] == _intakeId).toList();

  Future<void> _removeStudent(Map<String, dynamic> student) async {
    try {
      await AdminDataService.instance.assignStudentsToIntake(studentIds: [student['id'] as String], intakeId: null);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tt('Could not remove')}: ${friendlyError(e)}'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _manageStudents() async {
    final selected = _assigned.map((s) => s['id'] as String).toSet();
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        expand: false,
        builder: (sheetContext, scrollController) => StatefulBuilder(
          builder: (context, setSheetState) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text(tt('Assign students'), style: AppTextStyles.h3, overflow: TextOverflow.ellipsis)),
                    TextButton(onPressed: () => Navigator.pop(sheetContext, selected), child: Text(tt('Done'))),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _allStudents.length,
                  itemBuilder: (_, i) {
                    final student = _allStudents[i];
                    final id = student['id'] as String;
                    final otherIntake = student['intake_id'] != null && student['intake_id'] != _intakeId;
                    return CheckboxListTile(
                      value: selected.contains(id),
                      title: Text((student['full_name'] as String?)?.isNotEmpty == true ? student['full_name'] as String : 'Unnamed student'),
                      subtitle: otherIntake ? Text(tt('Already in another intake — will be moved here'), style: TextStyle(fontSize: 11)) : null,
                      onChanged: (checked) => setSheetState(() {
                        if (checked == true) {
                          selected.add(id);
                        } else {
                          selected.remove(id);
                        }
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == null) return;
    final previouslyAssigned = _assigned.map((s) => s['id'] as String).toSet();
    final toAdd = result.difference(previouslyAssigned).toList();
    final toRemove = previouslyAssigned.difference(result).toList();
    try {
      if (toAdd.isNotEmpty) await AdminDataService.instance.assignStudentsToIntake(studentIds: toAdd, intakeId: _intakeId);
      if (toRemove.isNotEmpty) await AdminDataService.instance.assignStudentsToIntake(studentIds: toRemove, intakeId: null);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tt('Could not save')}: ${friendlyError(e)}'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final intake = widget.intake;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: intake['name'] as String,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            tooltip: tr('Download grades', ms: 'Muat turun gred', zh: '下载成绩'),
            onSelected: (value) => downloadIntakeGrades(context, intakeId: _intakeId, intakeName: intake['name'] as String, pdf: value == 'pdf'),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'csv', child: Text(tr('Spreadsheet (CSV) of all students', ms: 'Hamparan (CSV) semua pelajar', zh: '全部学生电子表格（CSV）'))),
              PopupMenuItem(value: 'pdf', child: Text(tr('Grade slips of all students (PDF)', ms: 'Slip gred semua pelajar (PDF)', zh: '全部学生成绩单（PDF）'))),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${_formatDate(intake['start_date'] as String)} – ${_formatDate(intake['end_date'] as String)}',
                      style: AppTextStyles.bodySecondary,
                    ),
                  ),
                  SectionHeader(title: 'Assigned students (${_assigned.length})'),
                  if (_assigned.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('No students assigned yet.', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
                    )
                  else
                    ..._assigned.map((s) => AccentCard(
                          accentColor: AppColors.primaryLight,
                          // tapping a student opens their evaluation and grade
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentGradeScreen(
                                studentId: s['id'] as String,
                                studentName: (s['full_name'] as String?)?.isNotEmpty == true ? s['full_name'] as String : 'Unnamed student',
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.infoBg,
                                child: Text(logoLetter((s['full_name'] as String?) ?? '?'),
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text((s['full_name'] as String?)?.isNotEmpty == true ? s['full_name'] as String : 'Unnamed student',
                                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              ),
                              if (_grades[s['id']] != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text('${_gradeText(_grades[s['id']]!['total'])} / 100',
                                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
                                ),
                              _statusBadge(s['status'] as String),
                              IconButton(
                                icon: Icon(Icons.close, size: 18, color: AppColors.textMuted),
                                onPressed: () => _removeStudent(s),
                              ),
                            ],
                          ),
                        )),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _manageStudents,
                        icon: const Icon(Icons.people_outline, size: 18),
                        label: Text(tt('Manage students')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
