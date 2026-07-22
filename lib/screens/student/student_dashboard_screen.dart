import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import 'student_notifications_screen.dart';
import 'student_profile_screen.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Gradient header with wave
          SliverAppBar(
            expandedHeight: 190,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
              title: const Text('Dashboard',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const StudentProfileScreen())),
                              child: const CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white24,
                                child: Text('TK',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                              ),
                            ),
                            NotificationBell(
                              count: 3,
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const StudentNotificationsScreen())),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Good morning, Tan Kai!',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Bachelor of Computer Science · Sem 6',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: const [],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active internship status banner
                _ActiveInternshipBanner(),

                // Metric grid
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
                        label: 'Applications sent',
                        value: '5',
                        icon: Icons.send_outlined,
                        color: AppColors.primary,
                      ),
                      MetricCard(
                        label: 'Interviews scheduled',
                        value: '2',
                        icon: Icons.calendar_today_outlined,
                        color: AppColors.warning,
                      ),
                      MetricCard(
                        label: 'Reports submitted',
                        value: '3',
                        icon: Icons.assignment_turned_in_outlined,
                        color: AppColors.success,
                      ),
                      MetricCard(
                        label: 'Days remaining',
                        value: '42',
                        icon: Icons.timer_outlined,
                        color: AppColors.primaryLight,
                      ),
                    ],
                  ),
                ),

                // Internship progress
                const SectionHeader(title: 'Internship progress'),
                _InternshipProgressCard(),

                // Upcoming deadlines
                const SectionHeader(
                  title: 'Upcoming deadlines',
                  actionLabel: 'View all',
                ),
                _DeadlineItem(
                  title: 'Monthly Report — June',
                  dueDate: 'Due 30 Jun 2026',
                  icon: Icons.assignment_outlined,
                  isUrgent: true,
                ),
                _DeadlineItem(
                  title: 'Supervisor Evaluation Form',
                  dueDate: 'Due 5 Jul 2026',
                  icon: Icons.rate_review_outlined,
                  isUrgent: false,
                ),
                _DeadlineItem(
                  title: 'Final Report',
                  dueDate: 'Due 31 Jul 2026',
                  icon: Icons.library_books_outlined,
                  isUrgent: false,
                ),

                // Recent feedback
                const SectionHeader(
                  title: 'Recent feedback',
                  actionLabel: 'View all',
                ),
                AccentCard(
                  accentColor: AppColors.success,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.surfaceVariant,
                            child: Icon(Icons.person, size: 18, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Dr. Lim Wei Shan',
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                              Text('Academic Supervisor',
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                          const Spacer(),
                          StatusBadge.approved(),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '"Good progress on your May report. Please elaborate more on technical challenges in the next submission."',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                // Company review prompt
                const SectionHeader(title: 'Quick actions'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickActionTile(
                          icon: Icons.rate_review_outlined,
                          label: 'Submit company review',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickActionTile(
                          icon: Icons.trending_up,
                          label: 'View my progress',
                          onTap: () {},
                        ),
                      ),
                    ],
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

class _ActiveInternshipBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D6E78), Color(0xFF14B8C8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.work, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Internship active',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                Text('Tencent Malaysia Sdn. Bhd.',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Colors.white70)),
                Text('1 Jun — 31 Aug 2026',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Colors.white60)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Week 4',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _InternshipProgressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ProgressStepper(
            steps: const ['Applied', 'Accepted', 'Ongoing', 'Completed'],
            currentStep: 2,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Overall progress',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textSecondary)),
              const Spacer(),
              const Text('42%',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.42,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeadlineItem extends StatelessWidget {
  final String title;
  final String dueDate;
  final IconData icon;
  final bool isUrgent;

  const _DeadlineItem({
    required this.title,
    required this.dueDate,
    required this.icon,
    required this.isUrgent,
  });

  @override
  Widget build(BuildContext context) {
    return AccentCard(
      accentColor: isUrgent ? AppColors.error : AppColors.cardAccent,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isUrgent ? AppColors.errorBg : AppColors.infoBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                size: 20,
                color: isUrgent ? AppColors.error : AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(dueDate, style: AppTextStyles.caption),
              ],
            ),
          ),
          if (isUrgent)
            const StatusBadge(
              label: 'Urgent',
              backgroundColor: AppColors.errorBg,
              textColor: AppColors.error,
            ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}