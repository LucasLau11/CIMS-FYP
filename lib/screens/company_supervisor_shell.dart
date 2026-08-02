import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/company_service.dart';
import 'company_setup_screen.dart';
import 'company_supervisor/company_supervisor_dashboard_screen.dart';
import 'company_supervisor/company_supervisor_students_screen.dart';
import 'company_supervisor/company_supervisor_messages_screen.dart';

class CompanySupervisorShell extends StatefulWidget {
  const CompanySupervisorShell({super.key});

  @override
  State<CompanySupervisorShell> createState() => _CompanySupervisorShellState();
}

class _CompanySupervisorShellState extends State<CompanySupervisorShell> {
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _hasCompany = false;

  // Same fix as the other shells: IndexedStack keeps every tab's State
  // alive for the session, so tabs showing server data that changes from
  // actions on OTHER tabs would keep showing stale data.
  int _dashboardRefreshKey = 0;
  int _studentsRefreshKey = 0;

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
        if (index == 1) _studentsRefreshKey++;
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
      CompanySupervisorDashboardScreen(key: ValueKey('cs-dashboard-$_dashboardRefreshKey')),
      CompanySupervisorStudentsScreen(key: ValueKey('cs-students-$_studentsRefreshKey')),
      // Not `const` — see the comment in student_shell.dart. A const
      // instance here would be canonicalized and reused identically across
      // every CompanySupervisorShell rebuild (e.g. a theme toggle), which
      // makes Flutter's Element.updateChild skip rebuilding this tab
      // entirely, leaving it stuck on whichever AppColors brightness was
      // active when it was first built. (CompanySupervisorMessagesScreen
      // itself must also not return a `const` child — see
      // company_supervisor_messages_screen.dart.)
      CompanySupervisorMessagesScreen(),
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
              icon: const Icon(Icons.people_outline),
              activeIcon: const Icon(Icons.people),
              label: l10n.csInterns,
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
