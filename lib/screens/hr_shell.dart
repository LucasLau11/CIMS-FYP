import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/company_service.dart';
import 'company_setup_screen.dart';
import 'hr/hr_dashboard_screen.dart';
import 'hr/hr_postings_screen.dart';
import 'hr/hr_applicants_screen.dart';
import 'hr/hr_messages_screen.dart';

class HrShell extends StatefulWidget {
  const HrShell({super.key});

  @override
  State<HrShell> createState() => _HrShellState();
}

class _HrShellState extends State<HrShell> {
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _hasCompany = false;

  // Same fix as StudentShell/SupervisorShell/AdminShell: IndexedStack keeps
  // every tab's State alive for the session, so tabs showing server data
  // that changes from actions on OTHER tabs would keep showing stale data.
  int _dashboardRefreshKey = 0;
  int _postingsRefreshKey = 0;
  int _applicantsRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _checkCompany();
  }

  Future<void> _checkCompany() async {
    setState(() => _isLoading = true);
    try {
      final company = await CompanyService.instance.getMyCompany();
      if (!mounted) return;
      setState(() {
        _hasCompany = company != null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      if (index != _currentIndex) {
        if (index == 0) _dashboardRefreshKey++;
        if (index == 1) _postingsRefreshKey++;
        if (index == 2) _applicantsRefreshKey++;
      }
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (!_hasCompany) {
      return CompanySetupScreen(onDone: _checkCompany);
    }

    final l10n = AppLocalizations.of(context)!;
    final screens = [
      HrDashboardScreen(key: ValueKey('hr-dashboard-$_dashboardRefreshKey')),
      HrPostingsScreen(key: ValueKey('hr-postings-$_postingsRefreshKey')),
      HrApplicantsScreen(key: ValueKey('hr-applicants-$_applicantsRefreshKey')),
      // Not `const` — see the comment in student_shell.dart. A const
      // instance here would be canonicalized and reused identically across
      // every HrShell rebuild (e.g. a theme toggle), which makes Flutter's
      // Element.updateChild skip rebuilding this tab entirely, leaving it
      // stuck on whichever AppColors brightness was active when it was
      // first built. (HrMessagesScreen itself must also not return a
      // `const` child — see hr_messages_screen.dart.)
      HrMessagesScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              activeIcon: const Icon(Icons.dashboard),
              label: l10n.dashboard,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.work_outline),
              activeIcon: const Icon(Icons.work),
              label: l10n.hrPostings,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people_outline),
              activeIcon: const Icon(Icons.people),
              label: l10n.hrApplicants,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline),
              activeIcon: const Icon(Icons.chat_bubble),
              label: l10n.profileMessages,
            ),
          ],
        ),
      ),
    );
  }
}
