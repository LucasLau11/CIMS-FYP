import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_students_screen.dart';
import 'admin/admin_companies_screen.dart';
import 'admin/admin_supervisors_screen.dart';
import 'admin/admin_more_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  // Same fix as StudentShell/SupervisorShell: IndexedStack keeps every
  // tab's State alive for the session, so tabs showing server data that
  // changes from actions on OTHER tabs (assigning a supervisor on
  // Students doesn't touch the already-built Dashboard/Supervisors tabs)
  // would keep showing stale data forever without this.
  int _dashboardRefreshKey = 0;
  int _studentsRefreshKey = 0;
  int _companiesRefreshKey = 0;
  int _supervisorsRefreshKey = 0;

  void _onTabTapped(int index) {
    setState(() {
      if (index != _currentIndex) {
        if (index == 0) _dashboardRefreshKey++;
        if (index == 1) _studentsRefreshKey++;
        if (index == 2) _companiesRefreshKey++;
        if (index == 3) _supervisorsRefreshKey++;
      }
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      AdminDashboardScreen(key: ValueKey('dashboard-$_dashboardRefreshKey')),
      AdminStudentsScreen(key: ValueKey('students-$_studentsRefreshKey')),
      AdminCompaniesScreen(key: ValueKey('companies-$_companiesRefreshKey')),
      AdminSupervisorsScreen(key: ValueKey('supervisors-$_supervisorsRefreshKey')),
      // Not `const` — see the comment in student_shell.dart. A const
      // instance here would be canonicalized and reused identically across
      // every AdminShell rebuild (e.g. a theme toggle), which makes
      // Flutter's Element.updateChild skip rebuilding this tab entirely,
      // leaving it stuck on whichever AppColors brightness was active when
      // it was first built.
      AdminMoreScreen(),
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              activeIcon: Icon(Icons.school),
              label: 'Students',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.business_outlined),
              activeIcon: Icon(Icons.business),
              label: 'Companies',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.supervisor_account_outlined),
              activeIcon: Icon(Icons.supervisor_account),
              label: 'Supervisors',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_outlined),
              activeIcon: Icon(Icons.menu),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable CIMS shield logo mark for app bars (small, icon-only use)
class CimsLogoMark extends StatelessWidget {
  final double size;

  const CimsLogoMark({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/cims_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
