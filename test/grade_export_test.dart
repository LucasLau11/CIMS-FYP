import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/utils/grade_export.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

void main() {
  final complete = {
    'company': {
      'evaluated': true,
      'evaluator': 'John',
      'designation': 'Manager',
      'overall_grade': 'A',
      'attendance_with': 1,
      'attendance_without': 0,
      'comments': 'Reliable and learns quickly.',
      'training_notes': 'Software development team, 3 months.',
      'scores': {
        'technical_knowledge': 5,
        'dependability': 6,
        'initiative': 4,
        'commitment': 5,
        'quality_of_work': 5,
        'working_relationship': 6,
        'discipline': 5,
        'system_development_skills': 4,
        'punctuality': 6,
        'attendance': 6,
      },
    },
    'monthly': {
      'required': 3,
      'graded': 2,
      'points': 8.5,
      'items': [
        {'period': 'Month 1', 'grade': 8, 'status': 'approved', 'feedback': 'Good structure.'},
        {'period': 'Month 2', 'grade': 9, 'status': 'approved', 'feedback': 'Clear analysis.'},
        {'period': 'Month 3', 'grade': null, 'status': 'submitted', 'feedback': null},
      ],
    },
    'final': {
      'points': 25,
      'items': [
        {'period': 'Final report', 'grade': 25, 'status': 'approved', 'feedback': 'Well done.'}
      ],
    },
    'company_points': 52,
    'academic_points': 33.5,
    'total': 85.5,
    'complete': false,
  };

  int pages(List<int> bytes) {
    final doc = sf.PdfDocument(inputBytes: bytes);
    final n = doc.pages.count;
    doc.dispose();
    return n;
  }

  String text(List<int> bytes) {
    final doc = sf.PdfDocument(inputBytes: bytes);
    final t = sf.PdfTextExtractor(doc).extractText();
    doc.dispose();
    return t;
  }

  test('a grade slip is a PDF that shows the marks and the totals', () {
    final bytes = buildGradeSlipsPdf([GradeSlip(studentName: 'Aiman Hakim bin Razak', regNo: '25PMR99001', programme: 'BIT', intake: 'June 2025', grade: complete)]);
    expect(bytes.length, greaterThan(1000));
    final t = text(bytes);
    expect(t, contains('Aiman Hakim bin Razak'));
    expect(t, contains('85.5'));
    expect(t, contains('Technical knowledge'));
    expect(t, contains('3 required by the intake'));
    expect(t, contains('not complete yet'));
  });

  test('one page (at least) per student in a batch', () {
    final slips = [for (var i = 0; i < 4; i++) GradeSlip(studentName: 'Student $i', grade: complete)];
    expect(pages(buildGradeSlipsPdf(slips)), greaterThanOrEqualTo(4));
  });

  test('a student with nothing graded yet still gets a slip, and a name that is not Latin does not break it', () {
    final empty = {'company': {'evaluated': false}, 'monthly': {'items': []}, 'final': {'items': []}, 'company_points': 0, 'academic_points': 0, 'total': 0, 'complete': false};
    final bytes = buildGradeSlipsPdf([GradeSlip(studentName: '林小明 Lim', grade: empty)]);
    expect(pages(bytes), greaterThanOrEqualTo(1));
    expect(text(bytes), contains('has not evaluated this student yet'));
  });

  test('the spreadsheet has a header and one row per student, with quotes and commas escaped', () {
    final csv = buildGradesCsv([
      {
        'full_name': 'Tan, Wei "Jie"',
        'student_reg_no': '25PMR1',
        'programme': 'BIT',
        'internship_status': 'active',
        'company_points': 52,
        'monthly_points': 8.5,
        'final_points': 25,
        'academic_points': 33.5,
        'total': 85.5,
        'overall_grade': 'A',
        'monthly_graded': 2,
        'monthly_required': 3,
        'complete': false,
      }
    ]);
    final lines = csv.trim().split('\r\n');
    expect(lines.length, 2);
    expect(lines[0], contains('Total (100)'));
    expect(lines[1], contains('"Tan, Wei ""Jie"""'));
    expect(lines[1], contains('85.5'));
    expect(lines[1], endsWith('No'));
  });
}
