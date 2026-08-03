import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/student_data_service.dart';
import '../../utils/format_utils.dart';
import 'student_apply_screen.dart';
import 'student_company_profile_screen.dart';

/// Landing page for a tapped internship — job details first, "Apply" only
/// proceeds to the resume/cover-letter/skills flow once the student has
/// actually reviewed the posting.
class StudentInternshipDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> internship;
  final bool applied;

  const StudentInternshipDetailsScreen({super.key, required this.internship, required this.applied});

  @override
  State<StudentInternshipDetailsScreen> createState() => _StudentInternshipDetailsScreenState();
}

class _StudentInternshipDetailsScreenState extends State<StudentInternshipDetailsScreen> {
  bool _isLoadingCompany = true;
  Map<String, dynamic>? _companyDetails;
  late bool _applied = widget.applied;

  bool get _isVerified => _isLoadingCompany || _companyDetails?['status'] == 'verified';

  @override
  void initState() {
    super.initState();
    _loadCompany();
  }

  Future<void> _loadCompany() async {
    try {
      final details = await StudentDataService.instance.getCompanyDetails(widget.internship['company_id'] as String?);
      if (!mounted) return;
      setState(() {
        _companyDetails = details;
        _isLoadingCompany = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCompany = false);
    }
  }

  Future<void> _apply() async {
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => StudentApplyScreen(internship: widget.internship)),
    );
    if (submitted == true) {
      setState(() => _applied = true);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final internship = widget.internship;
    final companyName = internship['company_name'] as String;
    final skills = (internship['required_skills'] as List?)?.cast<String>() ?? [];
    final deadlineRaw = internship['application_deadline'] as String?;
    final deadline = deadlineRaw != null ? DateTime.tryParse(deadlineRaw) : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context, _applied)),
        title: Text(l10n.internshipDetails, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: nameColor(companyName).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Text(logoLetter(companyName),
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: nameColor(companyName))),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(internship['title'] as String, style: TextStyle(fontFamily: 'Poppins', fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    if (internship['company_id'] != null)
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentCompanyProfileScreen(companyId: internship['company_id'] as String, companyName: companyName),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(companyName, style: AppTextStyles.bodySecondary.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 2),
                            Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                          ],
                        ),
                      )
                    else
                      Text(companyName, style: AppTextStyles.bodySecondary),
                  ],
                ),
              ),
              if (_applied) StatusBadge(label: l10n.stepApplied, backgroundColor: AppColors.successBg, textColor: AppColors.success),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(
              children: [
                _DetailRow(icon: Icons.work_outline, label: l10n.position, value: internship['title'] as String),
                const Divider(height: 20),
                _DetailRow(icon: Icons.badge_outlined, label: l10n.hrJobType, value: (internship['job_type'] as String?) ?? l10n.notSpecified),
                const Divider(height: 20),
                _DetailRow(icon: Icons.attach_money, label: l10n.monthlyAllowance, value: formatAllowance(parseNum(internship['allowance_month']))),
                const Divider(height: 20),
                _DetailRow(icon: Icons.schedule, label: l10n.hrDuration, value: formatDuration(internship['duration_months'] as int)),
                const Divider(height: 20),
                _DetailRow(icon: Icons.location_on_outlined, label: l10n.address, value: internship['location'] as String),
                const Divider(height: 20),
                _DetailRow(
                  icon: Icons.event_busy_outlined,
                  label: l10n.applicationDeadline,
                  value: deadline != null ? '${deadline.day}/${deadline.month}/${deadline.year}' : l10n.openUntilFilled,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(l10n.hrJobDescription, style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text((internship['description'] as String?) ?? l10n.noDescriptionProvided,
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
          if (skills.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(l10n.hrSkillsRequired, style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(20)),
                        child: Text(s, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.primary)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 20),
          Text(l10n.aboutTheCompany, style: AppTextStyles.h3),
          const SizedBox(height: 8),
          if (_isLoadingCompany)
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Column(
                children: [
                  _DetailRow(icon: Icons.category_outlined, label: l10n.industry, value: (_companyDetails?['industry'] as String?) ?? (internship['company_industry'] as String?) ?? l10n.notSpecified),
                  if (_companyDetails?['hr_contact_name'] != null) ...[
                    const Divider(height: 20),
                    _DetailRow(icon: Icons.person_outline, label: l10n.hrContact, value: _companyDetails!['hr_contact_name'] as String),
                  ],
                  if (_companyDetails?['hr_contact_email'] != null) ...[
                    const Divider(height: 20),
                    _DetailRow(icon: Icons.email_outlined, label: l10n.contactEmail, value: _companyDetails!['hr_contact_email'] as String),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (!_isLoadingCompany && !_applied && !_isVerified) ...[
            Text(
              l10n.applyOnceVerifiedNote,
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_applied || !_isVerified) ? null : _apply,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: Text(_applied
                  ? l10n.alreadyApplied
                  : (!_isVerified ? l10n.companyPendingVerification : l10n.applyNow)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}
