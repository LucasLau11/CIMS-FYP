import '../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../services/hr_data_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/error_text.dart';
import '../../widgets/common/shared_widgets.dart';
import '../document_preview_screen.dart';
import '../../widgets/profile_actions.dart';

/// What company HR sees of an applicant: photo, contact details, studies,
/// skills, work experience and the resume. Opened from the applicant list and
/// from the application screen; only students who applied to the HR's own
/// company can be opened (the database enforces that).
class ApplicantProfileScreen extends StatefulWidget {
  /// The row already loaded by the applicant list, shown while the full
  /// profile loads.
  final Map<String, dynamic> applicant;

  const ApplicantProfileScreen({super.key, required this.applicant});

  @override
  State<ApplicantProfileScreen> createState() => _ApplicantProfileScreenState();
}

class _ApplicantProfileScreenState extends State<ApplicantProfileScreen> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _experience = [];
  bool _loading = true;
  String? _error;

  String get _studentId => widget.applicant['student_id'] as String;

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
      final profile = await HrDataService.instance.getStudentProfile(_studentId);
      final experience = await HrDataService.instance.getStudentExperience(_studentId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _experience = experience;
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

  Future<void> _viewResume(String path, String? fileName) async {
    try {
      final url = await HrDataService.instance.getResumeSignedUrl(path);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DocumentPreviewScreen(url: url, fileName: fileName ?? path.split('/').last)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.apCouldNotOpenResume(friendlyError(e))), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile ?? widget.applicant;
    final name = ((p['full_name'] ?? p['student_name']) as String?)?.trim();
    final l10n = AppLocalizations.of(context)!;
    final displayName = (name == null || name.isEmpty) ? l10n.apUnnamed : name;
    final avatarUrl = p['avatar_url'] as String?;
    final skills = List<String>.from(p['skills'] as List? ?? const []);
    final resumePath = p['resume_path'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(l10n.apTitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: (avatarUrl == null || avatarUrl.isEmpty) ? null : () => _showPhoto(displayName, avatarUrl),
                    child: ProfileAvatar(name: displayName, avatarUrl: avatarUrl, radius: 44),
                  ),
                  const SizedBox(height: 12),
                  Text(displayName, style: AppTextStyles.h2, textAlign: TextAlign.center),
                  if ((p['student_reg_no'] as String?)?.isNotEmpty == true)
                    Text(p['student_reg_no'] as String, style: AppTextStyles.bodySecondary),
                ],
              ),
            ),
            const SizedBox(height: 16),
            MessageButton(profileId: _studentId),
            const SizedBox(height: 20),
            if (_loading)
              Padding(padding: const EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
            else if (_error != null)
              _InfoBox(child: Text(l10n.apCouldNotLoad(_error!), style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.error)))
            else ...[
              _Section(
                title: l10n.apContact,
                child: Column(
                  children: [
                    _InfoRow(icon: Icons.email_outlined, label: l10n.apEmail, value: p['email'] as String?),
                    _InfoRow(icon: Icons.phone_outlined, label: l10n.apPhone, value: p['phone'] as String?),
                  ],
                ),
              ),
              _Section(
                title: l10n.apStudies,
                child: Column(
                  children: [
                    _InfoRow(icon: Icons.school_outlined, label: l10n.apProgramme, value: p['programme'] as String?),
                    _InfoRow(icon: Icons.account_balance_outlined, label: l10n.apFaculty, value: p['faculty'] as String?),
                    _InfoRow(icon: Icons.timeline_outlined, label: l10n.apSemester, value: p['semester']?.toString()),
                    _InfoRow(icon: Icons.grade_outlined, label: l10n.apCgpa, value: p['cgpa']?.toString()),
                  ],
                ),
              ),
              _Section(
                title: l10n.apSkills,
                child: skills.isEmpty
                    ? Text(l10n.apNoSkills, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: skills
                            .map((s) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(20)),
                                  child: Text(s, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.primaryText)),
                                ))
                            .toList(),
                      ),
              ),
              _Section(
                title: l10n.apWorkExperience,
                child: _experience.isEmpty
                    ? Text(l10n.apNoExperience, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary))
                    : Column(
                        children: _experience.map((e) => _ExperienceTile(data: e)).toList(),
                      ),
              ),
              _Section(
                title: l10n.apResume,
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.primaryText),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        (p['resume_filename'] as String?) ?? l10n.apNoResume,
                        style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                      ),
                    ),
                    if (resumePath != null) TextButton(onPressed: () => _viewResume(resumePath, p['resume_filename'] as String?), child: Text(l10n.apView)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPhoto(String name, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox(height: 120, child: Center(child: Icon(Icons.broken_image_outlined))))),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.label),
          const SizedBox(height: 8),
          _InfoBox(child: child),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final Widget child;

  const _InfoBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final notProvided = AppLocalizations.of(context)!.apNotProvided;
    final shown = (value == null || value!.trim().isEmpty) ? notProvided : value!;
    final missing = shown == notProvided;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryText),
          const SizedBox(width: 10),
          SizedBox(width: 78, child: Text(label, style: AppTextStyles.caption)),
          Expanded(
            child: Text(
              shown,
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: missing ? AppColors.textMuted : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExperienceTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ExperienceTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final start = data['start_year'];
    final end = data['is_current'] == true ? AppLocalizations.of(context)!.apPresent : data['end_year'];
    final period = [if (start != null) '$start', if (end != null) '$end'].join(' – ');
    final description = data['description'] as String?;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text((data['position'] as String?) ?? '', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          Text([(data['company_name'] as String?) ?? '', if (period.isNotEmpty) period].where((s) => s.isNotEmpty).join(' · '), style: AppTextStyles.caption),
          if (description != null && description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(description, style: TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.4, color: AppColors.textSecondary)),
            ),
        ],
      ),
    );
  }
}


