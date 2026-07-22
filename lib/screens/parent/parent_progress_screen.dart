import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';

class ParentProgressScreen extends StatelessWidget {
  const ParentProgressScreen({super.key});

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
        title: const Text('Internship Progress',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Student + company summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D6E78), Color(0xFF14B8C8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white24,
                      child: Text('TK',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tan Kai Ming',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          Text('Tencent Malaysia Sdn. Bhd.',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Colors.white70)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
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
                const SizedBox(height: 16),
                const Text('Overall progress',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Colors.white70)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.42,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1 Jun 2026',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: Colors.white60)),
                    Text('42% completed',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    Text('31 Aug 2026',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: Colors.white60)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Progress stepper
          const Text('Internship journey', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: ProgressStepper(
              steps: const ['Applied', 'Accepted', 'Ongoing', 'Completed'],
              currentStep: 2,
            ),
          ),

          const SizedBox(height: 20),

          // Quick stats
          const Text('At a glance', style: AppTextStyles.h3),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: const [
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

          const SizedBox(height: 20),

          // Report history — read only
          const Text('Report submissions', style: AppTextStyles.h3),
          const SizedBox(height: 10),
          _ReportStatusRow(
            title: 'Monthly Report — June 2026',
            date: 'Due 30 Jun 2026',
            status: 'pending',
          ),
          _ReportStatusRow(
            title: 'Monthly Report — May 2026',
            date: 'Submitted 28 May 2026',
            status: 'approved',
          ),
          _ReportStatusRow(
            title: 'Monthly Report — April 2026',
            date: 'Submitted 29 Apr 2026',
            status: 'approved',
          ),

          const SizedBox(height: 20),

          // Supervisor feedback — read only
          const Text('Latest supervisor feedback', style: AppTextStyles.h3),
          const SizedBox(height: 10),
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
                      child: Icon(Icons.person,
                          size: 18, color: AppColors.textSecondary),
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
                      height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Read-only notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline, size: 16, color: AppColors.textMuted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is a read-only view. Contact the university for queries regarding your child\'s internship.',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ReportStatusRow extends StatelessWidget {
  final String title;
  final String date;
  final String status;

  const _ReportStatusRow({
    required this.title,
    required this.date,
    required this.status,
  });

  Color get _accentColor {
    switch (status) {
      case 'approved': return AppColors.success;
      case 'rejected': return AppColors.error;
      default: return AppColors.warning;
    }
  }

  StatusBadge get _badge {
    switch (status) {
      case 'approved': return StatusBadge.approved();
      case 'rejected': return StatusBadge.rejected();
      default: return StatusBadge.pending();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccentCard(
      accentColor: _accentColor,
      child: Row(
        children: [
          Icon(Icons.assignment_outlined,
              size: 18,
              color: _accentColor),
          const SizedBox(width: 10),
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
                Text(date, style: AppTextStyles.caption),
              ],
            ),
          ),
          _badge,
        ],
      ),
    );
  }
}
