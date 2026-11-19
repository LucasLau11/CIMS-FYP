import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/admin_data_service.dart';
import '../services/company_supervisor_data_service.dart';
import '../services/hr_data_service.dart';
import '../services/supervisor_data_service.dart';
import '../theme/app_theme.dart';
import '../utils/csv_export.dart';
import '../utils/error_text.dart';
import '../utils/stats_report.dart';
import '../widgets/common/shared_widgets.dart';

/// Where one role's statistics come from and how they are turned into a report.
class StatsSource {
  const StatsSource({required this.fetch, required this.build, required this.title});

  final Future<Map<String, dynamic>> Function() fetch;
  final StatsReport Function(AppLocalizations, Map<String, dynamic>) build;
  final String Function(AppLocalizations) title;
}

/// The statistics for a `profiles.role` (null for a student, who has no statistics page).
StatsSource? statsSourceFor(String? role) {
  switch (role) {
    case 'company_hr':
      return StatsSource(fetch: HrDataService.instance.getStats, build: hrReport, title: (l) => l.stTitleHr);
    case 'academic_supervisor':
      return StatsSource(fetch: SupervisorDataService.instance.getStats, build: academicSupervisorReport, title: (l) => l.stTitleAcademic);
    case 'company_supervisor':
      return StatsSource(fetch: CompanySupervisorDataService.instance.getStats, build: companySupervisorReport, title: (l) => l.stTitleCompanySup);
    case 'admin':
      return StatsSource(fetch: AdminDataService.instance.getPlatformStats, build: adminPlatformReport, title: (l) => l.stTitleAdmin);
    default:
      return null;
  }
}

/// The full statistics page for one role.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, required this.source});

  final StatsSource source;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _json;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final json = await widget.source.fetch();
      if (!mounted) return;
      setState(() {
        _json = json;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _export(StatsReport report) async {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final ok = await saveAndOpenCsv('cims_statistics_${now.year}${two(now.month)}${two(now.day)}.csv', report.toCsv());
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.analyticsExportFailed), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final report = _json == null ? null : widget.source.build(l10n, _json!);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: widget.source.title(l10n),
        actions: [
          if (report != null && report.sections.isNotEmpty)
            IconButton(tooltip: l10n.analyticsExportCsv, icon: const Icon(Icons.download_outlined, color: Colors.white), onPressed: () => _export(report)),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? EmptyState(icon: Icons.error_outline, title: l10n.stCouldNotLoad(_error!), description: '', buttonLabel: l10n.retry, onButton: _load)
              : RefreshIndicator(onRefresh: _load, child: _body(report!, l10n)),
    );
  }

  Widget _body(StatsReport report, AppLocalizations l10n) {
    if (report.notice != null) {
      return EmptyState(icon: Icons.business_outlined, title: report.notice!, description: '');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final s in report.sections) ...[
          switch (s) {
            KpiSection() => _KpiGrid(kpis: s.kpis),
            BarsSection() => _Titled(title: s.title, child: _BarsCard(section: s)),
            TrendSection() => _Titled(title: s.title, child: _TrendCard(points: s.points)),
            RowsSection() => _Titled(title: s.title, child: _RowsCard(rows: s.rows, emptyText: l10n.stNothingYet)),
          },
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}

/// The few headline numbers on a profile, with a link to the whole page. Statistics a role does not
/// have (a student) show nothing.
class StatsSummaryCard extends StatefulWidget {
  const StatsSummaryCard({super.key, required this.role});

  final String? role;

  @override
  State<StatsSummaryCard> createState() => _StatsSummaryCardState();
}

class _StatsSummaryCardState extends State<StatsSummaryCard> {
  Map<String, dynamic>? _json;
  bool _failed = false;

  StatsSource? get _source => statsSourceFor(widget.role);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final source = _source;
    if (source == null) return;
    try {
      final json = await source.fetch();
      if (!mounted) return;
      setState(() => _json = json);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = _source;
    if (source == null || _failed) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final report = _json == null ? null : source.build(l10n, _json!);
    final headline = report?.headline() ?? const <StatKpi>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_outlined, size: 18, color: AppColors.primaryText),
                const SizedBox(width: 8),
                Expanded(child: Text(source.title(l10n), style: AppTextStyles.h3, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 10),
            if (report == null)
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
            else if (report.notice != null)
              Text(report.notice!, style: AppTextStyles.bodySecondary)
            else
              Row(
                children: [
                  for (final k in headline)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(k.value, style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
                            Text(k.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StatsScreen(source: source))),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: Text(l10n.stViewFull),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Titled extends StatelessWidget {
  const _Titled({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.label),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: child,
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpis});

  final List<StatKpi> kpis;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 10.0;
        final columns = c.maxWidth >= 420 ? 3 : 2;
        final width = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final k in kpis)
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(k.icon, size: 18, color: AppColors.primaryText),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(k.value, style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
                      ),
                      Text(k.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BarsCard extends StatelessWidget {
  const _BarsCard({required this.section});

  final BarsSection section;

  @override
  Widget build(BuildContext context) {
    final largest = section.bars.fold<int>(0, (a, b) => b.value > a ? b.value : a);
    final scale = (section.total ?? 0) > 0 ? section.total! : (largest == 0 ? 1 : largest);
    return _Card(
      child: Column(
        children: [
          for (final b in section.bars)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(width: 112, child: Text(b.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textPrimary))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: (b.value / scale).clamp(0.0, 1.0), minHeight: 8, color: AppColors.primary, backgroundColor: AppColors.surfaceVariant),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(width: 30, child: Text('${b.value}', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.points});

  final List<StatBar> points;

  @override
  Widget build(BuildContext context) {
    final largest = points.fold<int>(0, (a, b) => b.value > a ? b.value : a);
    return _Card(
      child: SizedBox(
        height: 132,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final p in points)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('${p.value}', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Container(
                        height: largest == 0 ? 2 : (p.value / largest * 72).clamp(2.0, 72.0),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(3)),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(fit: BoxFit.scaleDown, child: Text(p.label, maxLines: 1, style: AppTextStyles.caption)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RowsCard extends StatelessWidget {
  const _RowsCard({required this.rows, required this.emptyText});

  final List<StatRow> rows;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return _Card(child: Text(emptyText, style: AppTextStyles.bodySecondary));
    return _Card(
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        if (r.subtitle != null) Text(r.subtitle!, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  if (r.badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: r.good == true ? AppColors.successBg : (r.good == false ? AppColors.warningBg : AppColors.surfaceVariant),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        r.badge!,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: r.good == true ? AppColors.success : (r.good == false ? AppColors.warning : AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