/// The profile of one student (contact details, studies, skills, work experience, resume) as a block
/// of sections, for pages that show a student among other things: the administrator's and the
/// supervisors' student page. What may be read is decided by the database.
class StudentProfileSections extends StatefulWidget {
  const StudentProfileSections({super.key, required this.studentId});
  final String studentId;

  @override
  State<StudentProfileSections> createState() => _StudentProfileSectionsState();
}

class _StudentProfileSectionsState extends State<StudentProfileSections> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _experience = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await HrDataService.instance.getStudentProfile(widget.studentId);
      final experience = await HrDataService.instance.getStudentExperience(widget.studentId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _experience = experience;
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

  Future<void> _viewResume(String path, String? fileName) async {
    try {
      final url = await HrDataService.instance.getResumeSignedUrl(path);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentPreviewScreen(url: url, fileName: fileName ?? path.split('/').last)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.apCouldNotOpenResume(friendlyError(e))), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return Padding(padding: const EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (_error != null || _profile == null) {
      return _InfoBox(child: Text(l10n.apCouldNotLoad(_error ?? ''), style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.error)));
    }
    final p = _profile!;
    final skills = List<String>.from(p['skills'] as List? ?? const []);
    final resumePath = p['resume_path'] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          title: l10n.apContact,
          child: Column(
            children: [
              _InfoRow(icon: Icons.email_outlined, label: l10n.apEmail, value: p['email'] as String?),
              _InfoRow(icon: Icons.phone_outlined, label: l10n.apPhone, value: p['phone'] as String?),
            ],
          ),
        ),
        _Section(
          title: l10n.apStudies,
          child: Column(
            children: [
              _InfoRow(icon: Icons.badge_outlined, label: l10n.studentRegNo, value: p['student_reg_no'] as String?),
              _InfoRow(icon: Icons.school_outlined, label: l10n.apProgramme, value: p['programme'] as String?),
              _InfoRow(icon: Icons.account_balance_outlined, label: l10n.apFaculty, value: p['faculty'] as String?),
              _InfoRow(icon: Icons.timeline_outlined, label: l10n.apSemester, value: p['semester']?.toString()),
              _InfoRow(icon: Icons.grade_outlined, label: l10n.apCgpa, value: p['cgpa']?.toString()),
            ],
          ),
        ),
        _Section(
          title: l10n.apSkills,
          child: skills.isEmpty
              ? Text(l10n.apNoSkills, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(20)),
                            child: Text(s, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.primaryText)),
                          ))
                      .toList(),
                ),
        ),
        _Section(
          title: l10n.apWorkExperience,
          child: _experience.isEmpty
              ? Text(l10n.apNoExperience, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary))
              : Column(children: _experience.map((e) => _ExperienceTile(data: e)).toList()),
        ),
        _Section(
          title: l10n.apResume,
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.primaryText),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  (p['resume_filename'] as String?) ?? l10n.apNoResume,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                ),
              ),
              if (resumePath != null) TextButton(onPressed: () => _viewResume(resumePath, p['resume_filename'] as String?), child: Text(l10n.apView)),
            ],
          ),
        ),
      ],
    );
  }
}
