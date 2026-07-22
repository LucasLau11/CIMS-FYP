import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../admin_shell.dart';

class SupervisorDashboardScreen extends StatelessWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
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
                                  child: const CimsLogoMark(size: 24),
                                ),
                                const SizedBox(width: 10),
                                const Text('CIMS',
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ],
                            ),
                            NotificationBell(count: 4, onTap: () {}),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Dr. Lim Wei Shan',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        const Text('Academic Supervisor · Faculty of Computing and IT',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white70)),
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
                const SectionHeader(title: 'Overview'),
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
                        label: 'Assigned students',
                        value: '12',
                        icon: Icons.people_outline,
                        color: AppColors.primary,
                      ),
                      MetricCard(
                        label: 'Pending reviews',
                        value: '7',
                        icon: Icons.pending_actions_outlined,
                        color: AppColors.warning,
                      ),
                      MetricCard(
                        label: 'Approved this month',
                        value: '18',
                        icon: Icons.check_circle_outline,
                        color: AppColors.success,
                      ),
                      MetricCard(
                        label: 'Unread messages',
                        value: '4',
                        icon: Icons.chat_bubble_outline,
                        color: AppColors.primaryLight,
                      ),
                    ],
                  ),
                ),

                const SectionHeader(title: 'Pending your review', actionLabel: 'View all'),
                AccentCard(
                  accentColor: AppColors.warning,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.surfaceVariant,
                        child: const Text('PD',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Monthly Report — June 2026',
                                style: TextStyle(
                                    fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            Text('Priya Devi · Submitted 29 Jun 2026', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      StatusBadge.pending(),
                    ],
                  ),
                ),
                AccentCard(
                  accentColor: AppColors.warning,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.surfaceVariant,
                        child: const Text('LM',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Offer Letter document',
                                style: TextStyle(
                                    fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            Text('Lee Mei Ling · Submitted 25 Jun 2026', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      StatusBadge.pending(),
                    ],
                  ),
                ),

                const SectionHeader(title: 'My students', actionLabel: 'View all'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 96,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _StudentAvatarTile(name: 'Tan Kai Ming', initials: 'TK', progress: 0.42),
                        _StudentAvatarTile(name: 'Priya Devi', initials: 'PD', progress: 0.18),
                        _StudentAvatarTile(name: 'Ahmad Hafiz', initials: 'AH', progress: 0.75),
                        _StudentAvatarTile(name: 'Wong Jia Hui', initials: 'WJ', progress: 1.0),
                      ],
                    ),
                  ),
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

class _StudentAvatarTile extends StatelessWidget {
  final String name;
  final String initials;
  final double progress;

  const _StudentAvatarTile({required this.name, required this.initials, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.infoBg,
            child: Text(initials, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
          const SizedBox(height: 6),
          Text(name,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('${(progress * 100).toInt()}%',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 9, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
