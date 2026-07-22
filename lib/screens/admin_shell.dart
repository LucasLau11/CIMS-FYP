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

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const AdminStudentsScreen(),
    const AdminCompaniesScreen(),
    const AdminSupervisorsScreen(),
    const AdminMoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
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
