import 'package:flutter/material.dart';
import '../../widgets/reason_dialog.dart';
import '../../widgets/grade_dialog.dart';
import '../../utils/grading_rubric.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/supervisor_data_service.dart';
import '../../utils/format_utils.dart';
import '../document_preview_screen.dart';
import '../../utils/error_text.dart';
import '../../utils/lang.dart';

class SupervisorReviewsScreen extends StatefulWidget {
  const SupervisorReviewsScreen({super.key});

  @override
  State<SupervisorReviewsScreen> createState() => _SupervisorReviewsScreenState();
}

class _SupervisorReviewsScreenState extends State<SupervisorReviewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _items = [];

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
      final items = await SupervisorDataService.instance.getAllReviewItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _filtered(String tab) {
    if (tab == 'Pending') return _items.where((i) => i['status'] == 'submitted').toList();
    if (tab == 'Approved') return _items.where((i) => i['status'] == 'approved').toList();
    return _items.where((i) => i['status'] == 'rejected').toList();
  }

  Future<void> _review(Map<String, dynamic> item, {required bool approve}) async {
    final isReport = item['kind'] == 'report';
    // Approving a report means grading it (0-100); a rejection needs a written reason; a document
    // only needs an optional comment.
    Map<String, int>? marks;
    String comment;
    if (approve && isReport) {
      final result = await showApproveReportDialog(context,
          isFinal: item['report_type'] == 'final', receivedAt: DateTime.tryParse('${item['submitted_at']}')?.toLocal());
      if (result == null) return;
      marks = result.marks;
      comment = result.comment;
    } else {
      final text = await showDialog<String>(
        context: context,
        builder: (_) => _CommentDialog(isReject: !approve),
      );
      if (text == null) return;
      comment = text;
    }
    try {
      final status = approve ? 'approved' : 'rejected';
      if (isReport) {
        await SupervisorDataService.instance.reviewReport(
          reportId: item['id'] as String,
          status: status,
          feedback: comment.trim().isEmpty ? null : comment.trim(),
          marks: marks,
        );
      } else {
        await SupervisorDataService.instance.reviewDocument(
          documentId: item['id'] as String,
          status: status,
          feedback: comment.trim().isEmpty ? null : comment.trim(),
        );
      }
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tt('Could not save review')}: ${friendlyError(e)}'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _view(Map<String, dynamic> item) async {
    final path = item['storage_path'] as String?;
    if (path == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.supNoFileAttached), backgroundColor: AppColors.warning));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tt('Could not open file')}: ${friendlyError(e)}'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: l10n.supReviews),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Container(
                  color: AppColors.surface,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primaryText,
                    unselectedLabelColor: AppColors.textMuted,
                    indicatorColor: AppColors.primary,
                    labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
                    tabs: [
                      Tab(text: l10n.supTabPending),
                      Tab(text: l10n.supTabApproved),
                      Tab(text: l10n.supTabRejected),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: ['Pending', 'Approved', 'Rejected'].map((tab) {
                      final items = _filtered(tab);
                      if (items.isEmpty) {
                        return EmptyState(
                          icon: Icons.fact_check_outlined,
                          title: l10n.supNothingHere,
                          description: l10n.supItemsAppearHere,
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 24),
                          itemCount: items.length,
                          itemBuilder: (_, i) => _ReviewCard(
                            data: items[i],
                            onView: () => _view(items[i]),
                            onApprove: () => _review(items[i], approve: true),
                            onReject: () => _review(items[i], approve: false),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onView;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ReviewCard({required this.data, required this.onView, required this.onApprove, required this.onReject});

  Color get _accentColor {
    switch (data['status']) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPending = data['status'] == 'submitted';
    final isReport = data['kind'] == 'report';
    final feedback = data['feedback'] as String?;
    // Two-stage approval: for reports, the company supervisor reviews
    // first. Nothing to act on here until that's done.
    final companyReviewStatus = data['company_review_status'] as String?;
    final awaitingCompanyReview = isReport && companyReviewStatus != 'approved';

    return AccentCard(
      accentColor: _accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.surfaceVariant,
                child: Text(logoLetter(data['student_name'] as String),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(isReport ? Icons.assignment_outlined : Icons.description_outlined, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(data['title'] as String,
                              style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    Text(l10n.supSubmittedAgo('${data['student_name']} · ${timeAgo(context, DateTime.parse(data['submitted_at'] as String))}'),
                        style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          if (data['grade'] != null) ...[
            const SizedBox(height: 8),
            Text(
                tr('Marks: ${(data['grade'] as num).toStringAsFixed(0)} / ${rubricMaxTotal(isFinal: data['report_type'] == 'final')}',
                    ms: 'Markah: ${(data['grade'] as num).toStringAsFixed(0)} / ${rubricMaxTotal(isFinal: data['report_type'] == 'final')}',
                    zh: '得分：${(data['grade'] as num).toStringAsFixed(0)} / ${rubricMaxTotal(isFinal: data['report_type'] == 'final')}'),
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
          ],
          if (feedback != null && feedback.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: data['status'] == 'rejected' ? AppColors.errorBg : AppColors.successBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.comment_outlined, size: 14, color: data['status'] == 'rejected' ? AppColors.error : AppColors.success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('"$feedback"',
                        style: TextStyle(
                            fontFamily: 'Inter', fontSize: 12, fontStyle: FontStyle.italic,
                            color: data['status'] == 'rejected' ? AppColors.error : AppColors.success)),
                  ),
                ],
              ),
            ),
          ],
          if (isPending && awaitingCompanyReview) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.hourglass_top, size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      companyReviewStatus == 'rejected' ? l10n.supRejectedByCompany : l10n.supAwaitingCompanyReview,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isPending) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: Text(l10n.view),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), textStyle: const TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), side: BorderSide(color: AppColors.error)),
                    child: Text(l10n.hrReject, style: TextStyle(fontSize: 11, color: AppColors.error)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
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
  }
}

/// Rejecting needs a written reason (at least 100 characters) that the student
/// will read; approving may carry an optional comment.
class _CommentDialog extends StatelessWidget {
  final bool isReject;

  const _CommentDialog({required this.isReject});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ReasonDialog(
      title: isReject ? l10n.supRejectSubmission : l10n.supApproveSubmission,
      prompt: isReject ? l10n.supRejectFeedbackPrompt : l10n.supApproveCommentPrompt,
      confirmLabel: isReject ? l10n.hrReject : l10n.supApprove,
      reasonRequired: isReject,
      destructive: isReject,
    );
  }
}
