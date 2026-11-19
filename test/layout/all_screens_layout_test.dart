import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/screens/admin/admin_approvals_screen.dart';
import 'package:fyp_cims/screens/admin/admin_companies_screen.dart';
import 'package:fyp_cims/screens/admin/admin_dashboard_screen.dart';
import 'package:fyp_cims/screens/admin/admin_document_templates_screen.dart';
import 'package:fyp_cims/screens/admin/admin_intakes_screen.dart';
import 'package:fyp_cims/screens/admin/admin_monitor_screen.dart';
import 'package:fyp_cims/screens/admin/admin_more_screen.dart';
import 'package:fyp_cims/screens/admin/admin_students_screen.dart';
import 'package:fyp_cims/screens/admin/admin_supervisors_screen.dart';
import 'package:fyp_cims/screens/admin_shell.dart';
import 'package:fyp_cims/screens/company_setup_screen.dart';
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
import 'package:fyp_cims/screens/student/student_applications_screen.dart';
import 'package:fyp_cims/screens/student/student_dashboard_screen.dart';
import 'package:fyp_cims/screens/student/student_messages_screen.dart';
import 'package:fyp_cims/screens/student/student_notifications_screen.dart';
import 'package:fyp_cims/screens/student/student_profile_screen.dart';
import 'package:fyp_cims/screens/student/student_reports_screen.dart';
import 'package:fyp_cims/screens/student/student_search_screen.dart';
import 'package:fyp_cims/screens/student_shell.dart';
import 'package:fyp_cims/screens/supervisor/supervisor_dashboard_screen.dart';
import 'package:fyp_cims/screens/supervisor/supervisor_messages_screen.dart';
import 'package:fyp_cims/screens/supervisor/supervisor_reviews_screen.dart';
import 'package:fyp_cims/screens/supervisor/supervisor_students_screen.dart';
import 'package:fyp_cims/screens/supervisor_shell.dart';

import 'layout_harness.dart';

/// Every screen that can be opened without arguments, rendered with an EMPTY
/// backend (the "nothing here yet" states) at every device size and text scale.
/// Screens with data are covered by data_screens_layout_test.dart.
void main() {
  setUpAll(() async {
    await initFakeSupabase();
  });

  final screens = <String, (String role, Widget Function() build)>{
    'StudentShell': ('student', () => const StudentShell()),
    'StudentDashboardScreen': ('student', () => const StudentDashboardScreen()),
    'StudentSearchScreen': ('student', () => const StudentSearchScreen()),
    'StudentApplicationsScreen': ('student', () => const StudentApplicationsScreen()),
    'StudentReportsScreen': ('student', () => const StudentReportsScreen()),
    'StudentMessagesScreen': ('student', () => const StudentMessagesScreen()),
    'StudentNotificationsScreen': ('student', () => const StudentNotificationsScreen()),
    'StudentProfileScreen': ('student', () => const StudentProfileScreen()),
    'HrShell': ('company_hr', () => const HrShell()),
    'HrDashboardScreen': ('company_hr', () => const HrDashboardScreen()),
    'HrPostingsScreen': ('company_hr', () => const HrPostingsScreen()),
    'HrApplicantsScreen': ('company_hr', () => const HrApplicantsScreen()),
    'HrAvailabilityScreen': ('company_hr', () => const HrAvailabilityScreen()),
    'HrMessagesScreen': ('company_hr', () => const HrMessagesScreen()),
    'StaffProfileScreen': ('company_hr', () => const StaffProfileScreen()),
    'CompanySetupScreen': ('company_hr', () => CompanySetupScreen(onDone: () {})),
    'SupervisorShell': ('academic_supervisor', () => const SupervisorShell()),
    'SupervisorDashboardScreen': ('academic_supervisor', () => const SupervisorDashboardScreen()),
    'SupervisorStudentsScreen': ('academic_supervisor', () => const SupervisorStudentsScreen()),
    'SupervisorReviewsScreen': ('academic_supervisor', () => const SupervisorReviewsScreen()),
    'SupervisorMessagesScreen': ('academic_supervisor', () => const SupervisorMessagesScreen()),
    'CompanySupervisorShell': ('company_supervisor', () => const CompanySupervisorShell()),
    'CompanySupervisorDashboardScreen': ('company_supervisor', () => const CompanySupervisorDashboardScreen()),
    'CompanySupervisorStudentsScreen': ('company_supervisor', () => const CompanySupervisorStudentsScreen()),
    'CompanySupervisorReviewsScreen': ('company_supervisor', () => const CompanySupervisorReviewsScreen()),
    'CompanySupervisorMessagesScreen': ('company_supervisor', () => const CompanySupervisorMessagesScreen()),
    'AdminShell': ('admin', () => const AdminShell()),
    'AdminDashboardScreen': ('admin', () => const AdminDashboardScreen()),
    'AdminStudentsScreen': ('admin', () => const AdminStudentsScreen()),
    'AdminCompaniesScreen': ('admin', () => const AdminCompaniesScreen()),
    'AdminSupervisorsScreen': ('admin', () => const AdminSupervisorsScreen()),
    'AdminMoreScreen': ('admin', () => const AdminMoreScreen()),
    'AdminApprovalsScreen': ('admin', () => const AdminApprovalsScreen()),
    'AdminMonitorScreen': ('admin', () => const AdminMonitorScreen()),
    'AdminIntakesScreen': ('admin', () => const AdminIntakesScreen()),
    'AdminDocumentTemplatesScreen': ('admin', () => const AdminDocumentTemplatesScreen()),
    'StaffProfileScreen (admin)': ('admin', () => const StaffProfileScreen()),
  };

  screens.forEach((name, spec) {
    testWidgets('$name (empty) has no layout problems at any size', (tester) async {
      addTearDown(tester.view.reset);
      final problems = await checkLayout(tester, name, spec.$2, role: spec.$1);
      expect(problems, isEmpty, reason: '\n${describeProblems(problems)}');
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
