import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/admin_data_service.dart';
import '../../services/auth_service.dart';
import '../../utils/format_utils.dart';
import '../admin_shell.dart';
import '../staff_profile_screen.dart';
import 'admin_companies_screen.dart';
import 'admin_students_screen.dart';
import 'admin_monitor_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  Map<String, int> _counts = const {};
  List<Map<String, dynamic>> _recentStudents = [];
  String? _name;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final profile = await AuthService.instance.getCurrentProfile();
      final resolvedAvatarUrl = profile?['avatar_url'] as String?;
      final counts = await AdminDataService.instance.getDashboardCounts();
      final recentStudents = await AdminDataService.instance.getRecentStudents();
      if (!mounted) return;
      setState(() {
        _name = profile?['full_name'] as String?;
        _avatarUrl = resolvedAvatarUrl;
        _counts = counts;
        _recentStudents = recentStudents;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 130,
              pinned: true,
              backgroundColor: AppColors.primary,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
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
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                    child: const CimsLogoMark(size: 26),
                                  ),
                                  const SizedBox(width: 10),
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('CIMS Admin',
                                          style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                                      Text('TARUMT', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.white70)),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffProfileScreen()));
                                      _load();
                                    },
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.white24,
                                      backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                                      onBackgroundImageError: _avatarUrl != null ? (_, __) {} : null,
                                      child: _avatarUrl == null
                                          ? Text(
                                              (_name?.isNotEmpty ?? false) ? logoLetter(_name!) : 'A',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  NotificationBell(count: 0, onTap: () {}),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text('Welcome back, ${(_name?.isNotEmpty ?? false) ? _name : 'Admin'}',
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
            else
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'System overview'),
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
                            label: 'Total students',
                            value: '${_counts['students'] ?? 0}',
                            icon: Icons.school_outlined,
                            color: AppColors.primary,
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminStudentsScreen()));
                              _load();
                            },
                          ),
                          MetricCard(
                            label: 'Active internships',
                            value: '${_counts['activeInternships'] ?? 0}',
                            icon: Icons.work_outline,
                            color: AppColors.success,
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMonitorScreen()));
                              _load();
                            },
                          ),
                          MetricCard(
                            label: 'Partner companies',
                            value: '${_counts['companies'] ?? 0}',
                            icon: Icons.business_outlined,
                            color: AppColors.primaryLight,
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCompaniesScreen()));
                              _load();
                            },
                          ),
                          MetricCard(
                            label: 'Pending reviews',
                            value: '${_counts['pendingReviews'] ?? 0}',
                            icon: Icons.pending_actions_outlined,
                            color: AppColors.warning,
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMonitorScreen()));
                              _load();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SectionHeader(title: 'Needs attention'),
                    if ((_counts['unassignedStudents'] ?? 0) == 0 && (_counts['pendingReviews'] ?? 0) == 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('All clear — nothing needs your attention right now.',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
                      ),
                    if ((_counts['unassignedStudents'] ?? 0) > 0)
                      AccentCard(
                        accentColor: AppColors.error,
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminStudentsScreen()));
                          _load();
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.report_problem_outlined, size: 18, color: AppColors.error),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${_counts['unassignedStudents']} students unassigned',
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                  Text('No academic supervisor assigned yet',
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
                          ],
                        ),
                      ),
                    if ((_counts['pendingReviews'] ?? 0) > 0)
                      AccentCard(
                        accentColor: AppColors.warning,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.assignment_late_outlined, size: 18, color: AppColors.warning),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${_counts['pendingReviews']} submissions pending review',
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                  Text('Awaiting supervisor or admin review',
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SectionHeader(title: 'Quick actions'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1,
                        children: [
                          _QuickAction(
                            icon: Icons.add_business_outlined,
                            label: 'Add Company',
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCompaniesScreen()));
                              _load();
                            },
                          ),
                          _QuickAction(
                            icon: Icons.link_outlined,
                            label: 'Assign Supervisor',
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminStudentsScreen()));
                              _load();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SectionHeader(title: 'Recently registered'),
                    if (_recentStudents.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('No students yet.', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
                      )
                    else
                      ..._recentStudents.map((s) => _ActivityItem(
                            icon: Icons.person_add_alt_outlined,
                            text: '${(s['full_name'] as String?)?.isNotEmpty == true ? s['full_name'] : 'Unnamed student'} registered',
                            time: timeAgo(DateTime.parse(s['created_at'] as String)),
                            color: AppColors.primary,
                          )),
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final String time;
  final Color color;

  const _ActivityItem({required this.icon, required this.text, required this.time, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(time, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
