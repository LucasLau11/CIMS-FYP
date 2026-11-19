import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/l10n/app_localizations.dart';
import 'package:fyp_cims/services/interview_service.dart';
import 'package:fyp_cims/utils/interview_format.dart';
import 'package:fyp_cims/widgets/interview_slot_picker.dart';

Widget _host(Widget child) => MaterialApp(
    localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
    supportedLocales: const [Locale('en')],
    home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)));

InterviewSlot _slot(DateTime start, {int minutes = 30}) => InterviewSlot(start: start, end: start.add(Duration(minutes: minutes)));

Map<String, dynamic> _embed({required DateTime start, String status = 'scheduled', List<Map<String, dynamic>> changes = const []}) => {
      'interview_id': 'i1',
      'interviewer_id': 'hr1',
      'scheduled_at': start.toUtc().toIso8601String(),
      'ends_at': start.add(const Duration(minutes: 30)).toUtc().toIso8601String(),
      'mode': 'online',
      'location': 'https://meet.example.com/x',
      'status': status,
      'interview_changes': changes,
    };

void main() {
  group('InterviewInfo', () {
    test('an interview 3 hours away can still be changed, one 1 hour away cannot', () {
      final soon = InterviewInfo.fromEmbed(_embed(start: DateTime.now().add(const Duration(hours: 1))))!;
      final later = InterviewInfo.fromEmbed(_embed(start: DateTime.now().add(const Duration(hours: 3))))!;
      expect(soon.canBeChanged, isFalse);
      expect(later.canBeChanged, isTrue);
    });

    test('a cancelled interview can never be changed', () {
      final iv = InterviewInfo.fromEmbed(_embed(start: DateTime.now().add(const Duration(days: 2)), status: 'cancelled'))!;
      expect(iv.isCancelled, isTrue);
      expect(iv.canBeChanged, isFalse);
    });

    test('the latest change with a reason is exposed, oldest first ordering', () {
      final start = DateTime.now().add(const Duration(days: 2));
      final iv = InterviewInfo.fromEmbed(_embed(start: start, changes: [
        {'action': 'cancelled', 'actor_role': 'student', 'reason': 'Second thoughts, sorry.', 'old_start': null, 'new_start': null, 'created_at': '2026-11-03T10:00:00Z'},
        {'action': 'booked', 'actor_role': 'company_hr', 'reason': null, 'old_start': null, 'new_start': null, 'created_at': '2026-11-01T10:00:00Z'},
      ]))!;
      expect(iv.changes.first.action, 'booked');
      expect(iv.lastReasonedChange!.reason, 'Second thoughts, sorry.');
      expect(iv.lastReasonedChange!.actorLabel, 'The student');
    });

    test('a pending reschedule request is exposed until it is answered or the interview is cancelled', () {
      final start = DateTime.now().add(const Duration(days: 2));
      Map<String, dynamic> request(String status) => {
            'request_id': 'r1',
            'requested_by': 'u1',
            'requested_role': 'student',
            'proposed_start': start.add(const Duration(days: 1)).toUtc().toIso8601String(),
            'proposed_end': start.add(const Duration(days: 1, minutes: 30)).toUtc().toIso8601String(),
            'reason': 'I have an exam at the original time.',
            'status': status,
            'created_at': '2026-11-03T10:00:00Z',
          };
      final waiting = _embed(start: start)..['interview_reschedule_requests'] = [request('pending')];
      final iv = InterviewInfo.fromEmbed(waiting)!;
      expect(iv.pendingRequest, isNotNull);
      expect(iv.pendingRequest!.byStudent, isTrue);

      final answered = _embed(start: start)..['interview_reschedule_requests'] = [request('declined')];
      expect(InterviewInfo.fromEmbed(answered)!.pendingRequest, isNull);

      final cancelled = _embed(start: start, status: 'cancelled')..['interview_reschedule_requests'] = [request('pending')];
      expect(InterviewInfo.fromEmbed(cancelled)!.pendingRequest, isNull);
    });

    test('no interview embed gives null', () {
      expect(InterviewInfo.fromEmbed(null), isNull);
    });
  });

  group('formatting', () {
    test('formats day and 12-hour time', () {
      final d = DateTime(2026, 11, 4, 14, 0);
      expect(formatInterviewDay(d), 'Wed, 4 Nov 2026');
      expect(formatInterviewTime(d), '2:00 PM');
      expect(formatInterviewTime(DateTime(2026, 11, 4, 0, 5)), '12:05 AM');
    });
  });

  group('InterviewSlotPicker', () {
    testWidgets('lists days that have free slots and reports the chosen time', (tester) async {
      final day1 = DateTime.now().add(const Duration(days: 1));
      final day2 = DateTime.now().add(const Duration(days: 2));
      final s1 = _slot(DateTime(day1.year, day1.month, day1.day, 9, 0));
      final s2 = _slot(DateTime(day1.year, day1.month, day1.day, 9, 30));
      final s3 = _slot(DateTime(day2.year, day2.month, day2.day, 14, 0));
      InterviewSlot? chosen;

      await tester.pumpWidget(_host(InterviewSlotPicker(
        loadSlots: (from, to) async => [s1, s2, s3],
        onChanged: (s) => chosen = s,
      )));
      await tester.pumpAndSettle();

      expect(find.text('2 free'), findsOneWidget);
      expect(find.text('1 free'), findsOneWidget);
      expect(find.text('9:00 AM'), findsOneWidget);
      expect(find.text('9:30 AM'), findsOneWidget);

      await tester.tap(find.text('9:30 AM'));
      await tester.pump();
      expect(chosen, s2);

      // switching day clears the choice
      await tester.tap(find.text('1 free'));
      await tester.pump();
      expect(chosen, isNull);
      expect(find.text('2:00 PM'), findsOneWidget);
    });

    testWidgets('says so when there are no free slots and offers the action', (tester) async {
      await tester.pumpWidget(_host(InterviewSlotPicker(
        loadSlots: (from, to) async => [],
        onChanged: (_) {},
        emptyAction: const Text('Set my availability'),
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('No free interview times'), findsOneWidget);
      expect(find.text('Set my availability'), findsOneWidget);
    });

    testWidgets('shows a friendly error and lets the person retry', (tester) async {
      var calls = 0;
      await tester.pumpWidget(_host(InterviewSlotPicker(
        loadSlots: (from, to) async {
          calls++;
          if (calls == 1) throw Exception('You cannot view these interview slots.');
          return [];
        },
        onChanged: (_) {},
      )));
      await tester.pumpAndSettle();
      expect(find.text('You cannot view these interview slots.'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.textContaining('No free interview times'), findsOneWidget);
    });
  });
}
