import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/screens/admin/admin_analytics_screen.dart';
import 'package:fyp_cims/screens/admin/admin_approvals_screen.dart';
import 'package:fyp_cims/screens/admin/admin_audit_log_screen.dart';
import 'package:fyp_cims/screens/admin/admin_companies_screen.dart';
import 'package:fyp_cims/screens/admin/admin_dashboard_screen.dart';
import 'package:fyp_cims/screens/admin/admin_document_templates_screen.dart';
import 'package:fyp_cims/screens/admin/admin_intakes_screen.dart';
import 'package:fyp_cims/screens/admin/admin_monitor_screen.dart';
import 'package:fyp_cims/screens/admin/admin_more_screen.dart';
import 'package:fyp_cims/screens/admin/admin_students_screen.dart';
import 'package:fyp_cims/screens/admin/admin_supervisors_screen.dart';
import 'package:fyp_cims/screens/admin_shell.dart';
import 'package:fyp_cims/screens/company_supervisor/company_supervisor_dashboard_screen.dart';
import 'package:fyp_cims/screens/company_supervisor/company_supervisor_messages_screen.dart';
import 'package:fyp_cims/screens/company_supervisor/company_supervisor_reviews_screen.dart';
import 'package:fyp_cims/screens/company_supervisor/company_supervisor_students_screen.dart';
import 'package:fyp_cims/screens/company_supervisor_shell.dart';
import 'package:fyp_cims/screens/hr/hr_applicants_screen.dart';
import 'package:fyp_cims/screens/hr/hr_availability_screen.dart';
import 'package:fyp_cims/screens/hr/hr_dashboard_screen.dart';
import 'package:fyp_cims/screens/hr/hr_messages_screen.dart';
import 'package:fyp_cims/screens/hr/hr_postings_screen.dart';
import 'package:fyp_cims/screens/hr_shell.dart';
import 'package:fyp_cims/screens/staff_profile_screen.dart';
import 'package:fyp_cims/screens/stats_screen.dart';
import 'package:fyp_cims/screens/supervisor/supervisor_dashboard_screen.dart';
import 'package:fyp_cims/screens/supervisor/supervisor_messages_screen.dart';
import 'package:fyp_cims/screens/supervisor/supervisor_reviews_screen.dart';
import 'package:fyp_cims/screens/supervisor/supervisor_students_screen.dart';
import 'package:fyp_cims/screens/supervisor_shell.dart';

import 'fixtures.dart';
import 'fixtures_staff.dart';
import 'layout_harness.dart';

/// HR, supervisor, company-supervisor and admin screens with long data in them.
void main() {
  setUpAll(() async {
    await initFakeSupabase(tables: staffTables('company_hr'));
  });

  final who = longName.substring(0, 8);
  final screens = <String, (String role, Widget Function() build, String? probe)>{
    'HrShell': ('company_hr', () => const HrShell(), null),
    'HrDashboardScreen': ('company_hr', () => const HrDashboardScreen(), who),
    'HrPostingsScreen': ('company_hr', () => const HrPostingsScreen(), 'Senior Full-Stack'),
    'HrApplicantsScreen': ('company_hr', () => const HrApplicantsScreen(), who),
    'HrAvailabilityScreen': ('company_hr', () => const HrAvailabilityScreen(), 'Monday'),
    'HrMessagesScreen': ('company_hr', () => const HrMessagesScreen(), who),
    'StaffProfileScreen': ('company_hr', () => const StaffProfileScreen(), null),
    'SupervisorShell': ('academic_supervisor', () => const SupervisorShell(), null),
    'SupervisorDashboardScreen': ('academic_supervisor', () => const SupervisorDashboardScreen(), null),
    'SupervisorStudentsScreen': ('academic_supervisor', () => const SupervisorStudentsScreen(), who),
    'SupervisorReviewsScreen': ('academic_supervisor', () => const SupervisorReviewsScreen(), null),
    'SupervisorMessagesScreen': ('academic_supervisor', () => const SupervisorMessagesScreen(), who),
    'CompanySupervisorShell': ('company_supervisor', () => const CompanySupervisorShell(), null),
    'CompanySupervisorDashboardScreen': ('company_supervisor', () => const CompanySupervisorDashboardScreen(), null),
    'CompanySupervisorStudentsScreen': ('company_supervisor', () => const CompanySupervisorStudentsScreen(), who),
    'CompanySupervisorReviewsScreen': ('company_supervisor', () => const CompanySupervisorReviewsScreen(), null),
    'CompanySupervisorMessagesScreen': ('company_supervisor', () => const CompanySupervisorMessagesScreen(), who),
    'AdminShell': ('admin', () => const AdminShell(), null),
    'AdminDashboardScreen': ('admin', () => const AdminDashboardScreen(), null),
    'AdminStudentsScreen': ('admin', () => const AdminStudentsScreen(), who),
    'AdminCompaniesScreen': ('admin', () => const AdminCompaniesScreen(), 'International Business'),
    'AdminSupervisorsScreen': ('admin', () => const AdminSupervisorsScreen(), 'Dr. Muhammad'),
    'AdminMoreScreen': ('admin', () => const AdminMoreScreen(), null),
    'AdminApprovalsScreen': ('admin', () => const AdminApprovalsScreen(), who),
    'AdminMonitorScreen': ('admin', () => const AdminMonitorScreen(), null),
    'AdminIntakesScreen': ('admin', () => const AdminIntakesScreen(), 'January 2027'),
    'AdminDocumentTemplatesScreen': ('admin', () => const AdminDocumentTemplatesScreen(), 'Parent / Guardian'),
    'StaffProfileScreen (admin)': ('admin', () => const StaffProfileScreen(), null),
    'StatsScreen (HR)': ('company_hr', () => StatsScreen(source: statsSourceFor('company_hr')!), '31'),
    'StatsScreen (academic supervisor)': ('academic_supervisor', () => StatsScreen(source: statsSourceFor('academic_supervisor')!), '18'),
    'StatsScreen (company supervisor)': ('company_supervisor', () => StatsScreen(source: statsSourceFor('company_supervisor')!), '5'),
    'StatsScreen (admin)': ('admin', () => StatsScreen(source: statsSourceFor('admin')!), '15'),
    'AdminAnalyticsScreen': ('admin', () => const AdminAnalyticsScreen(), '47'),
    'AdminAuditLogScreen': ('admin', () => const AdminAuditLogScreen(), 'Account of'),
  };

  screens.forEach((name, spec) {
    testWidgets('$name (with data) has no layout problems at any size', (tester) async {
      addTearDown(tester.view.reset);
      setFixtures(staffTables(spec.$1));
      final problems = await checkLayout(
        tester,
        name,
        spec.$2,
        role: spec.$1,
        expectText: spec.$3,
        interact: tapAllTabs,
      );
      expect(problems, isEmpty, reason: '\n${describeProblems(problems)}');
    }, timeout: const Timeout(Duration(minutes: 8)));
  });
}
