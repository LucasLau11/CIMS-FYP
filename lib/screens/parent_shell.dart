import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common/shared_widgets.dart';
import '../services/parent_data_service.dart';
import '../services/auth_service.dart';
import '../utils/format_utils.dart';
import 'parent/parent_acknowledgement_screen.dart';
import 'parent/parent_progress_screen.dart';
import 'admin_shell.dart';
import 'login_screen.dart';

class ParentShell extends StatefulWidget {
  const ParentShell({super.key});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  bool _isLoading = true;
  Map<String, dynamic>? _child;
  Map<String, dynamic>? _activeApplication;
  String _selectedThemeCode = 'system';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final child = await ParentDataService.instance.getChild();
      Map<String, dynamic>? application;
      if (child != null) {
        application = await ParentDataService.instance.getChildActiveApplication(child['id'] as String);
      }
      final profile = await AuthService.instance.getCurrentProfile();
      if (!mounted) return;
      setState(() {
        _child = child;
        _activeApplication = application;
        _selectedThemeCode = profile?['theme_mode'] as String? ?? 'system';
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _showThemePicker() {
    const options = {'light': 'Light', 'dark': 'Dark', 'system': 'System'};
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Select theme', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.entries.map((entry) {
              return RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.value, style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
                value: entry.key,
                groupValue: _selectedThemeCode,
                activeColor: AppColors.primary,
                onChanged: (val) async {
                  Navigator.pop(dialogContext);
                  setState(() => _selectedThemeCode = val!);
                  try {
                    await AuthService.instance.updateThemeMode(val!);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not save theme: $e'), backgroundColor: AppColors.error),
                    );
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ],
        );
      },
    );
  }

  Future<void> _logOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: const Text('You will need to log in again to access your account.', style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text('Log out', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;

    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final child = _child;
    final companyName = (_activeApplication?['internships'] as Map?)?['company_name'] as String?;

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
                                  IconButton(icon: const Icon(Icons.dark_mode_outlined, color: Colors.white, size: 20), onPressed: _showThemePicker),
                                  IconButton(icon: const Icon(Icons.logout, color: Colors.white, size: 20), onPressed: _logOut),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Text('Welcome, Parent', style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                          const Text('Monitor your child\'s internship progress', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
            else if (child == null)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.family_restroom_outlined,
                  title: 'No child linked yet',
                  description: 'Your account isn\'t linked to a student yet. Please contact the university admin office to complete this setup.',
                ),
              )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.infoBg,
                              child: Text(logoLetter(child['full_name'] as String? ?? '?'),
                                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text((child['full_name'] as String?)?.isNotEmpty == true ? child['full_name'] as String : 'Unnamed student',
                                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                  Text((child['programme'] as String?) ?? 'Programme not set',
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(companyName != null ? '$companyName · Ongoing' : 'No active internship yet',
                                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary)),
                                ],
                              ),
                            ),
                            if (companyName != null) StatusBadge.active(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('What would you like to do?', style: AppTextStyles.h3),
                      const SizedBox(height: 14),
                      _ActionCard(
                        icon: Icons.draw_outlined,
                        title: 'Sign Acknowledgement Form',
                        description: 'Digitally approve your child\'s internship participation.',
                        status: companyName != null ? 'Action may be required' : 'No internship yet',
                        statusColor: AppColors.warning,
                        buttonLabel: 'Open form',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ParentAcknowledgementScreen(child: child, application: _activeApplication))),
                      ),
                      const SizedBox(height: 14),
                      _ActionCard(
                        icon: Icons.trending_up,
                        title: 'View Internship Progress',
                        description: 'Track your child\'s internship journey and report submissions.',
                        status: companyName != null ? 'Ongoing' : 'Not started',
                        statusColor: AppColors.primary,
                        buttonLabel: 'View progress',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ParentProgressScreen(child: child, application: _activeApplication))),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: Column(
                          children: [
                            Text('Centralised Internship Management System', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textMuted)),
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

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String status;
  final Color statusColor;
  final String buttonLabel;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.statusColor,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(status, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: Text(buttonLabel, style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
