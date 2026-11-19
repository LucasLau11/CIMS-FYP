import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/l10n/app_localizations_en.dart';
import 'package:fyp_cims/utils/stats_report.dart';

void main() {
  final l10n = AppLocalizationsEn();

  KpiSection kpis(StatsReport r) => r.sections.whereType<KpiSection>().first;
  String kpi(StatsReport r, String label) => kpis(r).kpis.firstWhere((k) => k.label == label).value;

  test('HR report counts applications, acceptance and per-posting numbers', () {
    final r = hrReport(l10n, {
      'company_set': true,
      'postings_total': 6,
      'postings_open': 4,
      'applications_total': 20,
      'applicants_unique': 15,
      'by_status': {'pending': 8, 'interview': 5, 'offered': 2, 'active': 4, 'rejected': 1},
      'interviews_upcoming': 3,
      'interviews_completed': 6,
      'per_posting': [
        {'title': 'Intern', 'status': 'closed', 'applications': 9, 'interview': 2, 'offered': 1, 'accepted': 1},
      ],
      'weekly': [
        {'week': '2026-11-02', 'count': 5},
      ],
    });
    expect(kpi(r, 'Applications'), '20');
    expect(kpi(r, 'Accepted'), '4');
    expect(kpi(r, 'Acceptance rate'), '20%');
    expect(kpi(r, 'Open postings'), '4 / 6');

    final byStatus = r.sections.whereType<BarsSection>().first;
    expect(byStatus.total, 20);
    expect(byStatus.bars.map((b) => b.value), [8, 5, 2, 4, 1, 0]);

    final rows = r.sections.whereType<RowsSection>().first.rows.single;
    expect(rows.subtitle, '9 applications · 2 interview · 1 offered · 1 accepted');
    expect(rows.badge, 'Closed');

    expect(r.headline().map((k) => k.label), ['Applications', 'In interview', 'Accepted']);
  });

  test('HR with no company shows a notice instead of numbers', () {
    final r = hrReport(l10n, {'company_set': false});
    expect(r.sections, isEmpty);
    expect(r.notice, isNotNull);
  });

  test('an HR with no applications has a 0% acceptance rate, not a division error', () {
    final r = hrReport(l10n, {'company_set': true, 'applications_total': 0, 'by_status': <String, dynamic>{}});
    expect(kpi(r, 'Acceptance rate'), '0%');
  });

  test('academic supervisor report splits report progress and placement', () {
    final r = academicSupervisorReport(l10n, {
      'students_total': 10,
      'students_placed': 6,
      'reports_total': 12,
      'reports_pending': 5,
      'reports_approved': 6,
      'reports_rejected': 1,
      'documents_pending': 2,
      'documents_approved': 9,
      'evaluations_done': 3,
      'per_student': [
        {'name': 'Siti', 'placed': false, 'reports': 2, 'approved': 1, 'pending': 1},
      ],
    });
    expect(kpi(r, 'Not placed yet'), '4');
    expect(kpi(r, 'Waiting for your review'), '5');
    final progress = r.sections.whereType<BarsSection>().first;
    expect(progress.bars.map((b) => b.value), [5, 6, 1]);
    final row = r.sections.whereType<RowsSection>().first.rows.single;
    expect(row.badge, 'Not placed');
    expect(row.good, isFalse);
  });

  test('company supervisor report marks who has been evaluated', () {
    final r = companySupervisorReport(l10n, {
      'company_set': true,
      'students_total': 2,
      'students_evaluated': 1,
      'reports_total': 3,
      'reports_pending': 1,
      'reports_approved': 2,
      'reports_rejected': 0,
      'evaluations_done': 1,
      'per_student': [
        {'name': 'Ali', 'evaluated': true, 'reports': 3, 'approved': 2, 'pending': 1},
      ],
    });
    expect(kpi(r, 'Interns evaluated'), '1');
    expect(r.sections.whereType<RowsSection>().first.rows.single.badge, 'Evaluated');
    expect(companySupervisorReport(l10n, {'company_set': false}).notice, isNotNull);
  });

  test('admin report shows companies joined and ignores roles the app no longer has', () {
    final r = adminPlatformReport(l10n, {
      'users_by_role': {'student': 10, 'admin': 1, 'company_hr': 2, 'parent': 5},
      'pending_approvals': 2,
      'companies_total': 4,
      'companies_by_status': {'verified': 3, 'pending': 1},
      'companies_with_postings': 2,
      'new_companies_30d': 1,
      'new_users_30d': 6,
      'postings_total': 7,
      'postings_open': 5,
      'applications_total': 20,
      'interviews_upcoming': 1,
      'companies_monthly': [
        {'month': '2026-10', 'count': 1},
        {'month': '2026-11', 'count': 3},
      ],
      'users_monthly': <Object>[],
    });
    expect(kpi(r, 'Companies'), '4');
    expect(kpi(r, 'People on the platform'), '13', reason: 'parent accounts are not counted');
    expect(kpi(r, 'Verified'), '3');
    final trend = r.sections.whereType<TrendSection>().first;
    expect(trend.points.map((p) => p.value), [1, 3]);
    expect(r.headline().first.label, 'Companies');
  });

  test('the report can be written as CSV', () {
    final r = academicSupervisorReport(l10n, {'students_total': 1, 'students_placed': 1, 'reports_total': 0, 'per_student': <Object>[]});
    final csv = r.toCsv();
    expect(csv, contains('Student progress'));
    expect(csv, contains('Students,1'));
  });

  test('role labels', () {
    expect(roleLabel(l10n, 'company_hr'), 'Company HR');
    expect(roleLabel(l10n, 'admin'), 'Administrator');
    expect(roleLabel(l10n, null), '');
  });
}
