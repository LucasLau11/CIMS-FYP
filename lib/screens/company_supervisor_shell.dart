import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
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

  final List<Widget> _screens = [
    const CompanySupervisorDashboardScreen(),
    const CompanySupervisorStudentsScreen(),
    const CompanySupervisorMessagesScreen(),
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
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Interns',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Messages',
            ),
          ],
        ),
      ),
    );
  }
}
