import 'dart:io';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/student_data_service.dart';
import '../../utils/format_utils.dart';
import 'student_applications_screen.dart';
import 'student_reports_screen.dart';
import 'student_messages_screen.dart';
import 'student_notifications_screen.dart';
import 'student_profile_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  String? _name;
  String? _avatarUrl;
  String? _programme;
  int? _semester;

  bool _isLoading = true;
  Map<String, int> _counts = const {
    'applications': 0,
    'interviews': 0,
    'reports': 0,
    'unreadNotifications': 0,
    'unreadMessages': 0,
  };
  List<Map<String, dynamic>> _recentNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadProfile(), _loadDashboardData()]);
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AuthService.instance.getCurrentProfile();
      if (!mounted) return;
      final resolvedAvatarUrl =
          await AuthService.instance.resolveAvatarPath(profile?['avatar_url'] as String?);
      if (!mounted) return;
      setState(() {
        _name = profile?['full_name'] as String?;
        _avatarUrl = resolvedAvatarUrl;
        _programme = profile?['programme'] as String?;
        _semester = (profile?['semester'] as num?)?.toInt();
      });
    } catch (_) {
      // Non-fatal — dashboard still works with placeholder text.
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      final counts = await StudentDataService.instance.getDashboardCounts();
      final notifications = await StudentDataService.instance.getNotifications();
      if (!mounted) return;
      setState(() {
        _counts = counts;
        _recentNotifications = notifications.take(4).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String get _programmeSemesterLine {
    final programme = _programme ?? 'Programme not set';
    final semesterPart = _semester != null ? ' · Sem $_semester' : '';
    return '$programme$semesterPart';
  }

  String get _initials {
    if (_name == null || _name!.trim().isEmpty) return '👤';
    final parts = _name!.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: CustomScrollView(
          slivers: [
            // Gradient header with wave
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                // No animated `title` here — it collapses to overlap the
                // custom header content below instead of fading in behind
                // it, which read as "Dashboard" and "Programme · Sem"
                // being jammed together with no gap.
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => const StudentProfileScreen()));
                                  _loadAll();
                                },
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.white24,
                                  backgroundImage: _avatarUrl != null ? FileImage(File(_avatarUrl!)) : null,
                                  onBackgroundImageError: _avatarUrl != null ? (_, __) {} : null,
                                  child: _avatarUrl == null
                                      ? Text(_initials,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14))
                                      : null,
                                ),
                              ),
                              NotificationBell(
                                count: _counts['unreadNotifications'] ?? 0,
                                onTap: () async {
                                  await Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => const StudentNotificationsScreen()));
                                  _loadDashboardData();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.goodMorning(_name?.isNotEmpty == true ? _name! : ''),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _programmeSemesterLine,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: const [],
            ),

            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Metric grid
                    SectionHeader(title: l10n.overview),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.1,
                        children: [
                          MetricCard(
                            label: 'Applications sent',
                            value: '${_counts['applications'] ?? 0}',
                            icon: Icons.send_outlined,
                            color: AppColors.primary,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentApplicationsScreen())),
                          ),
                          MetricCard(
                            label: 'Interviews scheduled',
                            value: '${_counts['interviews'] ?? 0}',
                            icon: Icons.calendar_today_outlined,
                            color: AppColors.warning,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentApplicationsScreen())),
                          ),
                          MetricCard(
                            label: 'Reports submitted',
                            value: '${_counts['reports'] ?? 0}',
                            icon: Icons.assignment_turned_in_outlined,
                            color: AppColors.success,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentReportsScreen())),
                          ),
                          MetricCard(
                            label: 'Unread messages',
                            value: '${_counts['unreadMessages'] ?? 0}',
                            icon: Icons.chat_bubble_outline,
                            color: AppColors.primaryLight,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentMessagesScreen())),
                          ),
                        ],
                      ),
                    ),

                    // Recent activity
                    SectionHeader(
                      title: 'Recent activity',
                      actionLabel: l10n.viewAll,
                      onAction: () async {
                        await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const StudentNotificationsScreen()));
                        _loadDashboardData();
                      },
                    ),
                    if (_recentNotifications.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Nothing here yet — apply to an internship or submit a report to get started.',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary),
                        ),
                      )
                    else
                      ..._recentNotifications.map((n) => _RecentActivityTile(data: n)),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const _RecentActivityTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final type = data['type'] as String;
    final createdAt = DateTime.parse(data['created_at'] as String);

    return AccentCard(
      accentColor: notificationColor(type),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(notificationIcon(type), size: 18, color: notificationColor(type)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'] as String,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                if ((data['body'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(data['body'] as String,
                      style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(timeAgo(createdAt), style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
