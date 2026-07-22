import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  State<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState
    extends State<StudentNotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Report deadline approaching',
      'body': 'Your June monthly report is due in 2 days. Submit it before 30 Jun 2026.',
      'time': '2 hours ago',
      'type': 'deadline',
      'read': false,
    },
    {
      'title': 'Report approved',
      'body': 'Dr. Lim Wei Shan has approved your May 2026 monthly report.',
      'time': '1 day ago',
      'type': 'approval',
      'read': false,
    },
    {
      'title': 'Interview scheduled',
      'body': 'Grab has scheduled an interview with you on 5 Jul 2026 at 10:00 AM.',
      'time': '2 days ago',
      'type': 'interview',
      'read': false,
    },
    {
      'title': 'New message',
      'body': 'Ahmad Faris sent you a message: "Good work on the sprint."',
      'time': '3 days ago',
      'type': 'message',
      'read': true,
    },
    {
      'title': 'Document approved',
      'body': 'Your offer letter has been approved by the academic supervisor.',
      'time': '5 days ago',
      'type': 'approval',
      'read': true,
    },
    {
      'title': 'Application status updated',
      'body': 'Your application to Shopee has been reviewed.',
      'time': '1 week ago',
      'type': 'application',
      'read': true,
    },
    {
      'title': 'System maintenance',
      'body': 'The system will undergo scheduled maintenance on 5 Jul 2026, 12:00–2:00 AM.',
      'time': '1 week ago',
      'type': 'system',
      'read': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => n['read'] == false).toList();
    final read = _notifications.where((n) => n['read'] == true).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: 'Notifications',
        actions: [
          TextButton(
            onPressed: () => setState(() {
              for (final n in _notifications) {
                n['read'] = true;
              }
            }),
            child: const Text('Mark all read',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: 'Inter')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (unread.isNotEmpty) ...[
            const SectionHeader(title: 'New'),
            ...unread.map((n) => _NotificationCard(
                  data: n,
                  onTap: () => setState(() => n['read'] = true),
                )),
          ],
          if (read.isNotEmpty) ...[
            const SectionHeader(title: 'Earlier'),
            ...read.map((n) => _NotificationCard(data: n, onTap: () {})),
          ],
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _NotificationCard({required this.data, required this.onTap});

  IconData get _icon {
    switch (data['type']) {
      case 'deadline': return Icons.timer_outlined;
      case 'approval': return Icons.check_circle_outline;
      case 'interview': return Icons.videocam_outlined;
      case 'message': return Icons.chat_bubble_outline;
      case 'application': return Icons.work_outline;
      default: return Icons.info_outline;
    }
  }

  Color get _iconColor {
    switch (data['type']) {
      case 'deadline': return AppColors.error;
      case 'approval': return AppColors.success;
      case 'interview': return AppColors.warning;
      case 'message': return AppColors.primary;
      case 'application': return AppColors.primaryLight;
      default: return AppColors.textSecondary;
    }
  }

  Color get _iconBg {
    switch (data['type']) {
      case 'deadline': return AppColors.errorBg;
      case 'approval': return AppColors.successBg;
      case 'interview': return AppColors.warningBg;
      case 'message': return AppColors.infoBg;
      case 'application': return AppColors.surfaceVariant;
      default: return AppColors.surfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = data['read'] == false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.infoBg : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread ? AppColors.primaryLight.withOpacity(0.4) : AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, size: 18, color: _iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(data['title'],
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(data['body'],
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4)),
                  const SizedBox(height: 6),
                  Text(data['time'], style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
