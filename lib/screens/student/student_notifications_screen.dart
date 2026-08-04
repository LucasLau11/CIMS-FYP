import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
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

  Future<void> _respondToParentLink(Map<String, dynamic> notification, bool approve) async {
    await StudentDataService.instance.respondToParentLinkRequest(
      requestId: notification['related_id'] as String,
      approve: approve,
    );
    await StudentDataService.instance.markNotificationRead(notification['id'] as String);
    if (!mounted) return;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unread = _notifications.where((n) => n['read'] == false).toList();
    final read = _notifications.where((n) => n['read'] == true).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: l10n.notifications,
        actions: [
          if (unread.isNotEmpty)
            TextButton(
              onPressed: _markAllRead,
              child: Text(l10n.markAllRead, style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Inter')),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: _notifications.isEmpty
                  ? ListView(
                      children: [
                        EmptyState(
                          icon: Icons.notifications_none,
                          title: l10n.noNotificationsYet,
                          description: l10n.notificationsEmptyDescription,
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        if (unread.isNotEmpty) ...[
                          SectionHeader(title: l10n.newLabel),
                          ...unread.map((n) => _NotificationCard(
                                data: n,
                                onTap: () => _markRead(n),
                                onRespond: n['type'] == 'parent_link' ? (approve) => _respondToParentLink(n, approve) : null,
                              )),
                        ],
                        if (read.isNotEmpty) ...[
                          SectionHeader(title: l10n.earlier),
                          ...read.map((n) => _NotificationCard(data: n, onTap: () {})),
                        ],
                      ],
                    ),
            ),
    );
  }
}

class _NotificationCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final Future<void> Function(bool approve)? onRespond;

  const _NotificationCard({required this.data, required this.onTap, this.onRespond});

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool _isResponding = false;

  Future<void> _respond(bool approve) async {
    setState(() => _isResponding = true);
    try {
      await widget.onRespond!(approve);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isResponding = false);
      final l10n = AppLocalizations.of(context)!;
      final message = e.toString().contains('parent_child_links_one_approved_per_student')
          ? l10n.errorParentAlreadyLinked
          : l10n.errorCouldNotRespondToRequest(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.error));
      return;
    }
    if (!mounted) return;
    setState(() => _isResponding = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = widget.data;
    final isUnread = data['read'] == false;
    final type = data['type'] as String;
    final createdAt = DateTime.parse(data['created_at'] as String);
    final showLinkActions = widget.onRespond != null && isUnread;

    return GestureDetector(
      onTap: widget.onTap,
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
                  Text(timeAgo(context, createdAt), style: AppTextStyles.caption),
                  if (showLinkActions) ...[
                    const SizedBox(height: 10),
                    _isResponding
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        : Row(
                            children: [
                              OutlinedButton(
                                onPressed: () => _respond(false),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  minimumSize: Size.zero,
                                  foregroundColor: AppColors.error,
                                  side: BorderSide(color: AppColors.error),
                                ),
                                child: Text(l10n.notificationReject, style: const TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _respond(true),
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), minimumSize: Size.zero),
                                child: Text(l10n.notificationApprove, style: const TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
