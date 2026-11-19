import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/utils/grading_rubric.dart';

/// The university rubric: a progress report is marked out of 10 (submission 4 + content 6), the final report
/// out of 30 (submission 4 + written 6 + business awareness 10 + overall content 10). Together with the
/// average of the progress reports (10) and the final report (30) they make the academic supervisor's 40.
void main() {
  test('the marks add up to 10 for a progress report and 30 for the final report', () {
    expect(rubricMaxTotal(isFinal: false), 10);
    expect(rubricMaxTotal(isFinal: true), 30);
    expect(rubricMaxTotal(isFinal: false) + rubricMaxTotal(isFinal: true), 40);
  });

  test('every mark of every criterion falls in exactly one band', () {
    for (final isFinal in [false, true]) {
      for (final c in rubricFor(isFinal: isFinal)) {
        for (var m = 0; m <= c.maxMark; m++) {
          expect(c.bands.where((b) => b.contains(m)).length, 1, reason: '${c.key} mark $m (final: $isFinal)');
        }
        expect(c.bandOf(c.maxMark)!.label(), 'Excellent');
        expect(c.bandOf(0)!.label(), 'Very Poor');
      }
    }
  });

  test('the criteria keys match what the database checks', () {
    expect([for (final c in progressReportRubric) c.key], ['submission', 'content']);
    expect([for (final c in finalReportRubric) c.key], ['submission', 'written', 'awareness', 'content']);
  });

  test('marksSummary lists each mark out of its maximum', () {
    expect(marksSummary({'submission': 4, 'content': 5}, isFinal: false), 'Submission 4/4 · Content 5/6');
    expect(marksSummary(null, isFinal: true), '');
  });

  test('the company evaluation has 10 criteria of 6 marks: 60 in all', () {
    expect(companyEvaluationRubric.length, 10);
    expect(companyEvaluationMaxTotal, 60);
    expect([for (final c in companyEvaluationRubric) c.key], [
      'technical_knowledge', 'dependability', 'initiative', 'commitment', 'quality_of_work',
      'working_relationship', 'discipline', 'system_development_skills', 'punctuality', 'attendance',
    ]);
    for (final c in companyEvaluationRubric) {
      expect(c.maxMark, 6);
      for (var m = 0; m <= 6; m++) {
        expect(c.bands.where((b) => b.contains(m)).length, 1, reason: '${c.key} mark $m');
      }
      expect(c.bandOf(0)!.label(), 'Very Poor');
      expect(c.bandOf(2)!.label(), 'Poor');
      expect(c.bandOf(3)!.label(), 'Average');
      expect(c.bandOf(5)!.label(), 'Good');
      expect(c.bandOf(6)!.label(), 'Excellent');
    }
  });

  test('the overall grades are those of the form', () {
    expect([for (final g in kOverallGrades) g.$1], ['A', 'B+', 'B', 'C', 'F']);
  });
}
