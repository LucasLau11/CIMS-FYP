import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/company_supervisor_data_service.dart';
import '../../utils/format_utils.dart';

class CompanySupervisorReviewsScreen extends StatefulWidget {
  const CompanySupervisorReviewsScreen({super.key});

  @override
  State<CompanySupervisorReviewsScreen> createState() =>
      _CompanySupervisorReviewsScreenState();
}

class _CompanySupervisorReviewsScreenState
    extends State<CompanySupervisorReviewsScreen>
    with SingleTickerProviderStateMixin {
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
      final items = await CompanySupervisorDataService.instance.getReviewItems();
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

  List<Map<String, dynamic>> _filtered(String status) => _items.where((r) => r['status'] == status).toList();

  Future<void> _review(Map<String, dynamic> item, {required bool approve}) async {
    final comment = await showDialog<String>(context: context, builder: (_) => _CommentDialog(isReject: !approve));
    if (comment == null) return;
    try {
      final status = approve ? 'approved' : 'rejected';
      final feedback = comment.trim().isEmpty ? null : comment.trim();
      if (item['kind'] == 'report') {
        await CompanySupervisorDataService.instance.reviewReport(reportId: item['id'] as String, status: status, feedback: feedback);
      } else {
        await CompanySupervisorDataService.instance.reviewDocument(documentId: item['id'] as String, status: status, feedback: feedback);
      }
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save review: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _view(Map<String, dynamic> item) async {
    final path = item['storage_path'] as String?;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.supNoFileAttached), backgroundColor: AppColors.warning));
      return;
    }
    try {
      final url = await CompanySupervisorDataService.instance.getReviewFileSignedUrl(path);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open file: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(l10n.csReportReviews, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [Tab(text: l10n.csTabPending), Tab(text: l10n.csTabApproved), Tab(text: l10n.csTabRejected)],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: ['submitted', 'approved', 'rejected'].map((status) {
                final items = _filtered(status);
                if (items.isEmpty) {
                  return EmptyState(icon: Icons.fact_check_outlined, title: l10n.csNothingHere, description: l10n.csReportsAppearHere);
                }
                return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _ReportCard(
                      data: items[i],
                      onView: () => _view(items[i]),
                      onApprove: () => _review(items[i], approve: true),
                      onReject: () => _review(items[i], approve: false),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onView;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ReportCard({required this.data, required this.onView, required this.onApprove, required this.onReject});

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
                child: Text(logoLetter(data['student_name'] as String), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['title'] as String, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text(l10n.supSubmittedAgo('${data['student_name']} · ${timeAgo(DateTime.parse(data['submitted_at'] as String))}'), style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          if (data['feedback'] != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: data['status'] == 'rejected' ? AppColors.errorBg : AppColors.successBg, borderRadius: BorderRadius.circular(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.comment_outlined, size: 13, color: data['status'] == 'rejected' ? AppColors.error : AppColors.success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('"${data['feedback']}"',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontStyle: FontStyle.italic, color: data['status'] == 'rejected' ? AppColors.error : AppColors.success)),
                  ),
                ],
              ),
            ),
          ],
          if (isPending) ...[
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
      title: Text(widget.isReject ? l10n.csRejectReport : l10n.csApproveReport, style: AppTextStyles.h3),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.isReject ? l10n.csRejectReasonPrompt : l10n.csApproveCommentPrompt, style: AppTextStyles.bodySecondary),
          const SizedBox(height: 12),
          TextField(controller: _commentController, maxLines: 3, decoration: InputDecoration(hintText: l10n.supTypeYourComment)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        ElevatedButton(
          onPressed: () {
            if (widget.isReject && _commentController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.csPleaseAddFeedback), backgroundColor: AppColors.error));
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
