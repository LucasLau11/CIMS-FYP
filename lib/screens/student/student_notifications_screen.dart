import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/student_data_service.dart';
import '../../utils/format_utils.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  State<StudentNotificationsScreen> createState() => _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState extends State<StudentNotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await StudentDataService.instance.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    await StudentDataService.instance.markAllNotificationsRead();
    _load();
  }

  Future<void> _markRead(Map<String, dynamic> notification) async {
    if (notification['read'] == true) return;
    await StudentDataService.instance.markNotificationRead(notification['id'] as String);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => n['read'] == false).toList();
    final read = _notifications.where((n) => n['read'] == true).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: 'Notifications',
        actions: [
          if (unread.isNotEmpty)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read', style: TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Inter')),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: _notifications.isEmpty
                  ? ListView(
                      children: const [
                        EmptyState(
                          icon: Icons.notifications_none,
                          title: 'No notifications yet',
                          description: 'Updates about your applications, reports, and messages will show up here.',
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        if (unread.isNotEmpty) ...[
                          const SectionHeader(title: 'New'),
                          ...unread.map((n) => _NotificationCard(data: n, onTap: () => _markRead(n))),
                        ],
                        if (read.isNotEmpty) ...[
                          const SectionHeader(title: 'Earlier'),
                          ...read.map((n) => _NotificationCard(data: n, onTap: () {})),
                        ],
                      ],
                    ),
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _NotificationCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = data['read'] == false;
    final type = data['type'] as String;
    final createdAt = DateTime.parse(data['created_at'] as String);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.infoBg : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isUnread ? AppColors.primaryLight.withOpacity(0.4) : AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: notificationColor(type).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(notificationIcon(type), size: 18, color: notificationColor(type)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(data['title'] as String,
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  if ((data['body'] as String?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(data['body'] as String,
                        style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                  ],
                  const SizedBox(height: 6),
                  Text(timeAgo(createdAt), style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
