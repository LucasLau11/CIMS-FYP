import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../utils/format_utils.dart';

/// Shows the scheduled interview for one application and lets the student
/// join it. There's no embedded video calling here — HR schedules either an
/// "online" interview (a meeting link the student opens externally) or an
/// "in_person" one (an address), matching how HR's schedule-interview sheet
/// captures the detail.
class StudentInterviewScreen extends StatelessWidget {
  final Map<String, dynamic> application;

  const StudentInterviewScreen({super.key, required this.application});

  @override
  Widget build(BuildContext context) {
    final internship = application['internships'] as Map;
    final companyName = internship['company_name'] as String;
    final interviewAt = application['interview_at'] != null ? DateTime.parse(application['interview_at'] as String) : null;
    final mode = application['interview_mode'] as String?;
    final location = application['interview_location'] as String?;
    final isOnline = mode == 'online';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Interview', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: nameColor(companyName).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text(logoLetter(companyName),
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: nameColor(companyName))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(internship['title'] as String, style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text(companyName, style: AppTextStyles.bodySecondary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (interviewAt == null)
            const EmptyState(icon: Icons.event_busy_outlined, title: 'No interview scheduled', description: 'You will be notified once the company schedules your interview.')
          else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0D6E78), Color(0xFF14B8C8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(isOnline ? Icons.videocam_outlined : Icons.business_outlined, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(isOnline ? 'Online interview' : 'In-person interview',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('${_weekday(interviewAt.weekday)}, ${interviewAt.day} ${_month(interviewAt.month)} ${interviewAt.year}',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white70)),
                  Text(_formatTime(interviewAt), style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (location != null && location.isNotEmpty) ...[
              Text(isOnline ? 'Meeting link' : 'Location', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                child: Text(location, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 20),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (isOnline && location != null && location.isNotEmpty) ? () => _join(context, location) : null,
                icon: const Icon(Icons.videocam_outlined, size: 18),
                label: Text(isOnline ? 'Join interview' : 'Directions unavailable — see address above'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
            if (!isOnline)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('This is an in-person interview — no online join link is needed.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted), textAlign: TextAlign.center),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _join(BuildContext context, String link) async {
    final uri = Uri.tryParse(link.startsWith('http') ? link : 'https://$link');
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Could not open the meeting link.'), backgroundColor: AppColors.error));
    }
  }

  String _weekday(int d) => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1];
  String _month(int m) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];
  String _formatTime(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
