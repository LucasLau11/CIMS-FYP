import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/student_data_service.dart';
import '../../utils/format_utils.dart';
import '../../services/auth_service.dart';
import '../../services/hr_data_service.dart';
import '../hr/hr_applicants_screen.dart';
import 'student_interview_screen.dart';
import '../../services/push_notification_service.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  State<StudentNotificationsScreen> createState() => _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState extends State<StudentNotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  bool _pushAllowed = true;

  @override
  void initState() {
    super.initState();
    _pushAllowed = PushNotificationService.instance.notificationsAllowed;
    _load();
  }

  Future<void> _turnOnPush() async {
    final allowed = await PushNotificationService.instance.enableNotifications();
    if (mounted) setState(() => _pushAllowed = allowed);
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

  bool _isInterviewNotification(Map<String, dynamic> n) {
    final title = (n['title'] as String?) ?? '';
    return n['type'] == 'interview_request' || n['type'] == 'interview_reminder' || title.startsWith('Interview') || title.startsWith('Reschedule');
  }

  /// A tap marks the notification read and, for interview news (a reschedule
  /// request to accept or decline, an interview booked or cancelled), opens
  /// that interview so the person can act on it.
  Future<void> _open(Map<String, dynamic> n) async {
    await _markRead(n);
    final applicationId = n['related_id'] as String?;
    if (!_isInterviewNotification(n) || applicationId == null) return;
    try {
      final profile = await AuthService.instance.getCurrentProfile();
      final role = profile?['role'] as String?;
      if (role == 'student') {
        final apps = await StudentDataService.instance.getMyApplications();
        final application = apps.where((a) => a['id'] == applicationId).toList();
        if (application.isEmpty || !mounted) return;
        await Navigator.push(context, MaterialPageRoute(builder: (_) => StudentInterviewScreen(application: application.first)));
      } else if (role == 'company_hr') {
        final applicants = await HrDataService.instance.getApplicants();
        final applicant = applicants.where((a) => a['id'] == applicationId).toList();
        if (applicant.isEmpty || !mounted) return;
        await Navigator.push(context, MaterialPageRoute(builder: (_) => ApplicantDetailScreen(data: applicant.first)));
      }
      if (mounted) _load();
    } catch (_) {
      // Not fatal: the notification itself was already shown and marked read.
    }
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
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                        if (!_pushAllowed) _PushOffBanner(onTurnOn: _turnOnPush),
                        if (unread.isNotEmpty) ...[
                          SectionHeader(title: l10n.newLabel),
                          ...unread.map((n) => _NotificationCard(data: n, onTap: () => _open(n))),
                        ],
                        if (read.isNotEmpty) ...[
                          SectionHeader(title: l10n.earlier),
                          ...read.map((n) => _NotificationCard(data: n, onTap: _isInterviewNotification(n) ? () => _open(n) : () {})),
                        ],
                      ],
                    ),
            ),
    );
  }
}

/// Shown when the phone blocks CIMS notifications: the alerts still arrive in
/// this list but nothing appears outside the app until they are allowed.
class _PushOffBanner extends StatelessWidget {
  final VoidCallback onTurnOn;

  const _PushOffBanner({required this.onTurnOn});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_off_outlined, size: 18, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(AppLocalizations.of(context)!.pushOffTitle,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.warning)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.pushOffBody,
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.4, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: onTurnOn, child: Text(AppLocalizations.of(context)!.pushTurnOn)),
        ],
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
                          decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
