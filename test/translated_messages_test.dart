import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/services/locale_controller.dart';
import 'package:fyp_cims/utils/error_text.dart';
import 'package:fyp_cims/utils/interview_format.dart';
import 'package:fyp_cims/utils/validators.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  tearDown(() => LocaleController.instance.currentLocale.value = const Locale('en'));

  void use(String code) => LocaleController.instance.currentLocale.value = Locale(code);

  test('validation messages follow the app language', () {
    use('en');
    final en = Validators.password('abc');
    use('ms');
    final ms = Validators.password('abc');
    use('zh');
    final zh = Validators.password('abc');
    expect({en, ms, zh}.length, 3, reason: 'one message per language');
    expect(en, startsWith('Password must be at least 8'));
    expect(ms, contains('Kata laluan'));
    expect(zh, contains('密码'));
  });

  test('a field name passed in English is translated inside the sentence', () {
    use('ms');
    expect(Validators.text('', field: 'The reason'), 'Sebab diperlukan.');
    use('zh');
    expect(Validators.text('', field: 'The reason'), '原因不能为空。');
    use('en');
    expect(Validators.text('', field: 'Something unlisted'), 'Something unlisted is required.');
  });

  test('database errors are shown in the app language', () {
    use('ms');
    expect(friendlyError(Exception('PostgrestException(message: boom)')), 'Sesuatu telah berlaku. Sila cuba lagi.');
    use('zh');
    expect(friendlyError(Exception('PostgrestException(message: boom)')), '出了点问题，请重试。');
  });

  test('interview dates use the language of the app', () {
    final d = DateTime(2026, 11, 4, 10, 30);
    use('en');
    expect(formatInterviewDateTime(d), 'Wed, 4 Nov 2026 at 10:30 AM');
    use('zh');
    expect(formatInterviewDay(d), '2026年11月4日 周三');
    expect(formatInterviewDayMonth(d), '11月4日');
    use('ms');
    expect(formatInterviewDateTime(d), contains(' pada '));
    expect(interviewWeekdayName(1), 'Isnin');
  });
}
