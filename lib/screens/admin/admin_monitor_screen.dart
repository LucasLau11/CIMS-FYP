import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';

class AdminMonitorScreen extends StatefulWidget {
  const AdminMonitorScreen({super.key});

  @override
  State<AdminMonitorScreen> createState() => _AdminMonitorScreenState();
}

class _AdminMonitorScreenState extends State<AdminMonitorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: 'Monitor'),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Student progress'),
                Tab(text: 'Reports'),
                Tab(text: 'Documents'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _StudentProgressTab(),
                _ReportsReviewTab(),
                _DocumentsReviewTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentProgressTab extends StatelessWidget {
  const _StudentProgressTab();

  final List<Map<String, dynamic>> _students = const [
    {
      'name': 'Tan Kai Ming',
      'id': '22CSB12345',
      'company': 'Tencent Malaysia',
      'progress': 0.42,
      'status': 'On track',
      'initials': 'TK',
    },
    {
      'name': 'Priya Devi',
      'id': '22CSB09988',
      'company': 'CIMB Bank',
      'progress': 0.18,
      'status': 'At risk',
      'initials': 'PD',
    },
    {
      'name': 'Ahmad Hafiz',
      'id': '22CSB11223',
      'company': 'Grab Holdings',
      'progress': 0.75,
      'status': 'On track',
      'initials': 'AH',
    },
    {
      'name': 'Wong Jia Hui',
      'id': '21CSB05544',
      'company': 'Maxis Berhad',
      'progress': 1.0,
      'status': 'Completed',
      'initials': 'WJ',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: _students.length,
      itemBuilder: (_, i) {
        final s = _students[i];
        final color = s['status'] == 'At risk'
            ? AppColors.error
            : s['status'] == 'Completed'
                ? AppColors.textMuted
                : AppColors.success;
        return AccentCard(
          accentColor: color,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.surfaceVariant,
                    child: Text(s['initials'],
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['name'],
                            style: const TextStyle(
                                fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        Text('${s['id']} · ${s['company']}', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(s['status'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('Progress', style: AppTextStyles.caption),
                  const Spacer(),
                  Text('${(s['progress'] * 100).toInt()}%',
                      style: TextStyle(
                          fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: s['progress'],
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReportsReviewTab extends StatelessWidget {
  const _ReportsReviewTab();

  final List<Map<String, dynamic>> _reports = const [
    {
      'student': 'Tan Kai Ming',
      'title': 'Monthly Report — June 2026',
      'submittedDate': '28 Jun 2026',
      'supervisorStatus': 'Approved',
      'initials': 'TK',
    },
    {
      'student': 'Priya Devi',
      'title': 'Monthly Report — June 2026',
      'submittedDate': '29 Jun 2026',
      'supervisorStatus': 'Pending review',
      'initials': 'PD',
    },
    {
      'student': 'Ahmad Hafiz',
      'title': 'Monthly Report — May 2026',
      'submittedDate': '30 May 2026',
      'supervisorStatus': 'Approved',
      'initials': 'AH',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: _reports.length,
      itemBuilder: (_, i) {
        final r = _reports[i];
        final isPending = r['supervisorStatus'] == 'Pending review';
        return AccentCard(
          accentColor: isPending ? AppColors.warning : AppColors.success,
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.surfaceVariant,
                child: Text(r['initials'],
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['title'],
                        style: const TextStyle(
                            fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text('${r['student']} · Submitted ${r['submittedDate']}', style: AppTextStyles.caption),
                  ],
                ),
              ),
              isPending
                  ? StatusBadge.pending()
                  : StatusBadge.approved(),
            ],
          ),
        );
      },
    );
  }
}

class _DocumentsReviewTab extends StatelessWidget {
  const _DocumentsReviewTab();

  final List<Map<String, dynamic>> _documents = const [
    {
      'student': 'Lee Mei Ling',
      'title': 'Offer Letter',
      'uploadedDate': '25 Jun 2026',
      'status': 'Pending review',
      'initials': 'LM',
    },
    {
      'student': 'Tan Kai Ming',
      'title': 'Industrial Training Form (LI01)',
      'uploadedDate': '20 Jun 2026',
      'status': 'Approved',
      'initials': 'TK',
    },
    {
      'student': 'Priya Devi',
      'title': 'Parent Acknowledgement Form',
      'uploadedDate': '18 Jun 2026',
      'status': 'Rejected',
      'initials': 'PD',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: _documents.length,
      itemBuilder: (_, i) {
        final d = _documents[i];
        Color color = d['status'] == 'Pending review'
            ? AppColors.warning
            : d['status'] == 'Rejected'
                ? AppColors.error
                : AppColors.success;
        return AccentCard(
          accentColor: color,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.surfaceVariant,
                    child: Text(d['initials'],
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['title'],
                            style: const TextStyle(
                                fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        Text('${d['student']} · ${d['uploadedDate']}', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(d['status'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                  ),
                ],
              ),
              if (d['status'] == 'Pending review') ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            side: const BorderSide(color: AppColors.error)),
                        child: const Text('Reject', style: TextStyle(fontSize: 12, color: AppColors.error)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                        child: const Text('Approve', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
