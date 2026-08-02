import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'supervisor/supervisor_dashboard_screen.dart';
import 'supervisor/supervisor_students_screen.dart';
import 'supervisor/supervisor_reviews_screen.dart';
import 'supervisor/supervisor_messages_screen.dart';

class SupervisorShell extends StatefulWidget {
  const SupervisorShell({super.key});

  @override
  State<SupervisorShell> createState() => _SupervisorShellState();
}

class _SupervisorShellState extends State<SupervisorShell> {
  int _currentIndex = 0;

  // Same fix as StudentShell: IndexedStack keeps every tab's State alive
  // for the session, so Dashboard/Students/Reviews (all showing server
  // data that changes from actions on OTHER tabs, e.g. reviewing a
  // submission doesn't touch the already-built Students tab) would keep
  // showing stale data forever without this. Rekeying on tab switch
  // forces a fresh fetch.
  int _dashboardRefreshKey = 0;
  int _studentsRefreshKey = 0;
  int _reviewsRefreshKey = 0;

  void _onTabTapped(int index) {
    setState(() {
      if (index != _currentIndex) {
        if (index == 0) _dashboardRefreshKey++;
        if (index == 1) _studentsRefreshKey++;
        if (index == 2) _reviewsRefreshKey++;
      }
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screens = [
      SupervisorDashboardScreen(key: ValueKey('dashboard-$_dashboardRefreshKey')),
      SupervisorStudentsScreen(key: ValueKey('students-$_studentsRefreshKey')),
      SupervisorReviewsScreen(key: ValueKey('reviews-$_reviewsRefreshKey')),
      // Not `const` — see the comment in student_shell.dart. A const
      // instance here would be canonicalized and reused identically across
      // every SupervisorShell rebuild (e.g. a theme toggle), which makes
      // Flutter's Element.updateChild skip rebuilding this tab entirely,
      // leaving it stuck on whichever AppColors brightness was active when
      // it was first built. (SupervisorMessagesScreen itself must also not
      // return a `const` child — see supervisor_messages_screen.dart.)
      SupervisorMessagesScreen(),
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
              icon: const Icon(Icons.school_outlined),
              activeIcon: const Icon(Icons.school),
              label: l10n.supStudents,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.fact_check_outlined),
              activeIcon: const Icon(Icons.fact_check),
              label: l10n.supReviews,
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
