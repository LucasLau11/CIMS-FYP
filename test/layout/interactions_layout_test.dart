import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/screens/admin/admin_companies_screen.dart';
import 'package:fyp_cims/screens/admin/admin_create_students_screen.dart';
import 'package:fyp_cims/screens/admin/admin_intakes_screen.dart';
import 'package:fyp_cims/screens/forgot_password_screen.dart';
import 'package:fyp_cims/screens/hr/hr_applicants_screen.dart';
import 'package:fyp_cims/screens/hr/hr_availability_screen.dart';
import 'package:fyp_cims/screens/hr/hr_postings_screen.dart';
import 'package:fyp_cims/screens/login_screen.dart';
import 'package:fyp_cims/screens/signup_screen.dart';
import 'package:fyp_cims/screens/staff_profile_screen.dart';
import 'package:fyp_cims/screens/student/student_applications_screen.dart';
import 'package:fyp_cims/screens/student/student_interview_screen.dart';
import 'package:fyp_cims/screens/student/student_profile_screen.dart';
import 'package:fyp_cims/screens/student/student_reports_screen.dart';
import 'package:fyp_cims/services/interview_service.dart';
import 'package:fyp_cims/widgets/common/shared_widgets.dart';
import 'package:fyp_cims/widgets/reason_dialog.dart';

import 'fixtures.dart';
import 'fixtures_staff.dart';
import 'layout_harness.dart';

/// Opens dialogs, sheets, forms and error messages and checks those too:
/// a screen that fits is not enough if the sheet on top of it does not.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _tap(WidgetTester tester, Finder finder, {int index = 0}) async {
  if (finder.evaluate().length <= index) return;
  final target = finder.at(index);
  await tester.ensureVisible(target);
  await tester.tap(target, warnIfMissed: false);
  await _settle(tester);
}

Future<void> _tapText(WidgetTester tester, String text, {int index = 0}) => _tap(tester, find.text(text), index: index);

Future<void> _enter(WidgetTester tester, int fieldIndex, String text) async {
  final fields = find.byType(TextField);
  if (fields.evaluate().length <= fieldIndex) return;
  await tester.enterText(fields.at(fieldIndex), text);
  await _settle(tester);
  // wait out the 450 ms validation pause so messages are on screen
  await tester.pump(const Duration(milliseconds: 600));
}

String _slotTime(int day, int slot, int plusMinutes) {
  final d = DateTime.now().add(Duration(days: day));
  return DateTime.utc(d.year, d.month, d.day, 1 + slot ~/ 2, (slot % 2) * 30 + plusMinutes).toIso8601String();
}

Map<String, Object?> _tables(String role) => {
      ...staffTables(role),
      'rpc:interview_free_slots': [
        for (var day = 1; day <= 6; day++)
          for (var slot = 0; slot < 14; slot++)
            {
              'slot_start': _slotTime(day, slot, 0),
              'slot_end': _slotTime(day, slot, 29),
              'slot_minutes': 30,
            },
      ],
    };

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

Map<String, dynamic> _studentApplication(String status) {
  final a = application(status, withInterview: status == 'interview');
  return {
    ...a,
    'id': a['application_id'],
    'internships': {...posting(), 'id': postingId, 'company_name': longCompany},
    'interview': a['interviews'] == null ? null : InterviewInfo.fromEmbed(a['interviews']),
  };
}

