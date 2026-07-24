import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/student_data_service.dart';
import '../../utils/format_utils.dart';

class StudentApplicationsScreen extends StatefulWidget {
  const StudentApplicationsScreen({super.key});

  @override
  State<StudentApplicationsScreen> createState() => _StudentApplicationsScreenState();
}

class _StudentApplicationsScreenState extends State<StudentApplicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  List<Map<String, dynamic>> _applications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      final applications = await StudentDataService.instance.getMyApplications();
      if (!mounted) return;
      setState(() {
        _applications = applications;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _withdraw(Map<String, dynamic> application) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Withdraw application?'),
        content: Text(
            'You will be able to re-apply to ${(application['internships'] as Map)['title']} later if you change your mind.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Withdraw', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await StudentDataService.instance.withdrawApplication(application['id'] as String);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not withdraw: $e'), backgroundColor: AppColors.error));
    }
  }

  void _showDetails(Map<String, dynamic> application) {
    final internship = application['internships'] as Map;
    final skills = (application['skills'] as List?)?.cast<String>() ?? [];
    final coverLetter = application['cover_letter'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Text(internship['title'] as String, style: AppTextStyles.h3),
            Text('${internship['company_name']} · ${internship['location']}', style: AppTextStyles.bodySecondary),
            const SizedBox(height: 16),
            const Text('COVER LETTER', style: AppTextStyles.label),
            const SizedBox(height: 6),
            Text(
              coverLetter?.isNotEmpty == true ? coverLetter! : 'No cover letter provided',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: coverLetter?.isNotEmpty == true ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            const Text('SKILLS', style: AppTextStyles.label),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: skills
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration:
                            BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(6)),
                        child: Text(s,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.primary)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text('Applied ${timeAgo(DateTime.parse(application['applied_at'] as String))}',
                style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filtered(String tab) {
    if (tab == 'All') return _applications;
    if (tab == 'Rejected') return _applications.where((a) => a['status'] == 'rejected').toList();
    final map = {'Active': 'active', 'Interview': 'interview'};
    return _applications.where((a) => a['status'] == map[tab]).toList();
  }

  int _countByStatus(String status) => _applications.where((a) => a['status'] == status).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GradientAppBar(title: 'My applications'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(
                children: [
                  // Summary row
                  Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        _SummaryPill(label: 'Total', value: '${_applications.length}', color: AppColors.primary),
                        const SizedBox(width: 8),
                        _SummaryPill(label: 'Active', value: '${_countByStatus('active')}', color: AppColors.success),
                        const SizedBox(width: 8),
                        _SummaryPill(
                            label: 'Interview', value: '${_countByStatus('interview')}', color: AppColors.warning),
                        const SizedBox(width: 8),
                        _SummaryPill(
                            label: 'Pending', value: '${_countByStatus('pending')}', color: AppColors.primaryLight),
                      ],
                    ),
                  ),
                  // Tab bar
                  Container(
                    color: AppColors.surface,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textMuted,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 2,
                      labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
                      tabs: const [
                        Tab(text: 'All'),
                        Tab(text: 'Active'),
                        Tab(text: 'Interview'),
                        Tab(text: 'Rejected'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: ['All', 'Active', 'Interview', 'Rejected'].map((tab) {
                        final items = _filtered(tab);
                        if (items.isEmpty) {
                          return const EmptyState(
                            icon: Icons.work_outline,
                            title: 'No applications here',
                            description: 'Applications in this category will appear here.',
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          itemCount: items.length,
                          itemBuilder: (_, i) => _ApplicationCard(
                            data: items[i],
                            onViewDetails: () => _showDetails(items[i]),
                            onWithdraw: items[i]['status'] == 'pending' ? () => _withdraw(items[i]) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onViewDetails;
  final VoidCallback? onWithdraw;

  const _ApplicationCard({required this.data, required this.onViewDetails, required this.onWithdraw});

  Color get _accentColor {
    switch (data['status']) {
      case 'active':
        return AppColors.success;
      case 'interview':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.primaryLight;
    }
  }

  StatusBadge get _badge {
    switch (data['status']) {
      case 'active':
        return StatusBadge.active();
      case 'interview':
        return const StatusBadge(
            label: 'Interview', backgroundColor: Color(0xFFFEF3C7), textColor: Color(0xFFD97706));
      case 'rejected':
        return StatusBadge.rejected();
      default:
        return StatusBadge.pending();
    }
  }

  @override
  Widget build(BuildContext context) {
    final internship = data['internships'] as Map;
    final companyName = internship['company_name'] as String;
    final appliedAt = DateTime.parse(data['applied_at'] as String);
    final interviewAt = data['interview_at'] != null ? DateTime.parse(data['interview_at'] as String) : null;

    return AccentCard(
      onTap: onViewDetails,
      accentColor: _accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration:
                    BoxDecoration(color: nameColor(companyName).withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
                child: Center(
                  child: Text(logoLetter(companyName),
                      style: TextStyle(
                          fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: nameColor(companyName))),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(internship['title'] as String,
                        style: const TextStyle(
                            fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text(companyName, style: AppTextStyles.caption),
                  ],
                ),
              ),
              _badge,
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              _MetaItem(icon: Icons.location_on_outlined, label: internship['location'] as String),
              const SizedBox(width: 14),
              _MetaItem(icon: Icons.calendar_today_outlined, label: 'Applied ${timeAgo(appliedAt)}'),
            ],
          ),
          if (interviewAt != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.videocam_outlined, size: 15, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Text('Interview scheduled: ${interviewAt.toString()}',
                      style: const TextStyle(
                          fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.warning)),
                ],
              ),
            ),
          ],
          if (onWithdraw != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onWithdraw,
                    icon: const Icon(Icons.cancel_outlined, size: 15, color: AppColors.error),
                    label: const Text('Withdraw', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                      side: const BorderSide(color: AppColors.error),
                    ),
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

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
