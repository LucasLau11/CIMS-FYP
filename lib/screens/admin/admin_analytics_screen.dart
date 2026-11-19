import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/admin_data_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/csv_export.dart';
import '../../utils/error_text.dart';
import '../../utils/format_utils.dart';
import '../../widgets/common/shared_widgets.dart';

/// How the internship season is going: the placement rate, where applications
/// stand, how each programme and company is doing, and which students still
/// have no placement (with a CSV export of that list and the other tables).
class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  Map<String, dynamic>? _report;
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
      final report = await AdminDataService.instance.getPlacementReport();
      if (!mounted) return;
      setState(() {
        _report = report;
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

  List<Map<String, dynamic>> _list(String key) =>
      List<Map<String, dynamic>>.from((_report?[key] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)));

  int _int(String key) => (_report?[key] as num?)?.toInt() ?? 0;

  /// Every table of the report in one CSV, a blank row between them.
  String _buildCsv() {
    final rows = <List<Object?>>[
      ['Placement report'],
      ['Students', _int('students_total')],
      ['Placed', _int('students_placed')],
      ['Applied at least once', _int('students_applied')],
      ['Applications', _int('applications_total')],
      [],
      ['Applications by status'],
      ['Status', 'Count'],
      for (final e in (_report?['by_status'] as Map? ?? const {}).entries) [applicationStatusLabel('${e.key}'), e.value],
      [],
      ['By programme'],
      ['Programme', 'Students', 'Placed'],
      for (final r in _list('by_programme')) [r['programme'], r['students'], r['placed']],
      [],
      ['By company'],
      ['Company', 'Postings', 'Applications', 'Placed'],
      for (final r in _list('by_company')) [r['company'], r['postings'], r['applications'], r['placed']],
      [],
      ['Most applied postings'],
      ['Posting', 'Company', 'Applications', 'Offered or placed', 'Placed'],
      for (final r in _list('top_postings')) [r['title'], r['company'], r['applications'], r['offered'], r['placed']],
      [],
      ['Students without a placement'],
      ['Name', 'Email', 'Registration no.', 'Programme', 'Applications'],
      for (final r in _list('unplaced_students')) [r['name'], r['email'], r['reg_no'], r['programme'], r['applications']],
    ];
    return toCsv(rows);
  }

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final name = 'cims_placement_${now.year}${two(now.month)}${two(now.day)}.csv';
    final ok = await saveAndOpenCsv(name, _buildCsv());
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.analyticsExportFailed), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: l10n.adminAnalyticsTitle,
        actions: [
          if (_report != null)
            IconButton(tooltip: l10n.analyticsExportCsv, icon: const Icon(Icons.download_outlined, color: Colors.white), onPressed: _export),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? EmptyState(icon: Icons.error_outline, title: _error!, description: '', buttonLabel: l10n.retry, onButton: _load)
              : RefreshIndicator(onRefresh: _load, child: _content(l10n)),
    );
  }

  Widget _content(AppLocalizations l10n) {
    final total = _int('students_total');
    final placed = _int('students_placed');
    final applied = _int('students_applied');
    final rate = total == 0 ? 0.0 : placed / total;
    final byStatus = Map<String, dynamic>.from(_report?['by_status'] as Map? ?? const {});
    final statusTotal = byStatus.values.fold<int>(0, (a, b) => a + (b as num).toInt());
    final unplaced = _list('unplaced_students');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.analyticsPlacementRate, style: AppTextStyles.label),
              const SizedBox(height: 6),
              Text('${(rate * 100).round()}%',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: rate, minHeight: 10, color: AppColors.primary, backgroundColor: AppColors.surfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(l10n.analyticsPlacedOf(placed, total), style: AppTextStyles.bodySecondary),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _Stat(label: l10n.analyticsStudentsApplied, value: '$applied')),
            const SizedBox(width: 10),
            Expanded(child: _Stat(label: l10n.analyticsApplications, value: '${_int('applications_total')}')),
            const SizedBox(width: 10),
            Expanded(child: _Stat(label: l10n.analyticsWithoutPlacement, value: '${total - placed}')),
          ],
        ),
        const SizedBox(height: 20),
        if (statusTotal > 0) ...[
          Text(l10n.analyticsByStatus, style: AppTextStyles.label),
          const SizedBox(height: 8),
          _Card(
            child: Column(
              children: [
                for (final e in byStatus.entries)
                  _Bar(label: applicationStatusLabel(e.key), value: (e.value as num).toInt(), max: statusTotal),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text(l10n.analyticsByProgramme, style: AppTextStyles.label),
        const SizedBox(height: 8),
        _Card(
          child: Column(
            children: [
              for (final r in _list('by_programme'))
                _Row(title: '${r['programme']}', trailing: l10n.analyticsRowStudentsPlaced((r['placed'] as num).toInt(), (r['students'] as num).toInt())),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(l10n.analyticsByCompany, style: AppTextStyles.label),
        const SizedBox(height: 8),
        _Card(
          child: Column(
            children: [
              for (final r in _list('by_company'))
                _Row(
                  title: '${r['company']}',
                  subtitle: l10n.analyticsRowCompany((r['postings'] as num).toInt(), (r['applications'] as num).toInt(), (r['placed'] as num).toInt()),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(l10n.analyticsTopPostings, style: AppTextStyles.label),
        const SizedBox(height: 8),
        _Card(
          child: Column(
            children: [
              for (final r in _list('top_postings'))
                _Row(
                  title: '${r['title']}',
                  subtitle: l10n.analyticsRowPosting('${r['company']}', (r['applications'] as num).toInt(), (r['offered'] as num).toInt()),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Text('${l10n.analyticsUnplaced} (${unplaced.length})', style: AppTextStyles.label)),
            TextButton.icon(onPressed: _export, icon: const Icon(Icons.download_outlined, size: 18), label: Text(l10n.analyticsExportCsv)),
          ],
        ),
        const SizedBox(height: 4),
        _Card(
          child: unplaced.isEmpty
              ? Text(l10n.analyticsNoStudentsUnplaced, style: AppTextStyles.bodySecondary)
              : Column(
                  children: [
                    for (final r in unplaced)
                      _Row(
                        title: (r['name'] as String?)?.trim().isNotEmpty == true ? r['name'] as String : '${r['email']}',
                        subtitle: [r['programme'], r['reg_no']].where((v) => v != null && '$v'.isNotEmpty).join(' · '),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

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

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final int value;
  final int max;

  const _Bar({required this.label, required this.value, required this.max});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 92, child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textPrimary))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: max == 0 ? 0 : value / max, minHeight: 8, color: AppColors.primary, backgroundColor: AppColors.surfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 28, child: Text('$value', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? trailing;

  const _Row({required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                if (subtitle != null && subtitle!.isNotEmpty) Text(subtitle!, style: AppTextStyles.caption),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Flexible(child: Text(trailing!, textAlign: TextAlign.right, style: AppTextStyles.caption)),
          ],
        ],
      ),
    );
  }
}
