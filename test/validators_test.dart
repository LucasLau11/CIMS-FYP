import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/utils/validators.dart';

void main() {
  group('email', () {
    test('accepts allowed domains', () {
      expect(Validators.email('lauyh-pm23@student.tarc.edu.my'), isNull);
      expect(Validators.email('Felix.HR+jobs@gmail.com'), isNull);
      expect(Validators.email('  name@outlook.com  '), isNull);
    });

    test('explains exactly what is wrong', () {
      expect(Validators.email(''), 'Email is required.');
      expect(Validators.email('name'), contains('"@"'));
      expect(Validators.email('name@'), contains('valid email'));
      expect(Validators.email('name@gmail'), contains('valid email'));
      expect(Validators.email('name@yahoo.com'), contains('must end with'));
    });
  });

  group('password', () {
    test('accepts a strong password', () {
      expect(Validators.password('Str0ng!pass'), isNull);
    });

    test('reports the first missing rule, in order', () {
      expect(Validators.password(''), 'Password is required.');
      expect(Validators.password('Ab1!'), contains('at least 8'));
      expect(Validators.password('lowercase1!'), contains('uppercase'));
      expect(Validators.password('UPPERCASE1!'), contains('lowercase'));
      expect(Validators.password('NoNumbers!!'), contains('number'));
      expect(Validators.password('NoSymbols11'), contains('symbol'));
    });

    test('rejects passwords longer than bcrypt reads', () {
      expect(Validators.password('Aa1!${'x' * 80}'), contains('at most 72'));
    });

    test('checklist matches the rules', () {
      final weak = Validators.passwordChecks('abc');
      expect(weak.where((c) => c.met).length, 1); // only lowercase
      final strong = Validators.passwordChecks('Str0ng!pass');
      expect(strong.every((c) => c.met), isTrue);
    });

    test('confirmation must match', () {
      expect(Validators.confirmPassword('', 'x'), contains('Re-enter'));
      expect(Validators.confirmPassword('y', 'x'), 'Passwords do not match.');
      expect(Validators.confirmPassword('x', 'x'), isNull);
    });
  });

  group('otp code', () {
    test('accepts a 6 to 10 digit code (Supabase default is 6, this project sends 8)', () {
      expect(Validators.otpCode(''), contains('code from your email'));
      expect(Validators.otpCode('12a456'), contains('digits only'));
      expect(Validators.otpCode('123'), contains('entered 3'));
      expect(Validators.otpCode('12345678901'), contains('at most 10'));
      expect(Validators.otpCode('123456'), isNull);
      expect(Validators.otpCode('12345678'), isNull);
    });
  });

  group('names and phone', () {
    test('full name', () {
      expect(Validators.fullName(''), contains('required'));
      expect(Validators.fullName('A'), contains('too short'));
      expect(Validators.fullName('Lau Yik Hong'), isNull);
      expect(Validators.fullName("Nur Aisyah binti Abdul-Rahman"), isNull);
      expect(Validators.fullName("O'Brien"), isNull);
      expect(Validators.fullName('刘益宏'), isNull);
      expect(Validators.fullName('John3'), contains('letters'));
      expect(Validators.fullName('x' * 101), contains('at most 100'));
    });

    test('phone accepts Malaysian and international numbers', () {
      expect(Validators.phone('012-345 6789'), isNull);
      expect(Validators.phone('0123456789'), isNull);
      expect(Validators.phone('011-2345 6789'), isNull);
      expect(Validators.phone('+60 12-345 6789'), isNull);
      expect(Validators.phone('03-1234 5678'), isNull);
      expect(Validators.phone('+65 9123 4567'), isNull);
    });

    test('phone rejects bad input with a reason', () {
      expect(Validators.phone(''), contains('required'));
      expect(Validators.phone('', required: false), isNull);
      expect(Validators.phone('12345'), contains('valid phone'));
      expect(Validators.phone('abc'), contains('only contain digits'));
      expect(Validators.phone('012-345'), contains('valid phone'));
    });
  });

  group('dates', () {
    final today = DateTime(2026, 11, 3);

    test('date of birth', () {
      expect(Validators.dateOfBirth(null), contains('required'));
      expect(Validators.dateOfBirth(DateTime(2027, 1, 1), today: today), contains('future'));
      expect(Validators.dateOfBirth(DateTime(2015, 1, 1), today: today), contains('at least 15'));
      expect(Validators.dateOfBirth(DateTime(1900, 1, 1), today: today), contains('valid date'));
      expect(Validators.dateOfBirth(DateTime(2003, 5, 14), today: today), isNull);
      // 15th birthday not yet reached today
      expect(Validators.dateOfBirth(DateTime(2011, 11, 4), today: today), contains('at least 15'));
      expect(Validators.dateOfBirth(DateTime(2011, 11, 3), today: today), isNull);
      // the student profile requires 17
      expect(Validators.dateOfBirth(DateTime(2010, 1, 1), today: today, minAge: 17), contains('at least 17'));
      expect(Validators.dateOfBirth(DateTime(2009, 1, 1), today: today, minAge: 17), isNull);
    });

    test('not in the past', () {
      expect(Validators.dateNotInPast(DateTime(2026, 11, 2), today: today), contains('past'));
      expect(Validators.dateNotInPast(DateTime(2026, 11, 3), today: today), isNull);
      expect(Validators.dateNotInPast(null, field: 'Deadline'), 'Deadline is required.');
    });

    test('end must be after start', () {
      final start = DateTime(2026, 3, 1);
      expect(Validators.endAfterStart(start, null), contains('required'));
      expect(Validators.endAfterStart(start, DateTime(2026, 3, 1)), contains('after'));
      expect(Validators.endAfterStart(start, DateTime(2026, 2, 1)), contains('after'));
      expect(Validators.endAfterStart(start, DateTime(2026, 8, 1)), isNull);
      expect(Validators.endAfterStart(null, DateTime(2026, 8, 1)), isNull);
    });

    test('date-time in the future with a lead time', () {
      final now = DateTime(2026, 11, 3, 10);
      expect(Validators.dateTimeInFuture(DateTime(2026, 11, 3, 9), now: now), contains('future'));
      expect(
        Validators.dateTimeInFuture(DateTime(2026, 11, 3, 11),
            minLead: const Duration(hours: 2), now: now),
        contains('2 hours'),
      );
      expect(
        Validators.dateTimeInFuture(DateTime(2026, 11, 3, 13),
            minLead: const Duration(hours: 2), now: now),
        isNull,
      );
    });
  });

  group('academic and numbers', () {
    test('cgpa', () {
      expect(Validators.cgpa(''), contains('required'));
      expect(Validators.cgpa('', required: false), isNull);
      expect(Validators.cgpa('3.5'), isNull);
      expect(Validators.cgpa('4'), isNull);
      expect(Validators.cgpa('4.00'), isNull);
      expect(Validators.cgpa('4.01'), contains('between 0.00 and 4.00'));
      expect(Validators.cgpa('3.555'), contains('2 decimals'));
      expect(Validators.cgpa('abc'), contains('2 decimals'));
      expect(Validators.cgpa('-1'), contains('2 decimals'));
    });

    test('semester', () {
      expect(Validators.semester(null), contains('Select'));
      expect(Validators.semester(0), contains('between 1 and 4'));
      expect(Validators.semester(5), contains('between 1 and 4'));
      expect(Validators.semester(4), isNull);
      expect(Validators.semester(6, max: 8), isNull);
    });

    test('student registration number', () {
      expect(Validators.studentRegNo(''), isNull);
      expect(Validators.studentRegNo('', required: true), contains('required'));
      expect(Validators.studentRegNo('24WMR12345'), isNull);
      expect(Validators.studentRegNo('24wmr12345'), isNull);
      expect(Validators.studentRegNo('2024WMR1234'), contains('24WMR12345'));
      expect(Validators.studentRegNo('24WMR1234'), contains('24WMR12345'));
    });

    test('skill tags', () {
      expect(Validators.skill(''), isNull);
      expect(Validators.skill('C'), contains('at least 2'));
      expect(Validators.skill('Java'), isNull);
      expect(Validators.skill('C++'), isNull);
      expect(Validators.skill('C#'), isNull);
      expect(Validators.skill('Public Speaking'), isNull);
      expect(Validators.skill('Java!!'), contains('may only use'));
      expect(Validators.skill('java', existing: ['Java']), contains('already'));
      expect(Validators.skill('x' * 41), contains('at most 40'));
      expect(Validators.skill('New', existing: List.generate(30, (i) => 's$i')), contains('at most 30'));
    });

    test('whole numbers and money', () {
      expect(Validators.wholeNumber('3', field: 'Duration', min: 1, max: 12), isNull);
      expect(Validators.wholeNumber('0', field: 'Duration', min: 1, max: 12), contains('between 1 and 12'));
      expect(Validators.wholeNumber('2.5', field: 'Duration', min: 1, max: 12), contains('whole number'));
      expect(Validators.money('800', field: 'Allowance'), isNull);
      expect(Validators.money('800.50', field: 'Allowance'), isNull);
      expect(Validators.money('-5', field: 'Allowance'), contains('number such as'));
      expect(Validators.money('800.555', field: 'Allowance'), contains('number such as'));
      expect(Validators.money('', field: 'Allowance', required: false), isNull);
      expect(Validators.money('999999', field: 'Allowance'), contains('too large'));
    });

    test('year', () {
      final today = DateTime(2026, 11, 3);
      expect(Validators.year('2023', today: today), isNull);
      expect(Validators.year('1979', today: today), contains('between 1980'));
      expect(Validators.year('2099', today: today), contains('between 1980'));
    });
  });

  group('text, url and rating', () {
    test('text length limits report the current length', () {
      expect(Validators.text('', field: 'Reason'), 'Reason is required.');
      expect(Validators.text('short', field: 'Reason', min: 10), contains('at least 10 characters (now 5)'));
      expect(Validators.text('x' * 11, field: 'Reason', max: 10), contains('at most 10'));
      expect(Validators.text('   ', field: 'Note', required: false), isNull);
      expect(Validators.text('a valid reason', field: 'Reason', min: 10), isNull);
    });

    test('url', () {
      expect(Validators.url(''), isNull);
      expect(Validators.url('', required: true), contains('required'));
      expect(Validators.url('meet.google.com/abc'), contains('https://'));
      expect(Validators.url('https://meet.google.com/abc-defg-hij'), isNull);
      expect(Validators.url('ftp://x.com'), contains('https://'));
    });

    test('rating', () {
      expect(Validators.rating(null), contains('required'));
      expect(Validators.rating(0), contains('between 1 and 5'));
      expect(Validators.rating(6), contains('between 1 and 5'));
      expect(Validators.rating(4), isNull);
    });
  });
}
