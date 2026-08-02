import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/hr_data_service.dart';
import '../../services/student_data_service.dart';
import '../../services/auth_service.dart';
import '../../services/company_service.dart';
import '../../utils/format_utils.dart';
import '../staff_profile_screen.dart';
import '../student/student_notifications_screen.dart';
import 'hr_postings_screen.dart';
import 'hr_applicants_screen.dart' show HrApplicantsScreen, ApplicantDetailScreen;

class HrDashboardScreen extends StatefulWidget {
  const HrDashboardScreen({super.key});

  @override
  State<HrDashboardScreen> createState() => _HrDashboardScreenState();
}

class _HrDashboardScreenState extends State<HrDashboardScreen> {
  bool _isLoading = true;
  Map<String, int> _counts = {};
  int _unreadNotifications = 0;
  String _name = '';
  String? _avatarUrl;
  String? _companyName;
  List<Map<String, dynamic>> _upcomingInterviews = [];

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
      final company = await CompanyService.instance.getMyCompany();
      final counts = await HrDataService.instance.getDashboardCounts();
      final unread = await StudentDataService.instance.getUnreadNotificationCount();
      final applicants = await HrDataService.instance.getApplicants();
      final interviews = applicants.where((a) => a['status'] == 'interview' && a['interview_at'] != null).toList()
        ..sort((a, b) => (a['interview_at'] as String).compareTo(b['interview_at'] as String));
      if (!mounted) return;
      setState(() {
        _name = (profile?['full_name'] as String?)?.isNotEmpty == true ? profile!['full_name'] as String : '';
        _avatarUrl = resolvedAvatarUrl;
        _companyName = company?['name'] as String?;
        _counts = counts;
        _unreadNotifications = unread;
        _upcomingInterviews = interviews.take(3).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayName = _name.isNotEmpty ? _name : l10n.hrPersonnelLabel;
    final companyLabel = _companyName != null ? '${l10n.hrPersonnelLabel} · $_companyName' : l10n.hrPersonnelLabel;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              backgroundColor: AppColors.primary,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [AppColors.primary, AppColors.primaryLight]),
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
                                          _name.isNotEmpty ? logoLetter(_name) : '👤',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                                        )
                                      : null,
                                ),
                              ),
                              NotificationBell(
                                count: _unreadNotifications,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentNotificationsScreen())),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(displayName, style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                          Text(companyLabel, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white70)),
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
                    SectionHeader(title: l10n.hrRecruitmentOverview),
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
                            label: l10n.hrActivePostings,
                            value: '${_counts['activePostings'] ?? 0}',
                            icon: Icons.work_outline,
                            color: AppColors.primary,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HrPostingsScreen())).then((_) => _load()),
                          ),
                          MetricCard(
                            label: l10n.hrNewApplicants,
                            value: '${_counts['newApplicants'] ?? 0}',
                            icon: Icons.person_add_alt_outlined,
                            color: AppColors.warning,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HrApplicantsScreen())).then((_) => _load()),
                          ),
                          MetricCard(
                            label: l10n.hrInterviewsPending,
                            value: '${_counts['interviews'] ?? 0}',
                            icon: Icons.videocam_outlined,
                            color: AppColors.primaryLight,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HrApplicantsScreen())).then((_) => _load()),
                          ),
                          MetricCard(
                            label: l10n.hrCurrentInterns,
                            value: '${_counts['interns'] ?? 0}',
                            icon: Icons.badge_outlined,
                            color: AppColors.success,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HrApplicantsScreen())).then((_) => _load()),
                          ),
                        ],
                      ),
                    ),
                    SectionHeader(title: l10n.hrUpcomingInterviews),
                    if (_upcomingInterviews.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(l10n.hrNoInterviewsScheduled, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
                      )
                    else
                      ..._upcomingInterviews.map((a) => AccentCard(
                            accentColor: AppColors.primaryLight,
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => ApplicantDetailScreen(data: a)));
                              _load();
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.surfaceVariant,
                                  child: Text(logoLetter(a['student_name'] as String), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(a['student_name'] as String, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                      Text((a['internship_title'] as String?) ?? '', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(6)),
                                  child: Text(timeAgo(DateTime.parse(a['interview_at'] as String)),
                                      style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                ),
                              ],
                            ),
                          )),
                    SectionHeader(title: l10n.quickActions),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.add_box_outlined,
                              label: l10n.hrNewPosting,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HrPostingsScreen())).then((_) => _load()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.fact_check_outlined,
                              label: l10n.hrReviewApplicants,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HrApplicantsScreen())).then((_) => _load()),
                            ),
                          ),
                        ],
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
