import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/screens/admin/admin_create_students_screen.dart';
import 'package:fyp_cims/screens/company_supervisor/company_supervisor_evaluate_screen.dart';
import 'package:fyp_cims/screens/force_password_change_screen.dart';
import 'package:fyp_cims/services/admin_data_service.dart';
import 'package:fyp_cims/screens/company_supervisor/company_supervisor_students_screen.dart';
import 'package:fyp_cims/screens/hr/hr_applicants_screen.dart';
import 'package:fyp_cims/screens/hr/hr_recommended_candidates_screen.dart';
import 'package:fyp_cims/screens/student/student_apply_screen.dart';
import 'package:fyp_cims/screens/student/student_company_profile_screen.dart';
import 'package:fyp_cims/screens/student/student_internship_details_screen.dart';
import 'package:fyp_cims/screens/student/student_interview_screen.dart';
import 'package:fyp_cims/screens/student_grade_screen.dart';
import 'package:fyp_cims/screens/supervisor/supervisor_intakes_screen.dart';
import 'package:fyp_cims/screens/supervisor/supervisor_students_screen.dart';
import 'package:fyp_cims/services/interview_service.dart';

import 'fixtures.dart';
import 'fixtures_staff.dart';
import 'layout_harness.dart';

Map<String, dynamic> _flatPosting() => {
      ...posting(),
      'id': postingId,
      'company_name': longCompany,
      'company_industry': 'Information Technology and Business Process Outsourcing Services',
      'category': 'Software Engineering and Data Science',
    };

Map<String, dynamic> _studentApplication(String status) {
  final a = application(status, withInterview: status == 'interview');
  return {
    ...a,
    'id': a['application_id'],
    'internships': _flatPosting(),
    'interview': a['interviews'] == null ? null : InterviewInfo.fromEmbed(a['interviews']),
  };
}

Map<String, dynamic> _hrApplicant(String status) {
  final a = application(status, withInterview: status == 'interview');
  return {
    ...a,
    'id': a['application_id'],
    'student_name': longName,
    'programme': longProgramme,
    'student_reg_no': '24WMR12345',
    'resume_path': 'x/resume.pdf',
    'resume_filename': 'Muhammad_Alexander_Resume_Final_Version_2026_v3.pdf',
    'internship_title': longTitle,
    'company_name': longCompany,
    'interview': a['interviews'] == null ? null : InterviewInfo.fromEmbed(a['interviews']),
  };
}

/// Screens opened with data handed to them (detail pages, forms, chat).
void main() {
  setUpAll(() async {
    await initFakeSupabase(tables: staffTables('company_hr'));
  });

  final student = {
    'id': me,
    'profile_id': me,
    'full_name': longName,
    'programme': longProgramme,
    'company_name': longCompany,
    'student_reg_no': '24WMR12345',
    'email': unbroken,
    'faculty': 'Faculty of Computing and Information Technology',
    'semester': 6,
    'skills': ['Flutter', 'Dart', 'Machine Learning Operations'],
  };

  final screens = <String, (String role, Widget Function() build)>{
    'ApplicantDetailScreen (pending)': ('company_hr', () => ApplicantDetailScreen(data: _hrApplicant('pending'))),
    'ApplicantDetailScreen (interview)': ('company_hr', () => ApplicantDetailScreen(data: _hrApplicant('interview'))),
    'ApplicantDetailScreen (offered)': ('company_hr', () => ApplicantDetailScreen(data: _hrApplicant('offered'))),
    'ApplicantDetailScreen (active)': ('company_hr', () => ApplicantDetailScreen(data: _hrApplicant('active'))),
    'ApplicantDetailScreen (rejected)': ('company_hr', () => ApplicantDetailScreen(data: _hrApplicant('rejected'))),
    'RecommendedCandidatesScreen': ('company_hr', () => const RecommendedCandidatesScreen(postingTitle: longTitle, requiredSkills: ['Flutter', 'Dart', 'Machine Learning'])),
    'StudentInterviewScreen (scheduled)': ('student', () => StudentInterviewScreen(application: _studentApplication('interview'))),
    'StudentInternshipDetailsScreen': ('student', () => StudentInternshipDetailsScreen(internship: _flatPosting(), applied: false)),
    'StudentInternshipDetailsScreen (applied)': ('student', () => StudentInternshipDetailsScreen(internship: _flatPosting(), applied: true)),
    'StudentApplyScreen': ('student', () => StudentApplyScreen(internship: _flatPosting())),
    'StudentCompanyProfileScreen': ('student', () => const StudentCompanyProfileScreen(companyId: companyId, companyName: longCompany)),
    // ChatScreen is not listed: it subscribes to a realtime websocket stream that cannot run against
    // the fake backend. Its layout (bubbles capped at 72% of the width, ellipsized names and file
    // names) was reviewed by hand instead.
    'AdminCreateStudentsScreen': ('admin', () => const AdminCreateStudentsScreen()),
    'StudentCredentialsScreen': (
      'admin',
      () => StudentCredentialsScreen(results: [
            StudentAccountResult(email: unbroken, fullName: longName, status: 'created', password: 'Zq7!mHk3xWp#', message: 'Created, but the registration number could not be saved.'),
            const StudentAccountResult(email: 'ali@student.tarc.edu.my', fullName: 'Ali', status: 'created', password: 'Bn4@tRw8yLd!'),
            StudentAccountResult(email: unbroken, fullName: longName, status: 'exists', message: 'An account with this email already exists.'),
          ])
    ),
    'ForcedPasswordChangeScreen': ('student', () => ForcedPasswordChangeScreen(onDone: () {})),
    'StudentGradeScreen': ('academic_supervisor', () => StudentGradeScreen(studentId: '00000000-0000-4000-8000-000000000001', studentName: longName)),
    'SupervisorIntakesScreen': ('academic_supervisor', () => const SupervisorIntakesScreen()),
    'StudentDetailScreen (admin)': ('admin', () => const StudentDetailScreen(studentId: '00000000-0000-4000-8000-000000000001', adminMode: true)),
    'StudentDetailScreen (supervisor)': ('academic_supervisor', () => const StudentDetailScreen(studentId: '00000000-0000-4000-8000-000000000001')),
    'CompanySupervisorEvaluateScreen': ('company_supervisor', () => CompanySupervisorEvaluateScreen(intern: student)),
    'InternDetailScreen': ('company_supervisor', () => InternDetailScreen(data: {...student, 'student_id': me, 'internship_title': longTitle})),
  };

  screens.forEach((name, spec) {
    testWidgets('$name has no layout problems at any size', (tester) async {
      addTearDown(tester.view.reset);
      setFixtures(staffTables(spec.$1));
      final problems = await checkLayout(tester, name, spec.$2, role: spec.$1, interact: tapAllTabs);
      expect(problems, isEmpty, reason: '\n${describeProblems(problems)}');
    }, timeout: const Timeout(Duration(minutes: 8)));
  });
}
