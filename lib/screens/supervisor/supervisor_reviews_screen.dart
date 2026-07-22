import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';

class SupervisorReviewsScreen extends StatefulWidget {
  const SupervisorReviewsScreen({super.key});

  @override
  State<SupervisorReviewsScreen> createState() => _SupervisorReviewsScreenState();
}

class _SupervisorReviewsScreenState extends State<SupervisorReviewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _items = [
    {
      'type': 'report',
      'student': 'Priya Devi',
      'initials': 'PD',
      'title': 'Monthly Report — June 2026',
      'submittedDate': '29 Jun 2026',
      'status': 'pending',
    },
    {
      'type': 'document',
      'student': 'Lee Mei Ling',
      'initials': 'LM',
      'title': 'Offer Letter',
      'submittedDate': '25 Jun 2026',
      'status': 'pending',
    },
    {
      'type': 'report',
      'student': 'Tan Kai Ming',
      'initials': 'TK',
      'title': 'Monthly Report — May 2026',
      'submittedDate': '28 May 2026',
      'status': 'approved',
      'comment': 'Good progress. Elaborate on technical challenges next time.',
    },
    {
      'type': 'document',
      'student': 'Ahmad Hafiz',
      'initials': 'AH',
      'title': 'Industrial Training Form (LI01)',
      'submittedDate': '20 Jun 2026',
      'status': 'approved',
      'comment': null,
    },
    {
      'type': 'report',
      'student': 'Wong Jia Hui',
      'initials': 'WJ',
      'title': 'Final Report',
      'submittedDate': '14 Jun 2026',
      'status': 'rejected',
      'comment': 'Missing reflection section. Please resubmit with full analysis.',
    },
  ];

  List<Map<String, dynamic>> _filtered(String tab) {
    if (tab == 'Pending') return _items.where((i) => i['status'] == 'pending').toList();
    if (tab == 'Approved') return _items.where((i) => i['status'] == 'approved').toList();
    return _items.where((i) => i['status'] == 'rejected').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GradientAppBar(title: 'Reviews'),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Approved'),
                Tab(text: 'Rejected'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: ['Pending', 'Approved', 'Rejected'].map((tab) {
                final items = _filtered(tab);
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.fact_check_outlined,
                    title: 'Nothing here',
                    description: 'Items in this category will appear here.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _ReviewCard(data: items[i]),
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

  const _ReviewCard({required this.data});

  Color get _accentColor {
    switch (data['status']) {
      case 'approved': return AppColors.success;
      case 'rejected': return AppColors.error;
      default: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = data['status'] == 'pending';
    final isReport = data['type'] == 'report';

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
                child: Text(data['initials'],
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(isReport ? Icons.assignment_outlined : Icons.description_outlined,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(data['title'],
                              style: const TextStyle(
                                  fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    Text('${data['student']} · Submitted ${data['submittedDate']}', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          if (data['comment'] != null) ...[
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
                  Icon(Icons.comment_outlined, size: 14,
                      color: data['status'] == 'rejected' ? AppColors.error : AppColors.success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('"${data['comment']}"',
                        style: TextStyle(
                            fontFamily: 'Inter', fontSize: 12, fontStyle: FontStyle.italic,
                            color: data['status'] == 'rejected' ? AppColors.error : AppColors.success)),
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
                    onPressed: () {},
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: const Text('View'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), textStyle: const TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showCommentDialog(context, isReject: true),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: const BorderSide(color: AppColors.error)),
                    child: const Text('Reject', style: TextStyle(fontSize: 11, color: AppColors.error)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showCommentDialog(context, isReject: false),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                    child: const Text('Approve', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showCommentDialog(BuildContext context, {required bool isReject}) {
    showDialog(
      context: context,
      builder: (_) => _CommentDialog(isReject: isReject),
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(widget.isReject ? 'Reject submission' : 'Approve submission', style: AppTextStyles.h3),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isReject
                ? 'Please provide feedback explaining why this is being rejected.'
                : 'Add an optional comment for the student.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Type your comment...'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isReject ? AppColors.error : AppColors.primary,
          ),
          child: Text(widget.isReject ? 'Reject' : 'Approve'),
        ),
      ],
    );
  }
}
