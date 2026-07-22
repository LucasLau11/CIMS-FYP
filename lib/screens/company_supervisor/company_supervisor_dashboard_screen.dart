import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../admin_shell.dart';
import 'company_supervisor_reviews_screen.dart';

class CompanySupervisorDashboardScreen extends StatelessWidget {
  const CompanySupervisorDashboardScreen({super.key});

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
                            NotificationBell(count: 2, onTap: () {}),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Ahmad Faris',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        const Text('Company Supervisor · Tencent Malaysia Sdn. Bhd.',
                            style: TextStyle(
                                fontFamily: 'Inter', fontSize: 12, color: Colors.white70)),
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
                        label: 'Current interns',
                        value: '4',
                        icon: Icons.badge_outlined,
                        color: AppColors.primary,
                      ),
                      MetricCard(
                        label: 'Reports to review',
                        value: '3',
                        icon: Icons.pending_actions_outlined,
                        color: AppColors.warning,
                      ),
                      MetricCard(
                        label: 'Approved reports',
                        value: '9',
                        icon: Icons.check_circle_outline,
                        color: AppColors.success,
                      ),
                      MetricCard(
                        label: 'Evaluations due',
                        value: '2',
                        icon: Icons.assessment_outlined,
                        color: AppColors.primaryLight,
                      ),
                    ],
                  ),
                ),

                const SectionHeader(title: 'Pending your review', actionLabel: 'View all'),
                AccentCard(
                  accentColor: AppColors.warning,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CompanySupervisorReviewsScreen())),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.surfaceVariant,
                        child: const Text('TK',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Monthly Report — June 2026',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            Text('Tan Kai Ming · Submitted 28 Jun 2026',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      StatusBadge.pending(),
                    ],
                  ),
                ),
                AccentCard(
                  accentColor: AppColors.warning,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CompanySupervisorReviewsScreen())),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.surfaceVariant,
                        child: const Text('NS',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Monthly Report — June 2026',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            Text('Nur Sabrina · Submitted 29 Jun 2026',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      StatusBadge.pending(),
                    ],
                  ),
                ),

                const SectionHeader(title: 'Intern progress'),
                _InternProgressRow(name: 'Tan Kai Ming', initials: 'TK', progress: 0.42, status: 'On track'),
                _InternProgressRow(name: 'Nur Sabrina', initials: 'NS', progress: 0.55, status: 'On track'),
                _InternProgressRow(name: 'Chong Wei Liang', initials: 'CW', progress: 0.20, status: 'At risk'),
                _InternProgressRow(name: 'Rajesh Kumar', initials: 'RK', progress: 0.80, status: 'On track'),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InternProgressRow extends StatelessWidget {
  final String name;
  final String initials;
  final double progress;
  final String status;

  const _InternProgressRow({
    required this.name,
    required this.initials,
    required this.progress,
    required this.status,
  });

  Color get _color => status == 'At risk' ? AppColors.error : AppColors.success;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.infoBg,
            child: Text(initials,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name,
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                    ),
                    Text('${(progress * 100).toInt()}%',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _color)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation(_color),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
