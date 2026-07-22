import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import 'supervisor_evaluate_screen.dart';

class SupervisorStudentsScreen extends StatefulWidget {
  const SupervisorStudentsScreen({super.key});

  @override
  State<SupervisorStudentsScreen> createState() => _SupervisorStudentsScreenState();
}

class _SupervisorStudentsScreenState extends State<SupervisorStudentsScreen> {
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _students = [
    {
      'name': 'Tan Kai Ming',
      'id': '22CSB12345',
      'company': 'Tencent Malaysia',
      'progress': 0.42,
      'status': 'On track',
      'initials': 'TK',
      'lastReport': '28 May 2026',
    },
    {
      'name': 'Priya Devi',
      'id': '22CSB09988',
      'company': 'CIMB Bank',
      'progress': 0.18,
      'status': 'At risk',
      'initials': 'PD',
      'lastReport': '29 Apr 2026',
    },
    {
      'name': 'Ahmad Hafiz',
      'id': '22CSB11223',
      'company': 'Grab Holdings',
      'progress': 0.75,
      'status': 'On track',
      'initials': 'AH',
      'lastReport': '30 May 2026',
    },
    {
      'name': 'Wong Jia Hui',
      'id': '21CSB05544',
      'company': 'Maxis Berhad',
      'progress': 1.0,
      'status': 'Completed',
      'initials': 'WJ',
      'lastReport': '15 Jun 2026',
    },
    {
      'name': 'Lee Mei Ling',
      'id': '23CSB00112',
      'company': 'ByteDance Malaysia',
      'progress': 0.05,
      'status': 'On track',
      'initials': 'LM',
      'lastReport': 'Not submitted',
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_searchController.text.isEmpty) return _students;
    final q = _searchController.text.toLowerCase();
    return _students.where((s) => s['name'].toLowerCase().contains(q) || s['id'].toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GradientAppBar(title: 'My students'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search by name or student ID...',
                prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textMuted),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text('${_filtered.length} assigned students', style: AppTextStyles.caption),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 6, bottom: 24),
              itemCount: _filtered.length,
              itemBuilder: (_, i) => _StudentProgressCard(
                data: _filtered[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _StudentDetailScreen(data: _filtered[i]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentProgressCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _StudentProgressCard({required this.data, required this.onTap});

  Color get _statusColor {
    switch (data['status']) {
      case 'At risk': return AppColors.error;
      case 'Completed': return AppColors.textMuted;
      default: return AppColors.success;
    }
  }

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
                radius: 18,
                backgroundColor: AppColors.infoBg,
                child: Text(data['initials'],
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['name'],
                        style: const TextStyle(
                            fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text('${data['id']} · ${data['company']}', style: AppTextStyles.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(data['status'],
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Progress', style: AppTextStyles.caption),
              const Spacer(),
              Text('${(data['progress'] * 100).toInt()}%',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: _statusColor)),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.description_outlined, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('Last report: ${data['lastReport']}', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const _StudentDetailScreen({required this.data});

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
        title: const Text('Student details',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
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
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
                const SizedBox(height: 10),
                Text(data['name'], style: AppTextStyles.h2),
                Text('${data['id']} · ${data['company']}', style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => SupervisorEvaluateScreen(student: data))),
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
          const Text('Internship progress', style: AppTextStyles.h3),
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
                ProgressStepper(steps: const ['Applied', 'Accepted', 'Ongoing', 'Completed'], currentStep: 2),
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
          const SizedBox(height: 20),
          const Text('Submission history', style: AppTextStyles.h3),
          const SizedBox(height: 10),
          AccentCard(
            accentColor: AppColors.success,
            child: Row(
              children: [
                const Icon(Icons.assignment_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Monthly Report — May 2026',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                StatusBadge.approved(),
              ],
            ),
          ),
          AccentCard(
            accentColor: AppColors.success,
            child: Row(
              children: [
                const Icon(Icons.assignment_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Monthly Report — April 2026',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                StatusBadge.approved(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
