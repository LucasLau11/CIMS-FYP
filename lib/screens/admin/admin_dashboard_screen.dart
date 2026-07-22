import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../admin_shell.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: AppColors.primary,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const CimsLogoMark(size: 26),
                                ),
                                const SizedBox(width: 10),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('CIMS Admin',
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white)),
                                    Text('TARUMT',
                                        style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 10,
                                            color: Colors.white70)),
                                  ],
                                ),
                              ],
                            ),
                            NotificationBell(count: 5, onTap: () {}),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Welcome back, Admin',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Key stats grid
                const SectionHeader(title: 'System overview'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.5,
                    children: const [
                      MetricCard(
                        label: 'Total students',
                        value: '1,248',
                        icon: Icons.school_outlined,
                        color: AppColors.primary,
                      ),
                      MetricCard(
                        label: 'Active internships',
                        value: '683',
                        icon: Icons.work_outline,
                        color: AppColors.success,
                      ),
                      MetricCard(
                        label: 'Partner companies',
                        value: '156',
                        icon: Icons.business_outlined,
                        color: AppColors.primaryLight,
                      ),
                      MetricCard(
                        label: 'Pending reviews',
                        value: '34',
                        icon: Icons.pending_actions_outlined,
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                ),

                // Alerts requiring attention
                const SectionHeader(
                  title: 'Needs attention',
                  actionLabel: 'View all',
                ),
                AccentCard(
                  accentColor: AppColors.error,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.errorBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.report_problem_outlined,
                            size: 18, color: AppColors.error),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('12 students unassigned',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            Text('No academic supervisor assigned yet',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.textMuted, size: 18),
                    ],
                  ),
                ),
                AccentCard(
                  accentColor: AppColors.warning,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warningBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.assignment_late_outlined,
                            size: 18, color: AppColors.warning),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('22 reports pending review',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            Text('Awaiting administrator oversight',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.textMuted, size: 18),
                    ],
                  ),
                ),

                // Quick actions
                const SectionHeader(title: 'Quick actions'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1,
                    children: [
                      _QuickAction(
                          icon: Icons.person_add_alt_outlined,
                          label: 'Add Student',
                          onTap: () {}),
                      _QuickAction(
                          icon: Icons.add_business_outlined,
                          label: 'Add Company',
                          onTap: () {}),
                      _QuickAction(
                          icon: Icons.person_add_outlined,
                          label: 'Add Supervisor',
                          onTap: () {}),
                      _QuickAction(
                          icon: Icons.upload_file_outlined,
                          label: 'Upload Template',
                          onTap: () {}),
                      _QuickAction(
                          icon: Icons.link_outlined,
                          label: 'Assign Supervisor',
                          onTap: () {}),
                      _QuickAction(
                          icon: Icons.send_outlined,
                          label: 'Broadcast',
                          onTap: () {}),
                    ],
                  ),
                ),

                // Recent activity
                const SectionHeader(
                  title: 'Recent activity',
                  actionLabel: 'View all',
                ),
                _ActivityItem(
                  icon: Icons.person_add_alt_outlined,
                  text: 'New student registered: Lee Mei Ling (23CSB00112)',
                  time: '10 min ago',
                  color: AppColors.primary,
                ),
                _ActivityItem(
                  icon: Icons.business_outlined,
                  text: 'Company "ByteDance Malaysia" added to system',
                  time: '1 hour ago',
                  color: AppColors.primaryLight,
                ),
                _ActivityItem(
                  icon: Icons.check_circle_outline,
                  text: 'Monthly report approved for 18 students',
                  time: '3 hours ago',
                  color: AppColors.success,
                ),
                _ActivityItem(
                  icon: Icons.supervisor_account_outlined,
                  text: 'Dr. Lim Wei Shan assigned to 5 students',
                  time: 'Yesterday',
                  color: AppColors.warning,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final String time;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.text,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(time, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
