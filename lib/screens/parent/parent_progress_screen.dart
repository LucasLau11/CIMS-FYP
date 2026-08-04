import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/parent_data_service.dart';
import '../../utils/format_utils.dart';

const List<String> _requiredDocCategories = ['offer_letter', 'indemnity_letter', 'company_acceptance_letter'];

String _docCategoryTitle(AppLocalizations l10n, String category) {
  switch (category) {
    case 'offer_letter':
      return l10n.docTypeOfferLetter;
    case 'indemnity_letter':
      return l10n.docTypeIndemnityLetter;
    default:
      return l10n.docTypeCompanyAcceptanceLetter;
  }
}

String _evaluationTypeLabel(AppLocalizations l10n, String type) =>
    type == 'workplace' ? l10n.parentCompanySupervisorEvaluation : l10n.parentAcademicSupervisorEvaluation;

class ParentProgressScreen extends StatefulWidget {
  final Map<String, dynamic> child;
  final Map<String, dynamic>? application;

  const ParentProgressScreen({super.key, required this.child, required this.application});

  @override
  State<ParentProgressScreen> createState() => _ParentProgressScreenState();
}

class _ParentProgressScreenState extends State<ParentProgressScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _documents = [];
  List<Map<String, dynamic>> _evaluations = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final childId = widget.child['id'] as String;
      final reports = await ParentDataService.instance.getChildReports(childId);
      final documents = await ParentDataService.instance.getChildDocuments(childId);
      final evaluations = await ParentDataService.instance.getChildEvaluationSummary(childId);
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _documents = documents;
        _evaluations = evaluations;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = (widget.child['full_name'] as String?)?.isNotEmpty == true ? widget.child['full_name'] as String : l10n.parentUnnamedStudent;
    final internship = widget.application?['internships'] as Map?;
    final companyName = internship?['company_name'] as String?;
    final status = widget.application?['status'] as String?;
    final monthlyReports = _reports.where((r) => r['type'] != 'final').toList();
    final finalReports = _reports.where((r) => r['type'] == 'final').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(l10n.parentProgressTitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0D6E78), Color(0xFF14B8C8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white24,
                          child: Text(logoLetter(name), style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                              Text(companyName ?? l10n.parentNoApplicationYet, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white70)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(l10n.parentApplicationStatusTitle, style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  if (widget.application == null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: Text(l10n.parentNoApplicationSubmittedYet, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(companyName ?? l10n.parentUnknownCompany, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                if (internship?['title'] != null)
                                  Text(internship!['title'] as String, style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                          applicationStatusBadge(context, status ?? 'pending'),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(l10n.parentAtAGlanceTitle, style: AppTextStyles.h3),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.1,
                    children: [
                      MetricCard(label: l10n.parentReportsSubmittedLabel, value: '${_reports.length}', icon: Icons.assignment_turned_in_outlined, color: AppColors.success),
                      MetricCard(
                          label: l10n.parentDurationLabel,
                          value: internship?['duration_months'] != null ? formatDuration(internship!['duration_months'] as int) : '—',
                          icon: Icons.timer_outlined,
                          color: AppColors.primaryLight),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(l10n.parentEvaluationTitle, style: AppTextStyles.h3),
                  const SizedBox(height: 10),
                  if (_evaluations.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(l10n.parentNoEvaluationsYet, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
                    )
                  else
                    ..._evaluations.map((e) => _EvaluationRow(
                          title: _evaluationTypeLabel(l10n, e['type'] as String),
                          averageScore: parseNum(e['average_score'])?.toDouble() ?? 0,
                          date: timeAgo(context, DateTime.parse(e['created_at'] as String)),
                        )),
                  const SizedBox(height: 20),
                  Text(l10n.parentRequiredDocumentsTitle, style: AppTextStyles.h3),
                  const SizedBox(height: 10),
                  ..._requiredDocCategories.map((category) {
                    final matches = _documents.where((d) => d['category'] == category);
                    final doc = matches.isEmpty ? null : matches.first;
                    return _DocumentStatusRow(title: _docCategoryTitle(l10n, category), status: doc?['status'] as String?);
                  }),
                  const SizedBox(height: 20),
                  Text(l10n.parentMonthlyReportsTitle, style: AppTextStyles.h3),
                  const SizedBox(height: 10),
                  if (monthlyReports.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(l10n.parentNoMonthlyReportsYet, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
                    )
                  else
                    ...monthlyReports.map((r) => _ReportStatusRow(
                          title: l10n.parentMonthlyReportLabel(r['period_label'] as String),
                          date: l10n.parentSubmittedDate(timeAgo(context, DateTime.parse(r['submitted_at'] as String))),
                          status: r['status'] as String,
                        )),
                  const SizedBox(height: 20),
                  Text(l10n.parentFinalReportTitle, style: AppTextStyles.h3),
                  const SizedBox(height: 10),
                  if (finalReports.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(l10n.parentNoFinalReportYet, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
                    )
                  else
                    ...finalReports.map((r) => _ReportStatusRow(
                          title: l10n.parentFinalReportLabel(r['period_label'] as String),
                          date: l10n.parentSubmittedDate(timeAgo(context, DateTime.parse(r['submitted_at'] as String))),
                          status: r['status'] as String,
                        )),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline, size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.parentReadOnlyNotice,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _ReportStatusRow extends StatelessWidget {
  final String title;
  final String date;
  final String status;

  const _ReportStatusRow({required this.title, required this.date, required this.status});

  Color get _accentColor {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  StatusBadge _badge(BuildContext context) {
    switch (status) {
      case 'approved':
        return StatusBadge.approved(context);
      case 'rejected':
        return StatusBadge.rejected(context);
      default:
        return StatusBadge.pending(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccentCard(
      accentColor: _accentColor,
      child: Row(
        children: [
          Icon(Icons.assignment_outlined, size: 18, color: _accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(date, style: AppTextStyles.caption),
              ],
            ),
          ),
          _badge(context),
        ],
      ),
    );
  }
}

class _DocumentStatusRow extends StatelessWidget {
  final String title;
  final String? status;

  const _DocumentStatusRow({required this.title, required this.status});

  Color get _accentColor {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'submitted':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  Widget _badge(BuildContext context) {
    switch (status) {
      case 'approved':
        return StatusBadge.approved(context);
      case 'rejected':
        return StatusBadge.rejected(context);
      case 'submitted':
        return StatusBadge.submitted(context);
      default:
        return StatusBadge(label: AppLocalizations.of(context)!.parentDocNotSubmitted, backgroundColor: AppColors.surfaceVariant, textColor: AppColors.textMuted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccentCard(
      accentColor: _accentColor,
      child: Row(
        children: [
          Icon(Icons.description_outlined, size: 18, color: _accentColor),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
          _badge(context),
        ],
      ),
    );
  }
}

class _EvaluationRow extends StatelessWidget {
  final String title;
  final double averageScore;
  final String date;

  const _EvaluationRow({required this.title, required this.averageScore, required this.date});

  @override
  Widget build(BuildContext context) {
    return AccentCard(
      accentColor: AppColors.primary,
      child: Row(
        children: [
          const Icon(Icons.star_outline, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(date, style: AppTextStyles.caption),
              ],
            ),
          ),
          Text('${averageScore.toStringAsFixed(1)}/5', style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ],
      ),
    );
  }
}
