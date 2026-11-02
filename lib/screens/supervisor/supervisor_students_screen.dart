import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/student_data_service.dart';
import '../../services/supervisor_data_service.dart';
import '../../utils/format_utils.dart';
import '../document_preview_screen.dart';
import '../student/student_messages_screen.dart' show ChatScreen;
import 'supervisor_evaluate_screen.dart';

class SupervisorStudentsScreen extends StatefulWidget {
  const SupervisorStudentsScreen({super.key});

  @override
  State<SupervisorStudentsScreen> createState() => _SupervisorStudentsScreenState();
}

class _SupervisorStudentsScreenState extends State<SupervisorStudentsScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final students = await SupervisorDataService.instance.getStudents();
      if (!mounted) return;
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchController.text.isEmpty) return _students;
    final q = _searchController.text.toLowerCase();
    return _students.where((s) {
      final name = (s['full_name'] as String? ?? '').toLowerCase();
      final programme = (s['programme'] as String? ?? '').toLowerCase();
      return name.contains(q) || programme.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final results = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: l10n.supMyStudentsTitle),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: l10n.supSearchByNameOrProgramme,
                        prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [Text(l10n.supStudentsCount(results.length), style: AppTextStyles.caption)],
                    ),
                  ),
                  Expanded(
                    child: results.isEmpty
                        ? EmptyState(icon: Icons.school_outlined, title: l10n.supNoStudents, description: l10n.supNoStudentsMatch)
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 6, bottom: 24),
                            itemCount: results.length,
                            itemBuilder: (_, i) => _StudentProgressCard(
                              data: results[i],
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => StudentDetailScreen(studentId: results[i]['id'] as String)),
                                );
                                _load();
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StudentProgressCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _StudentProgressCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = (data['full_name'] as String?)?.isNotEmpty == true ? data['full_name'] as String : 'Unnamed student';
    final pendingCount = data['pending_review_count'] as int;
    final hasActive = data['has_active_internship'] as bool;
    final companyName = data['company_name'] as String?;
    final lastReportAt = data['last_report_at'] as String?;
    final accentColor = pendingCount > 0 ? AppColors.warning : AppColors.success;

    return AccentCard(
      accentColor: accentColor,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.infoBg,
                child: Text(logoLetter(name), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text(
                      hasActive ? '${data['programme'] ?? l10n.notSpecified} · $companyName' : (data['programme'] as String?) ?? l10n.notSpecified,
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(pendingCount > 0 ? l10n.supPendingCount(pendingCount) : l10n.supUpToDate,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: accentColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(hasActive ? Icons.work_outline : Icons.work_off_outlined, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Flexible(
                child: Text(hasActive ? l10n.supActiveInternship : l10n.supNoActiveInternship, style: AppTextStyles.caption),
              ),
              const SizedBox(width: 14),
              Icon(Icons.description_outlined, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  lastReportAt != null ? l10n.supLastReportAgo(timeAgo(context, DateTime.parse(lastReportAt))) : l10n.supNoReportsYet,
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StudentDetailScreen extends StatefulWidget {
  final String studentId;

  const StudentDetailScreen({super.key, required this.studentId});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _student;
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _documents = [];
  List<Map<String, dynamic>> _evaluations = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final students = await SupervisorDataService.instance.getStudents();
      final student = students.firstWhere((s) => s['id'] == widget.studentId, orElse: () => {});
      final reports = await SupervisorDataService.instance.getStudentReports(widget.studentId);
      final documents = await SupervisorDataService.instance.getStudentDocuments(widget.studentId);
      final evaluations = await SupervisorDataService.instance.getStudentEvaluations(widget.studentId);
      if (!mounted) return;
      setState(() {
        _student = student;
        _reports = reports;
        _documents = documents;
        _evaluations = evaluations;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openSubmission(String? storagePath) async {
    if (storagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.supNoFileAttached), backgroundColor: AppColors.warning));
      return;
    }
    try {
      final url = await SupervisorDataService.instance.getReviewFileSignedUrl(storagePath);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => DocumentPreviewScreen(url: url, fileName: storagePath.split('/').last),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open file: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _message() async {
    try {
      final conversation = await StudentDataService.instance.getOrCreateConversation(widget.studentId);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(conversationId: conversation['id'] as String, otherProfile: {..._student!, 'role': 'student'}),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open chat: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    final l10n = AppLocalizations.of(context)!;
    final student = _student ?? {};
    final name = (student['full_name'] as String?)?.isNotEmpty == true ? student['full_name'] as String : 'Unnamed student';
    final hasActive = student['has_active_internship'] == true;
    final companyName = student['company_name'] as String?;
    final canEvaluate = student['can_evaluate'] == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(l10n.supStudentDetails, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.infoBg,
                    child: Text(logoLetter(name), style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                  const SizedBox(height: 10),
                  Text(name, style: AppTextStyles.h2),
                  Text(
                    hasActive ? '${student['programme'] ?? l10n.notSpecified} · $companyName' : (student['programme'] as String?) ?? l10n.notSpecified,
                    style: AppTextStyles.bodySecondary,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canEvaluate
                        ? () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => SupervisorEvaluateScreen(student: student)));
                            _load();
                          }
                        : null,
                    icon: const Icon(Icons.assessment_outlined, size: 16),
                    label: Text(l10n.supEvaluate),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _message,
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: Text(l10n.supMessage),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                  ),
                ),
              ],
            ),
            // Evaluations are gated on the student's derived internship
            // status (see migration 00022) — 'completed' means their
            // assigned intake's end date has passed while they still have
            // an active internship. RLS enforces this too; this note just
            // explains the disabled button instead of letting a tap fail.
            if (!canEvaluate) ...[
              const SizedBox(height: 8),
              Text(l10n.supEvaluateLockedNote, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
            ],
            if (_evaluations.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(l10n.supLatestEvaluation, style: AppTextStyles.h3),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0D6E78), Color(0xFF14B8C8)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(l10n.supSubmittedAgo(timeAgo(context, DateTime.parse(_evaluations.first['created_at'] as String))),
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                    Text(parseNum(_evaluations.first['average_score'])?.toStringAsFixed(1) ?? '-',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(l10n.supSubmissionHistory, style: AppTextStyles.h3),
            const SizedBox(height: 10),
            if (_reports.isEmpty && _documents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.supNoSubmissionsYet, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
              ),
            ..._reports.map((r) => _SubmissionTile(
                  icon: Icons.assignment_outlined,
                  title: '${r['type'] == 'final' ? 'Final Report' : 'Monthly Report'} — ${r['period_label']}',
                  status: r['status'] as String,
                  onTap: () => _openSubmission(r['storage_path'] as String?),
                )),
            ..._documents.map((d) => _SubmissionTile(
                  icon: Icons.description_outlined,
                  title: (d['title'] as String?) ?? (d['category'] as String),
                  status: d['status'] as String,
                  onTap: () => _openSubmission(d['storage_path'] as String?),
                )),
          ],
        ),
      ),
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;
  final VoidCallback onTap;

  const _SubmissionTile({required this.icon, required this.title, required this.status, required this.onTap});

  Color get _color {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  StatusBadge _badge(BuildContext context) {
    switch (status) {
      case 'approved':
        return StatusBadge.approved(context);
      case 'rejected':
        return StatusBadge.rejected(context);
      default:
        return StatusBadge.pending(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccentCard(
      accentColor: _color,
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600))),
          _badge(context),
        ],
      ),
    );
  }
}
