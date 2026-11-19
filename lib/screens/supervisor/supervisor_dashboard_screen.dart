import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/student_data_service.dart';
import '../../services/supervisor_data_service.dart';
import '../../utils/format_utils.dart';
import '../../utils/lang.dart';
import 'supervisor_intakes_screen.dart';
import '../staff_profile_screen.dart';
import 'supervisor_messages_screen.dart';
import 'supervisor_reviews_screen.dart';
import 'supervisor_students_screen.dart' show SupervisorStudentsScreen, StudentDetailScreen;
import '../../theme/role_theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/common/flex_grid.dart';

class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  State<SupervisorDashboardScreen> createState() => _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen> {
  bool _isLoading = true;
  String? _name;
  String? _avatarUrl;
  String? _faculty;
  int _unreadNotifications = 0;
  Map<String, int> _counts = const {'students': 0, 'pendingReviews': 0, 'approvedThisMonth': 0};
  int _unreadMessages = 0;
  List<Map<String, dynamic>> _pendingItems = [];
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    // Profile fields (name/avatar/faculty) are applied in their own
    // try/catch, separate from the dashboard-stats calls below — a failure
    // fetching counts/reviews/students must never discard profile data that
    // was already fetched successfully (e.g. a freshly-uploaded avatar
    // silently failing to appear because getStudents() hiccupped).
    try {
      final profile = await AuthService.instance.getCurrentProfile();
      if (!mounted) return;
      setState(() {
        _name = profile?['full_name'] as String?;
        _avatarUrl = profile?['avatar_url'] as String?;
        _faculty = profile?['faculty'] as String?;
      });
    } catch (_) {
      // Non-fatal — keep whatever profile data was already displayed.
    }

    try {
      final counts = await SupervisorDataService.instance.getDashboardCounts();
      final unreadNotifications = await StudentDataService.instance.getUnreadNotificationCount();
      final unreadMessages = await StudentDataService.instance.getUnreadMessageCount();
      final allReviews = await SupervisorDataService.instance.getAllReviewItems();
      final students = await SupervisorDataService.instance.getStudents();
      if (!mounted) return;
      setState(() {
        _counts = counts;
        _unreadNotifications = unreadNotifications;
        _unreadMessages = unreadMessages;
        _pendingItems = allReviews.where((r) => r['status'] == 'submitted').take(3).toList();
        _students = students.take(8).toList();
      });
    } catch (_) {
      // Non-fatal — keep whatever stats were already displayed.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: scaledExtent(context, 140),
              pinned: true,
              backgroundColor: AppColors.primary,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: RoleHeaderBackground(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffProfileScreen()));
                                  _load();
                                },
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.white24,
                                  backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                                  onBackgroundImageError: _avatarUrl != null ? (_, __) {} : null,
                                  child: _avatarUrl == null
                                      ? Text(
                                          _name?.isNotEmpty == true ? logoLetter(_name!) : '👤',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                                        )
                                      : null,
                                ),
                              ),
                              NotificationBell(count: _unreadNotifications, onTap: () {}),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(_name?.isNotEmpty == true ? _name! : l10n.academicSupervisor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                          Text(
                            _faculty?.isNotEmpty == true ? '${l10n.academicSupervisor} · $_faculty' : l10n.academicSupervisor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: kOnBannerSoft),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
            else
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(title: l10n.overview),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FlexGrid(columns: 2, minColumnWidth: 110, children: [
                          MetricCard(
                            label: l10n.supAssignedStudents,
                            value: '${_counts['students'] ?? 0}',
                            icon: Icons.people_outline,
                            color: AppColors.primary,
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SupervisorStudentsScreen()));
                              _load();
                            },
                          ),
                          MetricCard(
                            label: l10n.supPendingReviews,
                            value: '${_counts['pendingReviews'] ?? 0}',
                            icon: Icons.pending_actions_outlined,
                            color: AppColors.warning,
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SupervisorReviewsScreen()));
                              _load();
                            },
                          ),
                          MetricCard(
                            label: l10n.supApprovedThisMonth,
                            value: '${_counts['approvedThisMonth'] ?? 0}',
                            icon: Icons.check_circle_outline,
                            color: AppColors.success,
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SupervisorReviewsScreen()));
                              _load();
                            },
                          ),
                          MetricCard(
                            label: l10n.supUnreadMessages,
                            value: '$_unreadMessages',
                            icon: Icons.chat_bubble_outline,
                            color: AppColors.primaryLight,
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SupervisorMessagesScreen()));
                              _load();
                            },
                          ),
                        ],
                      ),
                    ),
                    AccentCard(
                      accentColor: AppColors.primary,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupervisorIntakesScreen())),
                      child: Row(
                        children: [
                          Icon(Icons.groups_outlined, color: AppColors.primaryText),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(tr('Intakes and grades', ms: 'Pengambilan dan gred', zh: '实习批次与成绩'),
                                style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          ),
                          Icon(Icons.chevron_right, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                    SectionHeader(
                      title: l10n.supPendingYourReview,
                      actionLabel: l10n.viewAll,
                      onAction: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const SupervisorReviewsScreen()));
                        _load();
                      },
                    ),
                    if (_pendingItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(l10n.supNothingPendingReview,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
                      )
                    else
                      ..._pendingItems.map((item) => AccentCard(
                            accentColor: AppColors.warning,
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SupervisorReviewsScreen()));
                              _load();
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.surfaceVariant,
                                  child: Text(logoLetter(item['student_name'] as String),
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['title'] as String,
                                          style: TextStyle(
                                              fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                      Text(
                                          l10n.supSubmittedAgo('${item['student_name']} · ${timeAgo(context, DateTime.parse(item['submitted_at'] as String))}'),
                                          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                StatusBadge.pending(context),
                              ],
                            ),
                          )),
                    SectionHeader(
                      title: l10n.supMyStudents,
                      actionLabel: l10n.viewAll,
                      onAction: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const SupervisorStudentsScreen()));
                        _load();
                      },
                    ),
                    if (_students.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(l10n.supNoStudentsYet, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          height: scaledExtent(context, 118),
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _students
                                .map((s) => _StudentAvatarTile(
                                      name: (s['full_name'] as String?)?.isNotEmpty == true ? s['full_name'] as String : 'Unnamed',
                                      pendingCount: s['pending_review_count'] as int,
                                      onTap: () async {
                                        await Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(studentId: s['id'] as String)));
                                        _load();
                                      },
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
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

class _StudentAvatarTile extends StatelessWidget {
  final String name;
  final int pendingCount;
  final VoidCallback onTap;

  const _StudentAvatarTile({required this.name, required this.pendingCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 78,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.infoBg,
              child: Text(logoLetter(name), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
            ),
            const SizedBox(height: 6),
            Text(name,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              pendingCount > 0 ? l10n.supPendingCount(pendingCount) : l10n.supUpToDate,
              style: TextStyle(
                  fontFamily: 'Inter', fontSize: 9, color: pendingCount > 0 ? AppColors.warning : AppColors.success),
            ),
          ],
        ),
      ),
    );
  }
}
