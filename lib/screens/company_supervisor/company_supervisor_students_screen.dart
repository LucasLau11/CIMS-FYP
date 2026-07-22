import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import 'company_supervisor_evaluate_screen.dart';

class CompanySupervisorStudentsScreen extends StatelessWidget {
  const CompanySupervisorStudentsScreen({super.key});

  final List<Map<String, dynamic>> _interns = const [
    {
      'name': 'Tan Kai Ming',
      'id': '22CSB12345',
      'university': 'TARUMT',
      'role': 'Software Engineering Intern',
      'progress': 0.42,
      'status': 'On track',
      'initials': 'TK',
      'startDate': '1 Jun 2026',
      'endDate': '31 Aug 2026',
    },
    {
      'name': 'Nur Sabrina',
      'id': '22CSB30021',
      'university': 'TARUMT',
      'role': 'QA Engineering Intern',
      'progress': 0.55,
      'status': 'On track',
      'initials': 'NS',
      'startDate': '1 Jun 2026',
      'endDate': '31 Aug 2026',
    },
    {
      'name': 'Chong Wei Liang',
      'id': '22CSB09012',
      'university': 'TARUMT',
      'role': 'Software Engineering Intern',
      'progress': 0.20,
      'status': 'At risk',
      'initials': 'CW',
      'startDate': '1 Jun 2026',
      'endDate': '31 Aug 2026',
    },
    {
      'name': 'Rajesh Kumar',
      'id': '22CSB18890',
      'university': 'TARUMT',
      'role': 'Mobile App Development Intern',
      'progress': 0.80,
      'status': 'On track',
      'initials': 'RK',
      'startDate': '1 Jun 2026',
      'endDate': '31 Aug 2026',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GradientAppBar(title: 'Interns'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text('${_interns.length} current interns', style: AppTextStyles.caption),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('1 at risk',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: _interns.length,
              itemBuilder: (_, i) => _InternCard(
                data: _interns[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => _InternDetailScreen(data: _interns[i])),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InternCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _InternCard({required this.data, required this.onTap});

  Color get _statusColor =>
      data['status'] == 'At risk' ? AppColors.error : AppColors.success;

  @override
  Widget build(BuildContext context) {
    return AccentCard(
      accentColor: _statusColor,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.infoBg,
                child: Text(data['initials'],
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['name'],
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    Text('${data['id']} · ${data['role']}',
                        style: AppTextStyles.caption,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(data['status'],
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Progress', style: AppTextStyles.caption),
              const Spacer(),
              Text('${(data['progress'] * 100).toInt()}%',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _statusColor)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: data['progress'],
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(_statusColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _InternDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const _InternDetailScreen({required this.data});

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
        title: const Text('Intern details',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.infoBg,
                  child: Text(data['initials'],
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ),
                const SizedBox(height: 10),
                Text(data['name'], style: AppTextStyles.h2),
                Text('${data['id']} · ${data['university']}',
                    style: AppTextStyles.bodySecondary),
                const SizedBox(height: 6),
                Text(data['role'],
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => CompanySupervisorEvaluateScreen(intern: data))),
                  icon: const Icon(Icons.assessment_outlined, size: 16),
                  label: const Text('Evaluate'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Internship details', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _DetailLine(icon: Icons.calendar_today_outlined,
                    label: 'Start date', value: data['startDate']),
                const Divider(height: 1, indent: 44),
                _DetailLine(icon: Icons.event_outlined,
                    label: 'End date', value: data['endDate']),
                const Divider(height: 1, indent: 44),
                _DetailLine(icon: Icons.school_outlined,
                    label: 'University', value: data['university']),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Progress', style: AppTextStyles.h3),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                ProgressStepper(
                    steps: const ['Applied', 'Accepted', 'Ongoing', 'Completed'],
                    currentStep: 2),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: data['progress'],
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primaryLight),
                    minHeight: 8,
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

class _DetailLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailLine({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}
