import 'package:intl/intl.dart';

import '../services/locale_controller.dart';

/// Date and time text for interviews, in the language the app is showing.
/// English keeps the compact style the app has always used ("Wed, 4 Nov 2026",
/// "10:30 AM"); Malay and Chinese use their own order and names.
String _lang() => LocaleController.instance.currentLocale.value.languageCode;

String _format(String enPattern, String zhPattern, DateTime t) {
  final lang = _lang();
  if (lang != 'en') {
    try {
      return DateFormat(lang == 'zh' ? zhPattern : enPattern, lang).format(t);
    } catch (_) {
      // The language's date data is not loaded yet: fall through to English rather than crash.
    }
  }
  // No locale given = the built-in English data, which needs no set-up.
  return DateFormat(enPattern).format(t);
}

/// "Wed, 4 Nov 2026" / "Rab, 4 Nov 2026" / "2026年11月4日 周三"
String formatInterviewDay(DateTime d) => _format('EEE, d MMM y', 'y年M月d日 EEE', d);

/// "10:30 AM" / "上午10:30"
String formatInterviewTime(DateTime t) => _format('h:mm a', 'ah:mm', t);

/// "Wed, 4 Nov 2026 at 10:30 AM"
String formatInterviewDateTime(DateTime t) {
  final joiner = switch (_lang()) {
    'ms' => ' pada ',
    'zh' => ' ',
    _ => ' at ',
  };
  return '${formatInterviewDay(t)}$joiner${formatInterviewTime(t)}';
}

/// "Wed" / "Rab" / "周三" - for the day chips in the time picker.
String formatInterviewWeekdayShort(DateTime d) => _format('EEE', 'EEE', d);

/// "4 Nov" / "11月4日" - for the day chips in the time picker.
String formatInterviewDayMonth(DateTime d) => _format('d MMM', 'M月d日', d);

/// Full weekday name for 1 = Monday ... 7 = Sunday ("Monday", "Isnin", "星期一").
String interviewWeekdayName(int isoWeekday) {
  // 1 Jan 2024 was a Monday.
  final d = DateTime(2024, 1, isoWeekday);
  return _format('EEEE', 'EEEE', d);
}

/// Short weekday name for 1 = Monday ... 7 = Sunday ("Mon", "Isn", "周一").
String interviewWeekdayNameShort(int isoWeekday) => formatInterviewWeekdayShort(DateTime(2024, 1, isoWeekday));
