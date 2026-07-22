import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';

class HrApplicantsScreen extends StatefulWidget {
  const HrApplicantsScreen({super.key});

  @override
  State<HrApplicantsScreen> createState() => _HrApplicantsScreenState();
}

class _HrApplicantsScreenState extends State<HrApplicantsScreen>
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

  final List<Map<String, dynamic>> _applicants = [
    {
      'name': 'Tan Kai Ming',
      'id': '22CSB12345',
      'university': 'TARUMT',
      'role': 'Software Engineering Intern',
      'appliedDate': '1 Jun 2026',
      'status': 'interview',
      'interviewTime': 'Today, 3:00 PM',
      'initials': 'TK',
      'matchScore': 94,
    },
    {
      'name': 'Lim Sok Mun',
      'id': '22CSB22341',
      'university': 'TARUMT',
      'role': 'Software Engineering Intern',
      'appliedDate': '2 Jun 2026',
      'status': 'new',
      'interviewTime': null,
      'initials': 'LS',
      'matchScore': 88,
    },
    {
      'name': 'Rajesh Kumar',
      'id': '22CSB18890',
      'university': 'TARUMT',
      'role': 'Mobile App Development Intern',
      'appliedDate': '3 Jun 2026',
      'status': 'new',
      'interviewTime': null,
      'initials': 'RK',
      'matchScore': 81,
    },
    {
      'name': 'Nur Sabrina',
      'id': '22CSB30021',
      'university': 'TARUMT',
      'role': 'QA Engineering Intern',
      'appliedDate': '28 May 2026',
      'status': 'accepted',
      'interviewTime': null,
      'initials': 'NS',
      'matchScore': 90,
    },
    {
      'name': 'Chong Wei Liang',
      'id': '22CSB09012',
      'university': 'TARUMT',
      'role': 'Software Engineering Intern',
      'appliedDate': '25 May 2026',
      'status': 'rejected',
      'interviewTime': null,
      'initials': 'CW',
      'matchScore': 62,
    },
  ];

  List<Map<String, dynamic>> _filtered(String tab) {
    final map = {'New': 'new', 'Interview': 'interview', 'Accepted': 'accepted', 'Rejected': 'rejected'};
    return _applicants.where((a) => a['status'] == map[tab]).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GradientAppBar(title: 'Applicants'),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'New (2)'),
                Tab(text: 'Interview (1)'),
                Tab(text: 'Accepted (1)'),
                Tab(text: 'Rejected (1)'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: ['New', 'Interview', 'Accepted', 'Rejected'].map((tab) {
                final items = _filtered(tab);
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline,
                    title: 'No applicants here',
                    description: 'Applicants in this stage will appear here.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _ApplicantCard(
                    data: items[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => _ApplicantDetailScreen(data: items[i])),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _ApplicantCard({required this.data, required this.onTap});

  Color get _accentColor {
    switch (data['status']) {
      case 'accepted': return AppColors.success;
      case 'rejected': return AppColors.error;
      case 'interview': return AppColors.warning;
      default: return AppColors.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = data['matchScore'] as int;
    final scoreColor = score >= 90 ? AppColors.success : score >= 75 ? AppColors.primary : AppColors.warning;

    return AccentCard(
      onTap: onTap,
      accentColor: _accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceVariant,
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
                    Text('${data['id']} · ${data['role']}', style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(color: scoreColor.withOpacity(0.1), borderRadius: BorderRadius.circular(7)),
                child: Text('$score%',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: scoreColor)),
              ),
            ],
          ),
          if (data['interviewTime'] != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.videocam_outlined, size: 15, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Text('Interview: ${data['interviewTime']}',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.warning)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('Applied ${data['appliedDate']}', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _ApplicantDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ApplicantDetailScreen({required this.data});

  @override
  Widget build(BuildContext context) {
    final isNew = data['status'] == 'new';
    final isInterview = data['status'] == 'interview';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Applicant profile',
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
                Text('${data['id']} · ${data['university']}', style: AppTextStyles.bodySecondary),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, size: 13, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text('${data['matchScore']}% match',
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Applied for', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.work_outline, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['role'],
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('Applied ${data['appliedDate']}', style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Documents', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('resume_${"tankai"}.pdf',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500)),
                ),
                TextButton(onPressed: () {}, child: const Text('View')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Cover letter', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Dear Hiring Manager, I am writing to express my interest in this internship position. I have hands-on experience with Flutter and Dart from coursework and personal projects...',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Skills', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Flutter', 'Dart', 'Firebase']
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(20)),
                      child: Text(s, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.primary)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          if (isNew) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12), side: const BorderSide(color: AppColors.error)),
                    child: const Text('Reject', style: TextStyle(color: AppColors.error)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showScheduleInterviewSheet(context),
                    icon: const Icon(Icons.videocam_outlined, size: 16),
                    label: const Text('Schedule Interview'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ],
            ),
          ] else if (isInterview) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.videocam_outlined, size: 18, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Interview scheduled: ${data['interviewTime']}',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.warning)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12), side: const BorderSide(color: AppColors.error)),
                    child: const Text('Reject', style: TextStyle(color: AppColors.error)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showScheduleInterviewSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => const _ScheduleInterviewSheet(),
    );
  }
}

class _ScheduleInterviewSheet extends StatefulWidget {
  const _ScheduleInterviewSheet();

  @override
  State<_ScheduleInterviewSheet> createState() => _ScheduleInterviewSheetState();
}

class _ScheduleInterviewSheetState extends State<_ScheduleInterviewSheet> {
  String _mode = 'Online';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Schedule interview', style: AppTextStyles.h3),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Date', style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextFormField(
            readOnly: true,
            decoration: const InputDecoration(hintText: 'Select date', suffixIcon: Icon(Icons.calendar_today_outlined, size: 18)),
            onTap: () {},
          ),
          const SizedBox(height: 12),
          const Text('Time', style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextFormField(
            readOnly: true,
            decoration: const InputDecoration(hintText: 'Select time', suffixIcon: Icon(Icons.access_time, size: 18)),
            onTap: () {},
          ),
          const SizedBox(height: 12),
          const Text('Interview mode', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ModeOption(
                  label: 'Online',
                  icon: Icons.videocam_outlined,
                  selected: _mode == 'Online',
                  onTap: () => setState(() => _mode = 'Online'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ModeOption(
                  label: 'In-person',
                  icon: Icons.business_outlined,
                  selected: _mode == 'In-person',
                  onTap: () => setState(() => _mode = 'In-person'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: InputDecoration(
              labelText: _mode == 'Online' ? 'Meeting link' : 'Location',
              hintText: _mode == 'Online' ? 'e.g. Zoom/Google Meet link' : 'Office address',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Confirm & notify applicant'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeOption({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.infoBg : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.primary : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
