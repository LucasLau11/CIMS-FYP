import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/screens/student/student_applications_screen.dart';
import 'package:fyp_cims/screens/student/student_dashboard_screen.dart';
import 'package:fyp_cims/screens/student/student_messages_screen.dart';
import 'package:fyp_cims/screens/student/student_notifications_screen.dart';
import 'package:fyp_cims/screens/student/student_profile_screen.dart';
import 'package:fyp_cims/screens/student/student_reports_screen.dart';
import 'package:fyp_cims/screens/student/student_search_screen.dart';
import 'package:fyp_cims/screens/student_shell.dart';

import 'fixtures.dart';
import 'layout_harness.dart';

/// Student screens with realistic, deliberately long data in them.
void main() {
  setUpAll(() async {
    await initFakeSupabase(tables: studentTables());
  });

  final screens = <String, (Widget Function() build, String probe)>{
    'StudentShell': (() => const StudentShell(), 'Muhammad'),
    'StudentDashboardScreen': (() => const StudentDashboardScreen(), 'Muhammad'),
    'StudentSearchScreen': (() => const StudentSearchScreen(), 'Senior Full-Stack'),
    'StudentApplicationsScreen': (() => const StudentApplicationsScreen(), 'Senior Full-Stack'),
    'StudentReportsScreen': (() => const StudentReportsScreen(), 'Month 1'),
    'StudentNotificationsScreen': (() => const StudentNotificationsScreen(), 'Candidate no longer'),
    'StudentMessagesScreen': (() => const StudentMessagesScreen(), 'Muhammad'),
    'StudentProfileScreen': (() => const StudentProfileScreen(), 'Muhammad'),
  };

  screens.forEach((name, spec) {
    testWidgets('$name (with data) has no layout problems at any size', (tester) async {
      addTearDown(tester.view.reset);
      final problems = await checkLayout(
        tester,
        name,
        spec.$1,
        role: 'student',
        expectText: spec.$2,
        interact: tapAllTabs,
      );
      expect(problems, isEmpty, reason: '\n${describeProblems(problems)}');
    }, timeout: const Timeout(Duration(minutes: 8)));
  });
}
