import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/parent_data_service.dart';
import '../../utils/format_utils.dart';

class ParentProgressScreen extends StatefulWidget {
  final Map<String, dynamic> child;
  final Map<String, dynamic>? application;

  const ParentProgressScreen({super.key, required this.child, required this.application});

  @override
  State<ParentProgressScreen> createState() => _ParentProgressScreenState();
}

class _ParentProgressScreenState extends State<ParentProgressScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final reports = await ParentDataService.instance.getChildReports(widget.child['id'] as String);
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.child['full_name'] as String?)?.isNotEmpty == true ? widget.child['full_name'] as String : 'Unnamed student';
    final internship = widget.application?['internships'] as Map?;
    final companyName = internship?['company_name'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Internship Progress', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0D6E78), Color(0xFF14B8C8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white24,
                        child: Text(logoLetter(name), style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                            Text(companyName ?? 'No active internship', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Internship journey', style: AppTextStyles.h3),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: ProgressStepper(
                    steps: const ['Applied', 'Accepted', 'Ongoing', 'Completed'],
                    currentStep: widget.application == null ? 0 : 2,
                  ),
                ),
                const SizedBox(height: 20),
                Text('At a glance', style: AppTextStyles.h3),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.5,
                  children: [
                    MetricCard(label: 'Reports submitted', value: '${_reports.length}', icon: Icons.assignment_turned_in_outlined, color: AppColors.success),
                    MetricCard(
                        label: 'Duration',
                        value: internship?['duration_months'] != null ? formatDuration(internship!['duration_months'] as int) : '—',
                        icon: Icons.timer_outlined,
                        color: AppColors.primaryLight),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Report submissions', style: AppTextStyles.h3),
                const SizedBox(height: 10),
                if (_reports.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('No reports submitted yet.', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
                  )
                else
                  ..._reports.map((r) => _ReportStatusRow(
                        title: '${r['type'] == 'final' ? 'Final Report' : 'Monthly Report'} — ${r['period_label']}',
                        date: 'Submitted ${timeAgo(DateTime.parse(r['submitted_at'] as String))}',
                        status: r['status'] as String,
                      )),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline, size: 16, color: AppColors.textMuted),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This is a read-only view. Contact the university for queries regarding your child\'s internship.',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted),
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

  const _ReportStatusRow({required this.title, required this.date, required this.status});

  Color get _accentColor {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  StatusBadge get _badge {
    switch (status) {
      case 'approved':
        return StatusBadge.approved();
      case 'rejected':
        return StatusBadge.rejected();
      default:
        return StatusBadge.pending();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccentCard(
      accentColor: _accentColor,
      child: Row(
        children: [
          Icon(Icons.assignment_outlined, size: 18, color: _accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
