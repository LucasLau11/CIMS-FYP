import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/utils/letter_auto_values.dart';

void main() {
  final context = {
    'student': {
      'name': 'Aiman Hakim bin Razak',
      'reg_no': '25PMR99001',
      'ic': '030514-10-1234',
      'email': 'aiman@student.tarc.edu.my',
      'phone': '012-345 6789',
      'dob': '2003-05-14',
      'address': 'No. 18, Jalan Genting Klang, 53300 Setapak, Kuala Lumpur',
      'programme': 'Bachelor of Information Technology',
      'faculty': 'Faculty of Computing and Information Technology',
      'semester': 3,
      'cgpa': 3.45,
    },
    'company': {'name': 'Southern Steel Berhad', 'address': 'Perai, Pulau Pinang', 'supervisor': 'John', 'hr_name': 'Felix'},
    'internship': {'job_title': 'Automation Engineer', 'intake': 'June 2025', 'start': '2026-08-01', 'end': '2026-11-01', 'months': 3},
  };
  final values = letterValuesFromContext(context, today: DateTime(2026, 11, 16));

  test('every detail of the profile and the internship becomes a value, dates written dd/mm/yyyy', () {
    expect(values['student_name'], 'Aiman Hakim bin Razak');
    expect(values['student_ic'], '030514-10-1234');
    expect(values['student_dob'], '14/05/2003');
    expect(values['cgpa'], '3.45');
    expect(values['semester'], '3');
    expect(values['company_supervisor'], 'John');
    expect(values['internship_start'], '01/08/2026');
    expect(values['internship_end'], '01/11/2026');
    expect(values['internship_months'], '3');
    expect(values['today_date'], '16/11/2026');
  });

  test('what is not known is left out, so the field stays empty for the person to fill in', () {
    final sparse = letterValuesFromContext({'student': {'name': 'Aiman', 'ic': null, 'phone': ''}, 'company': {}, 'internship': {}});
    expect(sparse.containsKey('student_ic'), isFalse);
    expect(sparse.containsKey('student_phone'), isFalse);
    expect(sparse['student_name'], 'Aiman');
  });

  group('a field finds its value', () {
    test('by its key', () => expect(resolveLetterValue(values, key: 'company_name'), 'Southern Steel Berhad'));
    test('by a common name for the same thing', () {
      expect(resolveLetterValue(values, key: 'ic'), '030514-10-1234');
      expect(resolveLetterValue(values, key: 'NRIC'), '030514-10-1234');
      expect(resolveLetterValue(values, key: 'tel'), '012-345 6789');
      expect(resolveLetterValue(values, key: 'date'), '16/11/2026');
      expect(resolveLetterValue(values, key: 'company_supervisor'), 'John');
      expect(resolveLetterValue(values, key: 'start_date'), '01/08/2026');
    });
    test('ignoring a trailing number: the second company name is the company name again', () {
      expect(resolveLetterValue(values, key: 'company_name_2'), 'Southern Steel Berhad');
    });
    test('by its label when the key is a free name', () {
      expect(resolveLetterValue(values, key: 'text_3', label: 'Company address'), 'Perai, Pulau Pinang');
      expect(resolveLetterValue(values, key: 'x', label: 'Date of Birth'), '14/05/2003');
    });
    test('a field nobody knows stays empty', () {
      expect(resolveLetterValue(values, key: 'text', label: 'text'), isNull);
      expect(resolveLetterValue(values, key: 'allowance', label: 'Allowance'), isNull);
      expect(resolveLetterValue(values, key: 'working_hours', label: 'Working hours'), isNull);
    });
  });

  test('a date written dd/mm/yyyy reads back as a date, and an impossible one does not', () {
    expect(parseLetterDate('16/11/2026'), DateTime(2026, 11, 16));
    expect(parseLetterDate('31/02/2026'), isNull);
    expect(parseLetterDate('not a date'), isNull);
    expect(parseLetterDate(null), isNull);
  });
}
