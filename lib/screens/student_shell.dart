import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/student_data_service.dart';
import 'student/student_dashboard_screen.dart';
import 'student/student_search_screen.dart';
import 'student/student_applications_screen.dart';
import 'student/student_reports_screen.dart';
import 'student/student_messages_screen.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _currentIndex = 0;

  // IndexedStack keeps every tab's widget (and State, and its initState-time
  // data fetch) alive for the app's whole session — switching tabs never
  // rebuilds them. That's fine for Search/Messages, but Dashboard,
  // Applications, and Reports show server data that changes from actions
  // taken on OTHER tabs (e.g. submitting an application on Search doesn't
  // touch the already-built Applications tab at all), so they'd keep
  // showing whatever they first loaded. Bumping a counter into each
  // screen's key when its tab is selected forces Flutter to treat it as a
  // brand new widget — fresh State, fresh initState fetch — every time the
  // user switches to it, without disturbing the other tabs' state.
  int _dashboardRefreshKey = 0;
  int _applicationsRefreshKey = 0;
  int _reportsRefreshKey = 0;

  int _unreadMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadMessageCount();
  }

  Future<void> _loadUnreadMessageCount() async {
    try {
      final count = await StudentDataService.instance.getUnreadMessageCount();
      if (!mounted) return;
      setState(() => _unreadMessageCount = count);
    } catch (_) {
      // Non-fatal — badge just stays at its last known value.
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      if (index != _currentIndex) {
        if (index == 0) _dashboardRefreshKey++;
        if (index == 2) _applicationsRefreshKey++;
        if (index == 3) _reportsRefreshKey++;
      }
      _currentIndex = index;
    });
    // Cheap count-only query — refresh on every tab switch so the badge
    // reflects messages read/received on the Messages tab or elsewhere.
    _loadUnreadMessageCount();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      StudentDashboardScreen(key: ValueKey('dashboard-$_dashboardRefreshKey')),
      const StudentSearchScreen(),
      StudentApplicationsScreen(key: ValueKey('applications-$_applicationsRefreshKey')),
      StudentReportsScreen(key: ValueKey('reports-$_reportsRefreshKey')),
      const StudentMessagesScreen(),
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
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Search',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.work_outline),
              activeIcon: Icon(Icons.work),
              label: 'Applications',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: _MessagesIcon(count: _unreadMessageCount, filled: false),
              activeIcon: _MessagesIcon(count: _unreadMessageCount, filled: true),
              label: 'Messages',
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesIcon extends StatelessWidget {
  final int count;
  final bool filled;

  const _MessagesIcon({required this.count, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(filled ? Icons.chat_bubble : Icons.chat_bubble_outline),
        if (count > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
