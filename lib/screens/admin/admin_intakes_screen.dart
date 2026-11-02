import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/admin_data_service.dart';
import '../../utils/format_utils.dart';

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

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New intake', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. March 2026 Intake')),
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
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(errorText!, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || startDate == null || endDate == null) {
                  setDialogState(() => errorText = 'Fill in a name and both dates.');
                  return;
                }
                if (!endDate!.isAfter(startDate!)) {
                  setDialogState(() => errorText = 'End date must be after the start date.');
                  return;
                }
                try {
                  await AdminDataService.instance.createIntake(name: nameController.text.trim(), startDate: startDate!, endDate: endDate!);
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext, true);
                } catch (e) {
                  setDialogState(() => errorText = 'Could not create: $e');
                }
              },
              child: const Text('Create'),
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
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AdminDataService.instance.deleteIntake(intake['id'] as String);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete: $e'), backgroundColor: AppColors.error));
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
        title: 'Intakes',
        actions: [IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: _createIntake)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: _intakes.isEmpty
                  ? ListView(
                      children: const [
                        EmptyState(
                          icon: Icons.groups_outlined,
                          title: 'No intakes yet',
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

StatusBadge _statusBadge(String status) {
  switch (status) {
    case 'completed':
      return StatusBadge(label: 'Completed', backgroundColor: AppColors.successBg, textColor: AppColors.success);
    case 'ongoing':
      return StatusBadge(label: 'Ongoing', backgroundColor: AppColors.infoBg, textColor: AppColors.info);
    case 'failed':
      return StatusBadge(label: 'Failed', backgroundColor: AppColors.errorBg, textColor: AppColors.error);
    case 'not_started':
      return StatusBadge(label: 'Not started', backgroundColor: AppColors.warningBg, textColor: AppColors.warning);
    default:
      return StatusBadge(label: 'Unassigned', backgroundColor: AppColors.surfaceVariant, textColor: AppColors.textMuted);
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
      if (!mounted) return;
      setState(() {
        _allStudents = students;
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not remove: $e'), backgroundColor: AppColors.error));
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
                    Text('Assign students', style: AppTextStyles.h3),
                    TextButton(onPressed: () => Navigator.pop(sheetContext, selected), child: const Text('Done')),
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
                      subtitle: otherIntake ? const Text('Already in another intake — will be moved here', style: TextStyle(fontSize: 11)) : null,
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final intake = widget.intake;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: intake['name'] as String),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.infoBg,
                                child: Text(logoLetter((s['full_name'] as String?) ?? '?'),
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text((s['full_name'] as String?)?.isNotEmpty == true ? s['full_name'] as String : 'Unnamed student',
                                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
                        label: const Text('Manage students'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
