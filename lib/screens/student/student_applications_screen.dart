import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';

class StudentApplicationsScreen extends StatefulWidget {
  const StudentApplicationsScreen({super.key});

  @override
  State<StudentApplicationsScreen> createState() => _StudentApplicationsScreenState();
}

class _StudentApplicationsScreenState extends State<StudentApplicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _applications = [
    {
      'company': 'Tencent Malaysia',
      'role': 'Software Engineering Intern',
      'location': 'Kuala Lumpur',
      'appliedDate': '1 Jun 2026',
      'status': 'active',
      'statusLabel': 'Ongoing',
      'logo': 'T',
      'logoColor': Color(0xFF00A3FF),
      'interview': null,
      'allowance': 'RM 1,500/month',
    },
    {
      'company': 'Grab',
      'role': 'Data Science Intern',
      'location': 'Petaling Jaya',
      'appliedDate': '15 May 2026',
      'status': 'interview',
      'statusLabel': 'Interview',
      'logo': 'G',
      'logoColor': Color(0xFF00B14F),
      'interview': '5 Jul 2026, 10:00 AM',
      'allowance': 'RM 2,000/month',
    },
    {
      'company': 'Maxis Berhad',
      'role': 'Network Engineering Intern',
      'location': 'Kuala Lumpur',
      'appliedDate': '10 May 2026',
      'status': 'pending',
      'statusLabel': 'Pending',
      'logo': 'M',
      'logoColor': Color(0xFFE30613),
      'interview': null,
      'allowance': 'RM 1,200/month',
    },
    {
      'company': 'Shopee',
      'role': 'UI/UX Design Intern',
      'location': 'Shah Alam',
      'appliedDate': '8 May 2026',
      'status': 'rejected',
      'statusLabel': 'Rejected',
      'logo': 'S',
      'logoColor': Color(0xFFEE4D2D),
      'interview': null,
      'allowance': 'RM 1,800/month',
    },
    {
      'company': 'CIMB Bank',
      'role': 'IT Business Analyst Intern',
      'location': 'Kuala Lumpur',
      'appliedDate': '5 May 2026',
      'status': 'rejected',
      'statusLabel': 'Rejected',
      'logo': 'C',
      'logoColor': Color(0xFF8B0000),
      'interview': null,
      'allowance': 'RM 1,000/month',
    },
  ];

  List<Map<String, dynamic>> _filtered(String tab) {
    if (tab == 'All') return _applications;
    final map = {'Active': 'active', 'Interview': 'interview', 'Pending': 'pending'};
    if (tab == 'Rejected') return _applications.where((a) => a['status'] == 'rejected').toList();
    return _applications.where((a) => a['status'] == map[tab]).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: 'My applications',
        actions: [
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary row
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                _SummaryPill(label: 'Total', value: '5', color: AppColors.primary),
                const SizedBox(width: 8),
                _SummaryPill(label: 'Active', value: '1', color: AppColors.success),
                const SizedBox(width: 8),
                _SummaryPill(label: 'Interview', value: '1', color: AppColors.warning),
                const SizedBox(width: 8),
                _SummaryPill(label: 'Pending', value: '1', color: AppColors.primaryLight),
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
              labelStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
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
                  itemBuilder: (_, i) => _ApplicationCard(data: items[i]),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: color)),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ApplicationCard({required this.data});

  Color get _accentColor {
    switch (data['status']) {
      case 'active': return AppColors.success;
      case 'interview': return AppColors.warning;
      case 'rejected': return AppColors.error;
      default: return AppColors.primaryLight;
    }
  }

  StatusBadge get _badge {
    switch (data['status']) {
      case 'active': return StatusBadge.active();
      case 'interview': return const StatusBadge(
          label: 'Interview',
          backgroundColor: Color(0xFFFEF3C7),
          textColor: Color(0xFFD97706));
      case 'rejected': return StatusBadge.rejected();
      default: return StatusBadge.pending();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccentCard(
      accentColor: _accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (data['logoColor'] as Color).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(data['logo'],
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: data['logoColor'])),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['role'],
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    Text(data['company'],
                        style: AppTextStyles.caption),
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
              _MetaItem(
                  icon: Icons.location_on_outlined, label: data['location']),
              const SizedBox(width: 14),
              _MetaItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Applied ${data['appliedDate']}'),
            ],
          ),
          if (data['interview'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.videocam_outlined,
                      size: 15, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Text('Interview scheduled: ${data['interview']}',
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.warning)),
                ],
              ),
            ),
          ],
          if (data['status'] == 'active') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.visibility_outlined, size: 15),
                    label: const Text('View details'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
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
