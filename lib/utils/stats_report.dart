import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'csv_export.dart' as csv;
import 'interview_format.dart';

/// One headline number ("Applications 24").
class StatKpi {
  const StatKpi(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

class StatBar {
  const StatBar(this.label, this.value);
  final String label;
  final int value;
}

class StatRow {
  const StatRow(this.title, {this.subtitle, this.badge, this.good});
  final String title;
  final String? subtitle;
  final String? badge;

  /// true = green badge, false = amber badge, null = neutral.
  final bool? good;
}

/// A block of the statistics screen.
sealed class StatSection {
  const StatSection();
}

class KpiSection extends StatSection {
  const KpiSection(this.kpis);
  final List<StatKpi> kpis;
}

/// Horizontal bars, one per label, scaled against [total] (or the largest value).
class BarsSection extends StatSection {
  const BarsSection(this.title, this.bars, {this.total});
  final String title;
  final List<StatBar> bars;
  final int? total;
}

/// Vertical columns over time (for example applications per week).
class TrendSection extends StatSection {
  const TrendSection(this.title, this.points);
  final String title;
  final List<StatBar> points;
}

class RowsSection extends StatSection {
  const RowsSection(this.title, this.rows);
  final String title;
  final List<StatRow> rows;
}

/// Everything one role's statistics screen shows. Built from plain numbers the database sends, so
/// the labels follow the app's language.
class StatsReport {
  const StatsReport(this.title, this.sections, {this.notice});
  final String title;
  final List<StatSection> sections;

  /// Shown instead of the sections when there is nothing to count (for example no company yet).
  final String? notice;

  /// The first few headline numbers, for the summary card on the profile.
  List<StatKpi> headline([int count = 3]) {
    for (final s in sections) {
      if (s is KpiSection) return s.kpis.take(count).toList();
    }
    return const [];
  }

  /// The whole report as CSV rows, a blank row between the blocks.
  List<List<Object?>> toCsvRows() {
    final rows = <List<Object?>>[
      [title],
    ];
    for (final s in sections) {
      rows.add([]);
      switch (s) {
        case KpiSection():
          for (final k in s.kpis) {
            rows.add([k.label, k.value]);
          }
        case BarsSection():
          rows.add([s.title]);
          for (final b in s.bars) {
            rows.add([b.label, b.value]);
          }
        case TrendSection():
          rows.add([s.title]);
          for (final b in s.points) {
            rows.add([b.label, b.value]);
          }
        case RowsSection():
          rows.add([s.title]);
          for (final r in s.rows) {
            rows.add([r.title, r.subtitle, r.badge]);
          }
      }
    }
    return rows;
  }

  String toCsv() => csv.toCsv(toCsvRows());
}

int _n(Map<String, dynamic> j, String key) => (j[key] as num?)?.toInt() ?? 0;

Map<String, dynamic> _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> _list(Object? v) =>
    v is List ? [for (final e in v) Map<String, dynamic>.from(e as Map)] : const <Map<String, dynamic>>[];

String _percent(int part, int whole) => whole == 0 ? '0%' : '${(part * 100 / whole).round()}%';

// ------------------------------------------------------------------ company HR

StatsReport hrReport(AppLocalizations l10n, Map<String, dynamic> j) {
  if (j['company_set'] != true) return StatsReport(l10n.stTitleHr, const [], notice: l10n.stNoCompany);
  final byStatus = _map(j['by_status']);
  int s(String key) => (byStatus[key] as num?)?.toInt() ?? 0;
  final applications = _n(j, 'applications_total');
  final accepted = s('active');

  return StatsReport(l10n.stTitleHr, [
    KpiSection([
      StatKpi(l10n.stApplications, '$applications', Icons.description_outlined),
      StatKpi(l10n.stInterviewing, '${s('interview')}', Icons.event_available_outlined),
      StatKpi(l10n.stAccepted, '$accepted', Icons.how_to_reg_outlined),
      StatKpi(l10n.stApplicants, '${_n(j, 'applicants_unique')}', Icons.groups_outlined),
      StatKpi(l10n.stAcceptRate, _percent(accepted, applications), Icons.percent),
      StatKpi(l10n.stOffered, '${s('offered')}', Icons.mark_email_read_outlined),
      StatKpi(l10n.stRejected, '${s('rejected')}', Icons.block_outlined),
      StatKpi(l10n.stOpenPostings, '${_n(j, 'postings_open')} / ${_n(j, 'postings_total')}', Icons.work_outline),
      StatKpi(l10n.stInterviewsUpcoming, '${_n(j, 'interviews_upcoming')}', Icons.event_outlined),
      StatKpi(l10n.stInterviewsDone, '${_n(j, 'interviews_completed')}', Icons.event_available),
    ]),
    BarsSection(
      l10n.stByStatus,
      [
        StatBar(l10n.stPending, s('pending')),
        StatBar(l10n.stInterviewing, s('interview')),
        StatBar(l10n.stOffered, s('offered')),
        StatBar(l10n.stAccepted, accepted),
        StatBar(l10n.stRejected, s('rejected')),
        StatBar(l10n.stClosed, s('unavailable')),
      ],
      total: applications,
    ),
    TrendSection(l10n.stWeekly, [
      for (final w in _list(j['weekly']))
        StatBar(formatInterviewDayMonth(DateTime.parse(w['week'] as String)), (w['count'] as num).toInt()),
    ]),
    RowsSection(l10n.stPerPosting, [
      for (final p in _list(j['per_posting']))
        StatRow(
          p['title'] as String,
          subtitle: l10n.stPostingRow(_n(p, 'applications'), _n(p, 'interview'), _n(p, 'offered'), _n(p, 'accepted')),
          badge: p['status'] == 'open' ? null : l10n.stClosed,
        ),
    ]),
  ]);
}

// ------------------------------------------------------------ academic supervisor

StatsReport academicSupervisorReport(AppLocalizations l10n, Map<String, dynamic> j) {
  final students = _n(j, 'students_total');
  final placed = _n(j, 'students_placed');
  final waiting = _n(j, 'reports_pending');
  final approved = _n(j, 'reports_approved');
  final sentBack = _n(j, 'reports_rejected');

  return StatsReport(l10n.stTitleAcademic, [
    KpiSection([
      StatKpi(l10n.stStudents, '$students', Icons.groups_outlined),
      StatKpi(l10n.stPlaced, '$placed', Icons.work_outline),
      StatKpi(l10n.stReportsWaiting, '$waiting', Icons.pending_actions_outlined),
      StatKpi(l10n.stNotPlaced, '${students - placed}', Icons.person_search_outlined),
      StatKpi(l10n.stReportsApproved, '$approved', Icons.check_circle_outline),
      StatKpi(l10n.stReportsSentBack, '$sentBack', Icons.undo),
      StatKpi(l10n.stDocsWaiting, '${_n(j, 'documents_pending')}', Icons.folder_open_outlined),
      StatKpi(l10n.stDocsApproved, '${_n(j, 'documents_approved')}', Icons.folder_special_outlined),
      StatKpi(l10n.stEvaluationsDone, '${_n(j, 'evaluations_done')}', Icons.fact_check_outlined),
    ]),
    BarsSection(l10n.stReportProgress, [
      StatBar(l10n.stReportsWaiting, waiting),
      StatBar(l10n.stReportsApproved, approved),
      StatBar(l10n.stReportsSentBack, sentBack),
    ], total: _n(j, 'reports_total')),
    RowsSection(l10n.stPerStudent, [
      for (final p in _list(j['per_student']))
        StatRow(
          p['name'] as String,
          subtitle: l10n.stStudentRow(_n(p, 'reports'), _n(p, 'approved'), _n(p, 'pending')),
          badge: p['placed'] == true ? l10n.stPlacedBadge : l10n.stNotPlacedBadge,
          good: p['placed'] == true,
        ),
    ]),
  ]);
}

// ------------------------------------------------------------- company supervisor

StatsReport companySupervisorReport(AppLocalizations l10n, Map<String, dynamic> j) {
  if (j['company_set'] != true) return StatsReport(l10n.stTitleCompanySup, const [], notice: l10n.stNoCompany);
  final waiting = _n(j, 'reports_pending');
  final approved = _n(j, 'reports_approved');
  final sentBack = _n(j, 'reports_rejected');

  return StatsReport(l10n.stTitleCompanySup, [
    KpiSection([
      StatKpi(l10n.stInterns, '${_n(j, 'students_total')}', Icons.groups_outlined),
      StatKpi(l10n.stEvaluatedStudents, '${_n(j, 'students_evaluated')}', Icons.fact_check_outlined),
      StatKpi(l10n.stReportsWaiting, '$waiting', Icons.pending_actions_outlined),
      StatKpi(l10n.stEvaluationsDone, '${_n(j, 'evaluations_done')}', Icons.task_alt),
      StatKpi(l10n.stReportsApproved, '$approved', Icons.check_circle_outline),
      StatKpi(l10n.stReportsSentBack, '$sentBack', Icons.undo),
    ]),
    BarsSection(l10n.stReportProgress, [
      StatBar(l10n.stReportsWaiting, waiting),
      StatBar(l10n.stReportsApproved, approved),
      StatBar(l10n.stReportsSentBack, sentBack),
    ], total: _n(j, 'reports_total')),
    RowsSection(l10n.stPerStudent, [
      for (final p in _list(j['per_student']))
        StatRow(
          p['name'] as String,
          subtitle: l10n.stStudentRow(_n(p, 'reports'), _n(p, 'approved'), _n(p, 'pending')),
          badge: p['evaluated'] == true ? l10n.stEvaluatedBadge : l10n.stNotEvaluatedBadge,
          good: p['evaluated'] == true,
        ),
    ]),
  ]);
}

// ------------------------------------------------------------------------- admin

StatsReport adminPlatformReport(AppLocalizations l10n, Map<String, dynamic> j) {
  final roles = _map(j['users_by_role']);
  int r(String key) => (roles[key] as num?)?.toInt() ?? 0;
  // Only the roles the app still has; any leftover role row is not counted.
  final people = r('student') + r('academic_supervisor') + r('company_hr') + r('company_supervisor') + r('admin');
  final companyStatus = _map(j['companies_by_status']);
  int c(String key) => (companyStatus[key] as num?)?.toInt() ?? 0;

  List<StatBar> monthly(Object? v) => [for (final m in _list(v)) StatBar(m['month'] as String, (m['count'] as num).toInt())];

  return StatsReport(l10n.stTitleAdmin, [
    KpiSection([
      StatKpi(l10n.stCompanies, '${_n(j, 'companies_total')}', Icons.business_outlined),
      StatKpi(l10n.stPeople, '$people', Icons.people_outline),
      StatKpi(l10n.stNewCompanies, '${_n(j, 'new_companies_30d')}', Icons.add_business_outlined),
      StatKpi(l10n.stNewPeople, '${_n(j, 'new_users_30d')}', Icons.person_add_alt_1_outlined),
      StatKpi(l10n.stCompaniesVerified, '${c('verified')}', Icons.verified_outlined),
      StatKpi(l10n.stCompaniesPending, '${c('pending')}', Icons.hourglass_top_outlined),
      StatKpi(l10n.stPendingApprovals, '${_n(j, 'pending_approvals')}', Icons.verified_user_outlined),
      StatKpi(l10n.stCompaniesWithPostings, '${_n(j, 'companies_with_postings')}', Icons.work_outline),
      StatKpi(l10n.stOpenPostings, '${_n(j, 'postings_open')} / ${_n(j, 'postings_total')}', Icons.campaign_outlined),
      StatKpi(l10n.stApplications, '${_n(j, 'applications_total')}', Icons.description_outlined),
      StatKpi(l10n.stInterviewsUpcoming, '${_n(j, 'interviews_upcoming')}', Icons.event_outlined),
    ]),
    TrendSection(l10n.stCompaniesJoined, monthly(j['companies_monthly'])),
    TrendSection(l10n.stPeopleJoined, monthly(j['users_monthly'])),
    BarsSection(l10n.stUsersByRole, [
      StatBar(l10n.stRoleStudent, r('student')),
      StatBar(l10n.stRoleAcademic, r('academic_supervisor')),
      StatBar(l10n.stRoleHr, r('company_hr')),
      StatBar(l10n.stRoleCompanySup, r('company_supervisor')),
      StatBar(l10n.stRoleAdmin, r('admin')),
    ], total: people),
    BarsSection(l10n.stCompaniesByStatus, [
      for (final e in companyStatus.entries)
        StatBar(e.key == 'verified' ? l10n.stCompaniesVerified : (e.key == 'pending' ? l10n.stCompaniesPending : '${e.key}'), (e.value as num).toInt()),
    ], total: _n(j, 'companies_total')),
  ]);
}

/// The label for a `profiles.role` value, in the app's language.
String roleLabel(AppLocalizations l10n, String? role) {
  switch (role) {
    case 'student':
      return l10n.roleLabelStudent;
    case 'academic_supervisor':
      return l10n.roleLabelAcademic;
    case 'company_hr':
      return l10n.roleLabelHr;
    case 'company_supervisor':
      return l10n.roleLabelCompanySup;
    case 'admin':
      return l10n.roleLabelAdmin;
    default:
      return '';
  }
}
