import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/supervisor_data_service.dart';
import '../../utils/format_utils.dart';
import '../document_preview_screen.dart';
import '../supervisor/supervisor_students_screen.dart' show StudentDetailScreen;
import '../../l10n/app_localizations.dart';

class AdminMonitorScreen extends StatefulWidget {
  const AdminMonitorScreen({super.key});

  @override
  State<AdminMonitorScreen> createState() => _AdminMonitorScreenState();
}

class _AdminMonitorScreenState extends State<AdminMonitorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _reviewItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final students = await SupervisorDataService.instance.getStudents();
      final reviewItems = await SupervisorDataService.instance.getAllReviewItems();
      if (!mounted) return;
      setState(() {
        _students = students;
        _reviewItems = reviewItems;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _review(Map<String, dynamic> item, {required bool approve}) async {
    final comment = await showDialog<String>(context: context, builder: (_) => _CommentDialog(isReject: !approve));
    if (comment == null) return;
    try {
      final status = approve ? 'approved' : 'rejected';
      if (item['kind'] == 'report') {
        await SupervisorDataService.instance.reviewReport(reportId: item['id'] as String, status: status, feedback: comment.trim().isEmpty ? null : comment.trim());
      } else {
        await SupervisorDataService.instance.reviewDocument(documentId: item['id'] as String, status: status, feedback: comment.trim().isEmpty ? null : comment.trim());
      }
      _load();
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.adminCouldNotSaveReview(e.toString())), backgroundColor: AppColors.error));
    }
  }

  Future<void> _openStudent(String studentId) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(studentId: studentId)));
    _load();
  }

  Future<void> _view(Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context)!;
    final path = item['storage_path'] as String?;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.supNoFileAttached), backgroundColor: AppColors.warning));
      return;
    }
    try {
      final url = await SupervisorDataService.instance.getReviewFileSignedUrl(path);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => DocumentPreviewScreen(url: url, fileName: path.split('/').last),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.adminCouldNotOpenFile(e.toString())), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reports = _reviewItems.where((i) => i['kind'] == 'report').toList();
    final documents = _reviewItems.where((i) => i['kind'] == 'document').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: l10n.adminMonitorTitle),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Container(
                  color: AppColors.surface,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textMuted,
                    indicatorColor: AppColors.primary,
                    labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600),
                    tabs: [Tab(text: l10n.adminTabStudentProgress), Tab(text: l10n.adminTabReports), Tab(text: l10n.adminTabDocuments)],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _StudentProgressTab(students: _students, onRefresh: _load, onOpenStudent: _openStudent),
                      _ReviewListTab(items: reports, onRefresh: _load, onView: _view, onApprove: (i) => _review(i, approve: true), onReject: (i) => _review(i, approve: false)),
                      _ReviewListTab(items: documents, onRefresh: _load, onView: _view, onApprove: (i) => _review(i, approve: true), onReject: (i) => _review(i, approve: false)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _StudentProgressTab extends StatelessWidget {
  final List<Map<String, dynamic>> students;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String studentId) onOpenStudent;

  const _StudentProgressTab({required this.students, required this.onRefresh, required this.onOpenStudent});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (students.isEmpty) {
      return EmptyState(icon: Icons.school_outlined, title: l10n.adminNoStudentsTitle, description: l10n.adminNoStudentsRegisteredDescription);
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: students.length,
        itemBuilder: (_, i) {
          final s = students[i];
          final name = (s['full_name'] as String?)?.isNotEmpty == true ? s['full_name'] as String : l10n.adminUnnamedStudent;
          final pendingCount = s['pending_review_count'] as int;
          final hasActive = s['has_active_internship'] as bool;
          final color = pendingCount > 0 ? AppColors.warning : AppColors.success;
          return AccentCard(
            accentColor: color,
            onTap: () => onOpenStudent(s['id'] as String),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surfaceVariant,
                  child: Text(logoLetter(name), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      Text(hasActive ? '${s['programme'] ?? ''} · ${s['company_name']}' : (s['programme'] as String?) ?? l10n.adminProgrammeNotSet,
                          style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(pendingCount > 0 ? l10n.supPendingCount(pendingCount) : l10n.supUpToDate, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReviewListTab extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Future<void> Function() onRefresh;
  final void Function(Map<String, dynamic>) onView;
  final void Function(Map<String, dynamic>) onApprove;
  final void Function(Map<String, dynamic>) onReject;

  const _ReviewListTab({required this.items, required this.onRefresh, required this.onView, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return EmptyState(icon: Icons.fact_check_outlined, title: l10n.supNothingHere, description: l10n.adminSubmissionsAppearHere);
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          final isPending = item['status'] == 'submitted';
          final color = item['status'] == 'approved' ? AppColors.success : (item['status'] == 'rejected' ? AppColors.error : AppColors.warning);
          return AccentCard(
            accentColor: color,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.surfaceVariant,
                      child: Text(logoLetter(item['student_name'] as String), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['title'] as String,
                              style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                          Text('${item['student_name']} · ${l10n.supSubmittedAgo(timeAgo(context, DateTime.parse(item['submitted_at'] as String)))}', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    isPending ? StatusBadge.pending(context) : (item['status'] == 'approved' ? StatusBadge.approved(context) : StatusBadge.rejected(context)),
                  ],
                ),
                if (isPending) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => onView(item),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), textStyle: const TextStyle(fontSize: 11)),
                          child: Text(l10n.view),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => onReject(item),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), side: BorderSide(color: AppColors.error)),
                          child: Text(l10n.hrReject, style: TextStyle(fontSize: 11, color: AppColors.error)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => onApprove(item),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                          child: Text(l10n.supApprove, style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CommentDialog extends StatefulWidget {
  final bool isReject;

  const _CommentDialog({required this.isReject});

  @override
  State<_CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<_CommentDialog> {
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(widget.isReject ? l10n.supRejectSubmission : l10n.supApproveSubmission, style: AppTextStyles.h3),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.isReject ? l10n.supRejectFeedbackPrompt : l10n.supApproveCommentPrompt, style: AppTextStyles.bodySecondary),
          const SizedBox(height: 12),
          TextField(controller: _commentController, maxLines: 3, decoration: InputDecoration(hintText: l10n.supTypeYourComment)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        ElevatedButton(
          onPressed: () {
            if (widget.isReject && _commentController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.supPleaseAddFeedback), backgroundColor: AppColors.error));
              return;
            }
            Navigator.pop(context, _commentController.text);
          },
          style: ElevatedButton.styleFrom(backgroundColor: widget.isReject ? AppColors.error : AppColors.primary),
          child: Text(widget.isReject ? l10n.hrReject : l10n.supApprove),
        ),
      ],
    );
  }
}
