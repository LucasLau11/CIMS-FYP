import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/services/resume_parser_service.dart';

/// Layouts the regex parser used to get wrong. They were found by the fake-resume accuracy test
/// (nlp_service/eval), and each one is pinned here so it cannot quietly break again.
void main() {
  final parser = ResumeParserService.instance;

  test('skills written on one line after "Skills:" are found', () {
    final r = parser.parse('Ali bin Abu\nSkills: Python, Java, SQL\n');
    expect(r.skills, ['Python', 'Java', 'SQL']);
  });

  test('a category label in front of the first skill is dropped', () {
    final r = parser.parse('Ali bin Abu\n\nTechnical Skills\nProgramming: Python, Java\nTools: Git, Docker\n\nEducation\n');
    expect(r.skills, containsAll(['Python', 'Java', 'Git', 'Docker']));
    expect(r.skills.any((s) => s.contains(':')), isFalse);
  });

  test('a title in front of the name is not part of it', () {
    expect(parser.parse('Ms. Siti Aminah\nPhone: 012-345 6789\n').fullName, 'Siti Aminah');
    expect(parser.parse('Encik Ali bin Abu\nPhone: 012-345 6789\n').fullName, 'Ali bin Abu');
  });

  test('Malaysian "a/l" and "a/p" names are accepted', () {
    expect(parser.parse('Priya a/p Rajan\nPhone: 012-345 6789\n').fullName, 'Priya a/p Rajan');
    expect(parser.parse('Arjun a/l Krishnan\n').fullName, 'Arjun a/l Krishnan');
  });

  test('a faculty written as "Faculty of ..." is found, on its own line or in brackets', () {
    expect(parser.parse('Ali\nDiploma in IT\nFaculty of Computing and Information Technology\nSemester: 3\n').faculty,
        'Faculty of Computing and Information Technology');
    expect(parser.parse('Studying Diploma in Accounting (Faculty of Accountancy, Finance and Business). Semester: 4.').faculty,
        'Faculty of Accountancy, Finance and Business');
    expect(parser.parse('Faculty: Engineering\n').faculty, 'Engineering');
  });

  test('"Position, Company" splits into position and company', () {
    final r = parser.parse('Ali\n\nWork Experience\nGraphic Designer, Maybank Technology  2022 - 2024\n');
    expect(r.workExperience, hasLength(1));
    expect(r.workExperience.first.position, 'Graphic Designer');
    expect(r.workExperience.first.companyName, 'Maybank Technology');
  });

  test('"Position at Company" still works', () {
    final r = parser.parse('Ali\n\nExperience\nWeb Developer at Intel Malaysia   2023 - Present\n');
    expect(r.workExperience.first.position, 'Web Developer');
    expect(r.workExperience.first.companyName, 'Intel Malaysia');
    expect(r.workExperience.first.isCurrent, isTrue);
  });

  test('without the on-device model, the scan gives exactly the regex result', () async {
    // flutter test has no TensorFlow Lite library, so the model cannot load: the scan must not fail.
    const text = 'Ali bin Abu\nPhone: 012-345 6789\nBuilt dashboards with Power BI and SQL.\n';
    final r = await parser.parseOnDevice(text);
    final plain = parser.parse(text);
    expect(r.fullName, plain.fullName);
    expect(r.skills, plain.skills);
    expect(r.source, 'regex');
  });

  test('a resume with a skills list never reaches the model', () async {
    final r = await parser.parseOnDevice('Ali bin Abu\nSkills: Python, SQL\n');
    expect(r.skills, ['Python', 'SQL']);
    expect(r.source, 'regex');
  });

  group('real-resume mistakes (postcode as phone, skills as name, references as skills)', () {
    test('a postcode is never the phone number', () {
      const text = 'LAU YIK HONG\nNo. 12, Jalan Universiti, 05050 Alor Setar, Kedah\nlau@gmail.com\n+60 12-345 6789\n';
      expect(parser.parse(text).phone, '+60 12-345 6789');
      // no phone at all: nothing is better than a postcode
      expect(parser.parse('LAU YIK HONG\n11900 Bayan Lepas, Penang\nlau@gmail.com\n').phone, isNull);
    });

    test('people write Malaysian numbers with +60, 60 or 0 in front, with or without dashes and spaces', () {
      for (final written in ['+60123456789', '+60 12-345 6789', '(+60) 12 345 6789', '012-3456789', '012 345 6789', '60123456789', '011-2345 6789', '03-1234 5678']) {
        expect(parser.parse('Lau Yik Hong\nTel: $written\n').phone, isNotNull, reason: written);
        final found = parser.parse('Lau Yik Hong\n$written | lau@gmail.com\n').phone;
        expect(found?.replaceAll(RegExp(r'\D'), ''), written.replaceAll(RegExp(r'\D'), ''), reason: written);
      }
    });

    test('a year range, an IC number or a student ID is not a phone number', () {
      const text = 'Lau Yik Hong\nIC No: 020312-10-1234\nStudent ID: 22WMR01234\n2022 - 2025\nlau@gmail.com\n';
      expect(parser.parse(text).phone, isNull);
    });

    test('a number after the postcode on the same line is found', () {
      expect(parser.parse('Lau Yik Hong\n11900 012-345 6789\n').phone, '012-345 6789');
    });

    test("the referee's number is not the candidate's", () {
      const text = 'Lau Yik Hong\nlau@gmail.com\n\nEducation\nDiploma in IT\n\nWork\nx\n\nSkills\nPython\n\nREFERENCES\nDr. Ahmad\nTel: 012-999 8888\n';
      expect(parser.parse(text).phone, isNull);
    });

    test('a list of skills is not the name, and the name next to a job title is', () {
      expect(parser.parse('SKILLS\nPython Java\nMicrosoft Office\n').fullName, isNull);
      expect(parser.parse('LAU YIK HONG | Software Developer\nlau@gmail.com\n').fullName, 'LAU YIK HONG');
      expect(parser.parse('Software Developer | Lau Yik Hong\n').fullName, 'Lau Yik Hong');
      expect(parser.parse('Problem Solving\nTeam Leadership\nLau Yik Hong\nlau@gmail.com\n').fullName, 'Lau Yik Hong');
    });

    test('references, awards and activities are not skills, whatever the heading says', () {
      const text = 'Lau Yik Hong\n\nSKILLS\nPython, Java, SQL\n\nREFEREES\nDr. Ahmad bin Ismail\nSenior Lecturer, TAR UMT\nTel: 012-345 6789\nahmad@tarc.edu.my\n\n'
          'AWARDS, HONOURS & CO-CURRICULAR\nDean\'s List 2024\n';
      expect(parser.parse(text).skills, ['Python', 'Java', 'SQL']);
      expect(parser.parse('Lau Yik Hong\nSkills\nPython\nDr. Ahmad bin Ismail\nahmad@tarc.edu.my\n').skills, ['Python']);
    });
  });
}
