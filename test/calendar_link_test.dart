import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/utils/calendar_link.dart';

void main() {
  test('the calendar link carries the title, UTC times and place', () {
    final uri = interviewCalendarUri(
      title: 'Interview: Flutter Intern',
      start: DateTime.utc(2026, 11, 20, 2, 0),
      end: DateTime.utc(2026, 11, 20, 2, 30),
      location: 'https://meet.example.com/abc',
      details: 'CIMS interview',
    );
    expect(uri.host, 'calendar.google.com');
    expect(uri.queryParameters['action'], 'TEMPLATE');
    expect(uri.queryParameters['text'], 'Interview: Flutter Intern');
    expect(uri.queryParameters['dates'], '20261120T020000Z/20261120T023000Z');
    expect(uri.queryParameters['location'], 'https://meet.example.com/abc');
  });

  test('an empty location is left out', () {
    final uri = interviewCalendarUri(title: 't', start: DateTime.utc(2026, 1, 1), end: DateTime.utc(2026, 1, 1, 1), location: '');
    expect(uri.queryParameters.containsKey('location'), isFalse);
  });

  test('local times are converted to UTC', () {
    final local = DateTime(2026, 11, 20, 10, 0); // whatever the test machine's zone is
    final uri = interviewCalendarUri(title: 't', start: local, end: local.add(const Duration(minutes: 30)));
    final expected = local.toUtc();
    expect(uri.queryParameters['dates']!.startsWith('${expected.year}'), isTrue);
    expect(uri.queryParameters['dates']!.split('/').first.endsWith('Z'), isTrue);
  });
}
