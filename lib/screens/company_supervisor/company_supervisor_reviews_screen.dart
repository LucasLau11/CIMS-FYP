import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';

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

  final List<Map<String, dynamic>> _reports = [
    {
      'student': 'Tan Kai Ming',
      'initials': 'TK',
      'title': 'Monthly Report — June 2026',
      'submittedDate': '28 Jun 2026',
      'status': 'pending',
      'comment': null,
    },
    {
      'student': 'Nur Sabrina',
      'initials': 'NS',
      'title': 'Monthly Report — June 2026',
      'submittedDate': '29 Jun 2026',
      'status': 'pending',
      'comment': null,
    },
    {
      'student': 'Tan Kai Ming',
      'initials': 'TK',
      'title': 'Monthly Report — May 2026',
      'submittedDate': '28 May 2026',
      'status': 'approved',
      'comment': 'Well done. Technical output this month exceeded expectations.',
    },
    {
      'student': 'Chong Wei Liang',
      'initials': 'CW',
      'title': 'Monthly Report — May 2026',
      'submittedDate': '30 May 2026',
      'status': 'rejected',
      'comment': 'Report is incomplete. Please include task breakdown and hours logged.',
    },
  ];

  List<Map<String, dynamic>> _filtered(String tab) {
    final map = {'Pending': 'pending', 'Approved': 'approved', 'Rejected': 'rejected'};
    return _reports.where((r) => r['status'] == map[tab]).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Report reviews',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          labelStyle:
              const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [Tab(text: 'Pending'), Tab(text: 'Approved'), Tab(text: 'Rejected')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: ['Pending', 'Approved', 'Rejected'].map((tab) {
          final items = _filtered(tab);
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.fact_check_outlined,
              title: 'Nothing here',
              description: 'Reports in this category will appear here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: items.length,
            itemBuilder: (_, i) => _ReportCard(
              data: items[i],
              onAction: () => setState(() {}),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onAction;

  const _ReportCard({required this.data, required this.onAction});

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
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['title'],
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    Text('${data['student']} · Submitted ${data['submittedDate']}',
                        style: AppTextStyles.caption),
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
                  Icon(Icons.comment_outlined,
                      size: 13,
                      color: data['status'] == 'rejected' ? AppColors.error : AppColors.success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('"${data['comment']}"',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: data['status'] == 'rejected'
                                ? AppColors.error
                                : AppColors.success)),
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
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showCommentDialog(context, isReject: true),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: const BorderSide(color: AppColors.error)),
                    child: const Text('Reject',
                        style: TextStyle(fontSize: 11, color: AppColors.error)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showCommentDialog(context, isReject: false),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8)),
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
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(isReject ? 'Reject report' : 'Approve report', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isReject
                  ? 'Provide feedback explaining the rejection reason.'
                  : 'Add an optional comment for the intern.',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Type your comment...'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onAction();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: isReject ? AppColors.error : AppColors.primary),
            child: Text(isReject ? 'Reject' : 'Approve'),
          ),
        ],
      ),
    );
  }
}
