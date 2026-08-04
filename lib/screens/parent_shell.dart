import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/common/shared_widgets.dart';
import '../services/parent_data_service.dart';
import '../services/auth_service.dart';
import '../services/student_data_service.dart';
import '../utils/format_utils.dart';
import 'admin_shell.dart';
import 'staff_profile_screen.dart';
import 'parent/parent_acknowledgement_screen.dart';
import 'parent/parent_link_child_screen.dart';
import 'parent/parent_progress_screen.dart';
import 'student/student_messages_screen.dart';
import 'student/student_notifications_screen.dart';

class ParentShell extends StatefulWidget {
  const ParentShell({super.key});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _children = [];
  final Map<String, Map<String, dynamic>?> _activeApplications = {};
  String? _name;
  String? _avatarUrl;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final children = await ParentDataService.instance.getChildren();
      final apps = <String, Map<String, dynamic>?>{};
      for (final child in children) {
        apps[child['id'] as String] = await ParentDataService.instance.getChildLatestApplication(child['id'] as String);
      }
      final profile = await AuthService.instance.getCurrentProfile();
      final resolvedAvatarUrl = profile?['avatar_url'] as String?;
      final unread = await StudentDataService.instance.getUnreadNotificationCount();
      if (!mounted) return;
      setState(() {
        _children = children;
        _activeApplications
          ..clear()
          ..addAll(apps);
        _name = profile?['full_name'] as String?;
        _avatarUrl = resolvedAvatarUrl;
        _unreadNotifications = unread;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openLinkChild() async {
    final linked = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const ParentLinkChildScreen()));
    if (linked == true) _load();
  }

  Future<void> _openProfile() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffProfileScreen()));
    _load();
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
              expandedHeight: 150,
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
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                    child: const CimsLogoMark(size: 24),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text('CIMS', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(icon: const Icon(Icons.person_add_alt_outlined, color: Colors.white, size: 20), onPressed: _openLinkChild),
                                  IconButton(
                                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentMessagesScreen())),
                                  ),
                                  NotificationBell(
                                    count: _unreadNotifications,
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentNotificationsScreen())),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _openProfile,
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
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_name?.isNotEmpty == true ? l10n.parentWelcomeName(_name!) : l10n.parentWelcomeDefault,
                                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                                    Text(l10n.parentDashboardSubtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white70)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
            else if (_children.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EmptyState(
                          icon: Icons.family_restroom_outlined,
                          title: l10n.parentNoChildrenTitle,
                          description: l10n.parentNoChildrenDescription,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _openLinkChild,
                          icon: const Icon(Icons.person_add_alt_outlined, size: 18),
                          label: Text(l10n.parentLinkChildButton),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final child in _children) ...[
                        _ChildCard(
                          child: child,
                          application: _activeApplications[child['id']],
                          onOpenForm: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ParentAcknowledgementScreen(child: child, application: _activeApplications[child['id']])),
                          ),
                          onViewProgress: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ParentProgressScreen(child: child, application: _activeApplications[child['id']])),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      const SizedBox(height: 18),
                      Center(
                        child: Column(
                          children: [
                            Text(l10n.cimsFullName, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textMuted)),
                            const SizedBox(height: 4),
                            Image.asset('assets/images/cims_logo.png', height: 36, opacity: const AlwaysStoppedAnimation(0.4)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final Map<String, dynamic> child;
  final Map<String, dynamic>? application;
  final VoidCallback onOpenForm;
  final VoidCallback onViewProgress;

  const _ChildCard({required this.child, required this.application, required this.onOpenForm, required this.onViewProgress});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final companyName = (application?['internships'] as Map?)?['company_name'] as String?;
    final status = application?['status'] as String?;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.infoBg,
                child: Text(logoLetter(child['full_name'] as String? ?? '?'),
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((child['full_name'] as String?)?.isNotEmpty == true ? child['full_name'] as String : l10n.parentUnnamedStudent,
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Text((child['programme'] as String?) ?? l10n.programmeNotSet,
                        style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(companyName != null ? '$companyName · ${applicationStatusLabel(status ?? 'pending')}' : l10n.parentNoApplicationYet,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary)),
                  ],
                ),
              ),
              if (status != null) applicationStatusBadge(context, status),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenForm,
                  icon: const Icon(Icons.draw_outlined, size: 16),
                  label: Text(l10n.parentSignFormButton, style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onViewProgress,
                  icon: const Icon(Icons.trending_up, size: 16),
                  label: Text(l10n.parentProgressButton, style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
