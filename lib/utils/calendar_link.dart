import 'package:url_launcher/url_launcher.dart';

/// A link that opens the phone's calendar (or the browser) with a new event
/// already filled in, so people can add an interview to their own calendar.
/// No calendar permission or extra plugin is needed.
Uri interviewCalendarUri({
  required String title,
  required DateTime start,
  required DateTime end,
  String? location,
  String? details,
}) {
  String stamp(DateTime t) {
    final u = t.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${u.year.toString().padLeft(4, '0')}${two(u.month)}${two(u.day)}T${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
  }

  return Uri.https('calendar.google.com', '/calendar/render', {
    'action': 'TEMPLATE',
    'text': title,
    'dates': '${stamp(start)}/${stamp(end)}',
    if (location != null && location.isNotEmpty) 'location': location,
    if (details != null && details.isNotEmpty) 'details': details,
  });
}

/// Opens [interviewCalendarUri]. Returns false when nothing could open it.
Future<bool> addInterviewToCalendar({
  required String title,
  required DateTime start,
  required DateTime end,
  String? location,
  String? details,
}) async {
  final uri = interviewCalendarUri(title: title, start: start, end: end, location: location, details: details);
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