void main() {
  setUpAll(() async {
    await initFakeSupabase(tables: _tables('student'));
  });

  final cases = <String, (String role, Widget Function() build, Future<void> Function(WidgetTester) act)>{
    'Login with errors showing': (
      'student',
      () => const LoginScreen(),
      (t) async {
        await _enter(t, 0, 'not-an-email-address-that-is-long-and-wrong-$unbroken');
        await _enter(t, 1, 'x');
        await _tapText(t, 'Log in');
        await _tapText(t, 'Login');
      },
    ),
    'SignUp with manual role and password checklist': (
      'student',
      () => const SignUpScreen(),
      (t) async {
        await _enter(t, 0, 'someone.with.a.long.name@gmail.com');
        await _enter(t, 1, 'abc');
        await _enter(t, 2, 'xyz');
      },
    ),
    'ForgotPassword code step': (
      'student',
      () => const ForgotPasswordScreen(initialEmail: 'student@example.com'),
      (t) async {
        await _tapText(t, 'Send code');
        await _tapText(t, 'Send reset code');
        await _enter(t, 0, '12');
        await _tapText(t, 'Verify code');
      },
    ),
    'HrAvailability add hours sheet': (
      'company_hr',
      () => const HrAvailabilityScreen(),
      (t) async {
        await _tapText(t, 'Add hours');
        await _tap(t, find.byIcon(Icons.close), index: 0);
        await _tapText(t, 'Add day off');
      },
    ),
    'Applicant (pending) schedule interview sheet': (
      'company_hr',
      () => ApplicantDetailScreen(data: _hrApplicant('pending')),
      (t) async {
        await _tapText(t, 'Schedule interview');
        await _tap(t, find.byType(ChoiceChip), index: 1);
        await _enter(t, 0, 'not a link');
      },
    ),
    'Applicant (pending) reject reason dialog': (
      'company_hr',
      () => ApplicantDetailScreen(data: _hrApplicant('pending')),
      (t) async {
        await _tapText(t, 'Reject');
        await _enter(t, 0, 'short');
      },
    ),
    'Applicant (interview) reschedule sheet': (
      'company_hr',
      () => ApplicantDetailScreen(data: _hrApplicant('interview')),
      (t) async {
        await _tapText(t, 'Reschedule');
        await _tap(t, find.byType(ChoiceChip), index: 0);
        await _enter(t, 0, 'short');
      },
    ),
    'Applicant (interview) cancel dialog': (
      'company_hr',
      () => ApplicantDetailScreen(data: _hrApplicant('interview')),
      (t) async {
        await _tapText(t, 'Cancel');
        await _enter(t, 0, 'short');
      },
    ),
    'Student interview reschedule sheet': (
      'student',
      () => StudentInterviewScreen(application: _studentApplication('interview')),
      (t) async {
        await _tapText(t, 'Reschedule');
        await _tap(t, find.byType(ChoiceChip), index: 0);
        await _enter(t, 0, 'short');
      },
    ),
    'Student interview: decline a reschedule request': (
      'student',
      () => StudentInterviewScreen(application: _studentApplication('interview')),
      (t) async {
        await _tapText(t, 'Decline');
        await _enter(t, 0, 'short');
      },
    ),
    'Applicant (interview): decline a reschedule request': (
      'company_hr',
      () => ApplicantDetailScreen(data: _hrApplicant('interview')),
      (t) async {
        await _tapText(t, 'Decline');
        await _enter(t, 0, 'short');
      },
    ),
    'Student interview cancel dialog': (
      'student',
      () => StudentInterviewScreen(application: _studentApplication('interview')),
      (t) async {
        await _tapText(t, 'Cancel');
        await _enter(t, 0, 'short');
      },
    ),
    'Student applications: details sheet and accept offer dialog': (
      'student',
      () => const StudentApplicationsScreen(),
      (t) async {
        await _tapText(t, 'Offers');
        await _tapText(t, 'Accept offer');
        await _tapText(t, 'Not yet');
        await _tap(t, find.byType(AccentCard));
      },
    ),
    'Student profile: every edit form': (
      'student',
      () => const StudentProfileScreen(),
      (t) async {
        final edits = find.byIcon(Icons.edit_outlined).evaluate().length;
        for (var i = 0; i < edits; i++) {
          await _tap(t, find.byIcon(Icons.edit_outlined), index: i);
        }
        await _tap(t, find.byIcon(Icons.add), index: 0);
      },
    ),
    'Student profile: change password dialog': (
      'student',
      () => const StudentProfileScreen(),
      (t) async {
        await _tapText(t, 'Change password');
        await _enter(t, 0, 'a');
        await _enter(t, 1, 'b');
      },
    ),
    'Student documents tab': (
      'student',
      () => const StudentReportsScreen(),
      (t) async {
        await _tapText(t, 'Documents');
        await _tapText(t, 'Submissions');
      },
    ),
    'Staff profile: edit forms': (
      'company_hr',
      () => const StaffProfileScreen(),
      (t) async {
        final edits = find.byIcon(Icons.edit_outlined).evaluate().length;
        for (var i = 0; i < edits; i++) {
          await _tap(t, find.byIcon(Icons.edit_outlined), index: i);
        }
      },
    ),
    'HR postings: new posting form': (
      'company_hr',
      () => const HrPostingsScreen(),
      (t) async {
        await _tap(t, find.byType(FloatingActionButton));
        await _tapText(t, 'New posting');
      },
    ),
    'Admin companies: add dialog': (
      'admin',
      () => const AdminCompaniesScreen(),
      (t) async {
        await _tap(t, find.byType(FloatingActionButton));
        await _tap(t, find.byIcon(Icons.add));
      },
    ),
    'Admin intakes: add dialog': (
      'admin',
      () => const AdminIntakesScreen(),
      (t) async {
        await _tap(t, find.byType(FloatingActionButton));
        await _tap(t, find.byIcon(Icons.add));
      },
    ),
    'Admin: bulk student list with errors': (
      'admin',
      () => const AdminCreateStudentsScreen(),
      (t) async {
        await _tapText(t, 'Many (list / CSV)');
        await _enter(
          t,
          0,
          'ali@student.tarc.edu.my, Ali bin Abu, 24WMR12345\n$unbroken, $longName\nnot-an-email, Someone\nsiti@student.tarc.edu.my, , 99\n$unbroken, Duplicate Person',
        );
      },
    ),
    'Admin: one student form errors': (
      'admin',
      () => const AdminCreateStudentsScreen(),
      (t) async {
        await _enter(t, 0, '12');
        await _enter(t, 1, 'bad');
        await _enter(t, 2, 'abc');
      },
    ),
    'Reason dialog (long prompt)': (
      'student',
      () => Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showReasonDialog(
                    context,
                    title: 'Cancel interview with a rather long dialog title',
                    prompt: 'Tell $longName why the interview on Wed, 4 Nov 2026 at 10:30 AM at $longLocation is cancelled. They will see this reason.',
                    confirmLabel: 'Cancel interview',
                    hintText: 'e.g. The interviewer is unavailable on that day.',
                    destructive: true,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
      (t) async {
        await _tapText(t, 'open');
        await _enter(t, 0, 'short');
      },
    ),
  };

  cases.forEach((name, spec) {
    testWidgets('$name has no layout problems at any size', (tester) async {
      addTearDown(tester.view.reset);
      setFixtures(_tables(spec.$1));
      final problems = await checkLayout(tester, name, spec.$2, role: spec.$1, interact: spec.$3);
      expect(problems, isEmpty, reason: '\n${describeProblems(problems)}');
    }, timeout: const Timeout(Duration(minutes: 10)));
  });
}
