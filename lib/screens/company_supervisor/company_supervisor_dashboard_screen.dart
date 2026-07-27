import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/company_supervisor_data_service.dart';
import '../../services/student_data_service.dart';
import '../../services/auth_service.dart';
import '../../services/company_service.dart';
import '../../utils/format_utils.dart';
import '../staff_profile_screen.dart';
import '../student/student_notifications_screen.dart';
import 'company_supervisor_reviews_screen.dart';
import 'company_supervisor_students_screen.dart';

class CompanySupervisorDashboardScreen extends StatefulWidget {
  const CompanySupervisorDashboardScreen({super.key});

  @override
  State<CompanySupervisorDashboardScreen> createState() => _CompanySupervisorDashboardScreenState();
}

class _CompanySupervisorDashboardScreenState extends State<CompanySupervisorDashboardScreen> {
  bool _isLoading = true;
  String _name = '';
  String? _companyName;
  int _unreadNotifications = 0;
  Map<String, int> _counts = {};
  List<Map<String, dynamic>> _pendingReviews = [];
  List<Map<String, dynamic>> _interns = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final profile = await AuthService.instance.getCurrentProfile();
      final company = await CompanyService.instance.getMyCompany();
      final counts = await CompanySupervisorDataService.instance.getDashboardCounts();
      final unread = await StudentDataService.instance.getUnreadNotificationCount();
      final reviewItems = await CompanySupervisorDataService.instance.getReviewItems();
      final interns = await CompanySupervisorDataService.instance.getInterns();
      if (!mounted) return;
      setState(() {
        _name = (profile?['full_name'] as String?)?.isNotEmpty == true ? profile!['full_name'] as String : '';
        _companyName = company?['name'] as String?;
        _counts = counts;
        _unreadNotifications = unread;
        _pendingReviews = reviewItems.where((i) => i['status'] == 'submitted').take(3).toList();
        _interns = interns;
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
    final displayName = _name.isNotEmpty ? _name : l10n.companySupervisor;
    final companyLabel = _companyName != null ? '${l10n.companySupervisor} · $_companyName' : l10n.companySupervisor;

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
                                  child: Text(
                                    _name.isNotEmpty ? logoLetter(_name) : '👤',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
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
                            label: l10n.csCurrentInterns,
                            value: '${_counts['interns'] ?? 0}',
                            icon: Icons.badge_outlined,
                            color: AppColors.primary,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanySupervisorStudentsScreen())).then((_) => _load()),
                          ),
                          MetricCard(
                            label: l10n.csReportsToReview,
                            value: '${_counts['pendingReviews'] ?? 0}',
                            icon: Icons.pending_actions_outlined,
                            color: AppColors.warning,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanySupervisorReviewsScreen())).then((_) => _load()),
                          ),
                          MetricCard(
                            label: l10n.csApprovedThisMonth,
                            value: '${_counts['approvedThisMonth'] ?? 0}',
                            icon: Icons.check_circle_outline,
                            color: AppColors.success,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanySupervisorReviewsScreen())).then((_) => _load()),
                          ),
                          MetricCard(
                            label: l10n.csEvaluations,
                            value: '—',
                            icon: Icons.assessment_outlined,
                            color: AppColors.primaryLight,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanySupervisorStudentsScreen())).then((_) => _load()),
                          ),
                        ],
                      ),
                    ),
                    SectionHeader(title: l10n.csPendingYourReview, actionLabel: l10n.viewAll),
                    if (_pendingReviews.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(l10n.csNothingPendingReview, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
                      )
                    else
                      ..._pendingReviews.map((item) => AccentCard(
                            accentColor: AppColors.warning,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanySupervisorReviewsScreen())).then((_) => _load()),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.surfaceVariant,
                                  child: Text(logoLetter(item['student_name'] as String), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['title'] as String, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                      Text(l10n.supSubmittedAgo('${item['student_name']} · ${timeAgo(DateTime.parse(item['submitted_at'] as String))}'),
                                          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                StatusBadge.pending(),
                              ],
                            ),
                          )),
                    SectionHeader(title: l10n.csInternProgress),
                    if (_interns.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(l10n.csNoInternsYet, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
                      )
                    else
                      ..._interns.map((i) => _InternProgressRow(
                            name: i['full_name'] as String,
                            pendingCount: i['pending_review_count'] as int,
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => InternDetailScreen(data: i)));
                              _load();
                            },
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

class _InternProgressRow extends StatelessWidget {
  final String name;
  final int pendingCount;
  final VoidCallback onTap;

  const _InternProgressRow({required this.name, required this.pendingCount, required this.onTap});

  Color get _color => pendingCount > 0 ? AppColors.warning : AppColors.success;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.infoBg,
              child: Text(logoLetter(name), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(name, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(pendingCount > 0 ? l10n.supPendingCount(pendingCount) : l10n.supUpToDate, style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: _color)),
            ),
          ],
        ),
      ),
    );
  }
}
