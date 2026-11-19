import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/utils/student_import.dart';

void main() {
  group('StudentImport.parse', () {
    test('reads a list with a header row', () {
      final drafts = StudentImport.parse('email,full_name,student_reg_no,programme\n'
          'ali@student.tarc.edu.my,Ali bin Abu,24WMR12345,Software Engineering\n'
          'siti@student.tarc.edu.my,Siti Aminah,,\n');
      expect(drafts.length, 2);
      expect(drafts[0].ok, isTrue);
      expect(drafts[0].regNo, '24WMR12345');
      expect(drafts[0].programme, 'Software Engineering');
      expect(drafts[1].ok, isTrue);
      expect(drafts[1].regNo, isEmpty);
      expect(drafts[0].line, 2); // line numbers count the header
    });

    test('works without a header and finds the email whichever column it is in', () {
      final drafts = StudentImport.parse('Ali bin Abu, ali@student.tarc.edu.my, 24WMR12345\nsiti@student.tarc.edu.my, Siti Aminah');
      expect(drafts[0].email, 'ali@student.tarc.edu.my');
      expect(drafts[0].fullName, 'Ali bin Abu');
      expect(drafts[0].regNo, '24WMR12345');
      expect(drafts[1].fullName, 'Siti Aminah');
      expect(drafts.every((d) => d.ok), isTrue);
    });

    test('accepts semicolons, tabs and quoted values with commas', () {
      expect(StudentImport.parse('a@x.com;Ali Abu').single.fullName, 'Ali Abu');
      expect(StudentImport.parse('a@x.com\tAli Abu').single.fullName, 'Ali Abu');
      final quoted = StudentImport.parse('a@x.com,"Ali, bin Abu"').single;
      expect(quoted.fullName, 'Ali, bin Abu');
    });

    test('flags each problem on its own line without stopping the rest', () {
      final drafts = StudentImport.parse('good@x.com,Good Name\n'
          'not-an-email,Someone\n'
          'noname@x.com,\n'
          'badreg@x.com,Bad Reg,12345\n'
          'good@x.com,Duplicate Person');
      expect(drafts.map((d) => d.ok).toList(), [true, false, false, false, false]);
      expect(drafts[1].problem, contains('@'));
      expect(drafts[2].problem, contains('Full name'));
      expect(drafts[3].problem, contains('24WMR12345'));
      expect(drafts[4].problem, contains('more than once'));
      expect(drafts[4].line, 5);
    });

    test('ignores blank lines and returns nothing for empty text', () {
      expect(StudentImport.parse(''), isEmpty);
      expect(StudentImport.parse('\n\n   \n'), isEmpty);
      expect(StudentImport.parse('a@x.com,Ali Abu\n\n\nb@x.com,Siti Aminah').length, 2);
    });

    test('toJson only sends the optional fields that are filled', () {
      final d = StudentImport.parse('a@x.com,Ali Abu').single;
      expect(d.toJson(), {'email': 'a@x.com', 'full_name': 'Ali Abu'});
    });
  });
}
