import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/l10n/app_localizations.dart';
import 'package:fyp_cims/screens/student/student_interview_screen.dart';
import 'package:fyp_cims/services/interview_service.dart';
import 'package:fyp_cims/theme/app_theme.dart';

import 'layout/fixtures.dart';
import 'layout/layout_harness.dart';

Map<String, dynamic> _studentApplication() {
  final a = application('interview', withInterview: true);
  return {
    ...a,
    'id': a['application_id'],
    'internships': {...posting(), 'id': postingId, 'company_name': longCompany},
    'interview': InterviewInfo.fromEmbed(a['interviews']),
  };
}

Future<void> _pumpScreen(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.theme,
    localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
    supportedLocales: const [Locale('en')],
    home: home,
  ));
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async {
    await initFakeSupabase(tables: studentTables());
  });

  tearDown(() => setFixtures(studentTables()));

  // Regression: the company declined the student's reschedule request, but the
  // screen kept showing the copy of the interview it was opened with, so the
  // student saw a request that was still waiting and no Reschedule button.
  testWidgets('a request declined while the screen was stale no longer blocks a new reschedule', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // The student asked to move it earlier, and the copy handed to the screen says it is still pending.
    final snapshot = _studentApplication();
    final stale = snapshot['interview'] as InterviewInfo;
    expect(stale.pendingRequest, isNotNull, reason: 'the fixture starts with a pending request');

    // In the database that request has since been declined.
    final fresh = interview();
    (fresh['interview_reschedule_requests'] as List).first['status'] = 'declined';
    (fresh['interview_reschedule_requests'] as List).first['response_note'] = 'That day we are fully booked, sorry.';
    setFixtures({...studentTables(), 'interviews': [fresh]});

    await _pumpScreen(tester, StudentInterviewScreen(application: snapshot));

    expect(find.text('Reschedule'), findsOneWidget, reason: 'a declined request must not block asking for another time');
    expect(find.text('Decline'), findsNothing, reason: 'the declined request is no longer waiting for an answer');
  });

  test('InterviewInfo only counts a request as waiting while it is pending', () {
    InterviewInfo withStatus(String status) {
      final row = interview();
      (row['interview_reschedule_requests'] as List).first['status'] = status;
      return InterviewInfo.fromEmbed(row)!;
    }

    expect(withStatus('pending').pendingRequest, isNotNull);
    for (final s in ['declined', 'accepted', 'withdrawn', 'expired']) {
      expect(withStatus(s).pendingRequest, isNull, reason: '$s is an answered request');
    }
  });
}
