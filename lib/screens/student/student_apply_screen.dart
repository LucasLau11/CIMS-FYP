import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/student_data_service.dart';
import '../../services/resume_parser_service.dart';
import '../../utils/file_picker_utils.dart';
import '../../utils/format_utils.dart';
import '../../l10n/app_localizations.dart';
import '../document_preview_screen.dart';
import 'student_profile_screen.dart';

class StudentApplyScreen extends StatefulWidget {
  final Map<String, dynamic> internship;

  const StudentApplyScreen({super.key, required this.internship});

  @override
  State<StudentApplyScreen> createState() => _StudentApplyScreenState();
}

class _StudentApplyScreenState extends State<StudentApplyScreen> {
  int _currentStep = 0;
  final _coverLetterController = TextEditingController();
  late List<String> _selectedSkills;
  bool _submitted = false;
  bool _isSubmitting = false;
  String? _submitError;

  bool _isLoadingResume = true;
  String? _resumeFilename;
  int? _resumeSizeBytes;
  String? _resumePath;

  static const List<String> _fallbackSkills = [
    'Flutter', 'Dart', 'Firebase', 'Python', 'SQL',
    'Java', 'React', 'Node.js', 'Git', 'REST API',
  ];
  List<String> _availableSkills = _fallbackSkills;

  bool _isExtractingCoverLetter = false;

  @override
  void initState() {
    super.initState();
    _loadResume();
  }

  Future<void> _loadResume() async {
    try {
      final profile = await AuthService.instance.getCurrentProfile();
      if (!mounted) return;
      final requiredSkills = (widget.internship['required_skills'] as List?)?.cast<String>() ?? [];
      final profileSkills = (profile?['skills'] as List?)?.cast<String>() ?? [];
      final merged = <String>[];
      for (final s in [...requiredSkills, ...profileSkills, ..._fallbackSkills]) {
        if (!merged.any((m) => m.toLowerCase() == s.toLowerCase())) merged.add(s);
      }
      setState(() {
        _resumeFilename = profile?['resume_filename'] as String?;
        _resumeSizeBytes = parseNum(profile?['resume_size_bytes'])?.toInt();
        _resumePath = profile?['resume_path'] as String?;
        _availableSkills = merged;
        _selectedSkills = merged.where(requiredSkills.contains).toList();
        _isLoadingResume = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingResume = false);
    }
  }

  Future<void> _uploadCoverLetter() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'docx'], withData: true);
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;

    setState(() => _isExtractingCoverLetter = true);
    try {
      final file = await resolvePickedFile(picked);
      final text = await ResumeParserService.instance.extractText(file);
      if (!mounted) return;
      setState(() {
        _coverLetterController.text = text.trim();
        _isExtractingCoverLetter = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.coverLetterLoadedFromFile), backgroundColor: AppColors.primary),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExtractingCoverLetter = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorCouldNotReadFile(e.toString())), backgroundColor: AppColors.error));
    }
  }

  bool get _hasResume => _resumeFilename != null && _resumeFilename!.trim().isNotEmpty;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });
    try {
      await StudentDataService.instance.applyToInternship(
        internshipId: widget.internship['id'] as String,
        coverLetter: _coverLetterController.text.trim(),
        skills: _selectedSkills,
      );
      await StudentDataService.instance.createSelfNotification(
        title: l10n.notifApplicationSubmittedTitle,
        body: l10n.notifApplicationSubmittedBody(widget.internship['company_name'] as String),
        type: 'application',
        relatedId: widget.internship['id'] as String,
      );
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_submitted) {
      return _SuccessScreen(internship: widget.internship);
    }

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context, false),
          ),
          title: Text(l10n.apply,
              style: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
        body: Column(
          children: [
            // Company header
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: nameColor(widget.internship['company_name'] as String).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(logoLetter(widget.internship['company_name'] as String),
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: nameColor(widget.internship['company_name'] as String))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.internship['title'] as String,
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        Text(
                            '${widget.internship['company_name']} · ${widget.internship['location']}',
                            style: AppTextStyles.bodySecondary.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Step indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: ProgressStepper(
                steps: [l10n.resume, l10n.coverLetter, l10n.hrSkills, l10n.review],
                currentStep: _currentStep,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: _buildStep(),
              ),
            ),
            if (_submitError != null)
              Container(
                width: double.infinity,
                color: AppColors.errorBg,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(_submitError!,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
              ),
            // Bottom nav
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              color: AppColors.surface,
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => setState(() => _currentStep--),
                        child: Text(l10n.back),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting || (_currentStep == 0 && !_hasResume)
                          ? null
                          : () {
                              if (_currentStep < 3) {
                                setState(() => _currentStep++);
                              } else {
                                _submit();
                              }
                            },
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_currentStep == 3 ? l10n.submitApplication : l10n.continueLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _ResumeStep(
          isLoading: _isLoadingResume,
          hasResume: _hasResume,
          resumeFilename: _resumeFilename,
          resumeSizeBytes: _resumeSizeBytes,
          onViewResume: _resumePath == null
              ? null
              : () async {
                  final l10n = AppLocalizations.of(context)!;
                  try {
                    final url = await AuthService.instance.getResumeSignedUrl(_resumePath!);
                    if (!mounted) return;
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => DocumentPreviewScreen(url: url, fileName: _resumeFilename ?? l10n.resume),
                    ));
                  } catch (_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.errorCouldNotOpenResume), backgroundColor: AppColors.error),
                    );
                  }
                },
          onGoToProfile: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentProfileScreen()));
            _loadResume();
          },
        );
      case 1:
        return _CoverLetterStep(
          controller: _coverLetterController,
          isExtracting: _isExtractingCoverLetter,
          onUpload: _uploadCoverLetter,
        );
      case 2:
        return _SkillsStep(
          available: _availableSkills,
          selected: _selectedSkills,
          onToggle: (skill) {
            setState(() {
              _selectedSkills.contains(skill) ? _selectedSkills.remove(skill) : _selectedSkills.add(skill);
            });
          },
        );
      case 3:
        return _ReviewStep(
          internship: widget.internship,
          resumeFilename: _resumeFilename,
          coverLetter: _coverLetterController.text,
          skills: _selectedSkills,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ResumeStep extends StatelessWidget {
  final bool isLoading;
  final bool hasResume;
  final String? resumeFilename;
  final int? resumeSizeBytes;
  final VoidCallback? onViewResume;
  final VoidCallback onGoToProfile;

  const _ResumeStep({
    required this.isLoading,
    required this.hasResume,
    required this.resumeFilename,
    required this.resumeSizeBytes,
    required this.onViewResume,
    required this.onGoToProfile,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.resumeCvHeading, style: AppTextStyles.h3),
        const SizedBox(height: 4),
        Text(l10n.resumeSubmittedWithApplicationNote,
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        if (hasResume)
          GestureDetector(
            onTap: onViewResume,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_outlined, size: 22, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(resumeFilename!,
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                        if (resumeSizeBytes != null)
                          Text(formatFileSize(resumeSizeBytes!), style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  const Icon(Icons.open_in_new, size: 16, color: AppColors.primary),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.errorBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.error),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(l10n.noResumeOnFile,
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(l10n.uploadResumeBeforeApplyingNote,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: onGoToProfile, child: Text(l10n.goToProfile)),
              ],
            ),
          ),
      ],
    );
  }
}

class _CoverLetterStep extends StatelessWidget {
  final TextEditingController controller;
  final bool isExtracting;
  final VoidCallback onUpload;

  const _CoverLetterStep({required this.controller, required this.isExtracting, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.coverLetter, style: AppTextStyles.h3),
        const SizedBox(height: 4),
        Text(l10n.coverLetterIntroNote,
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: isExtracting ? null : onUpload,
          icon: isExtracting
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.upload_file_outlined, size: 16),
          label: Text(isExtracting ? l10n.readingFile : l10n.uploadCoverLetterButton),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          maxLines: 12,
          decoration: InputDecoration(
            hintText: l10n.coverLetterHint,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(l10n.coverLetterTip,
                style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ],
    );
  }
}

class _SkillsStep extends StatelessWidget {
  final List<String> available;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  const _SkillsStep({required this.available, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.relevantSkillsHeading, style: AppTextStyles.h3),
        const SizedBox(height: 4),
        Text(l10n.selectMatchingSkillsNote,
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: available.map((skill) {
            final isSelected = selected.contains(skill);
            return GestureDetector(
              onTap: () => onToggle(skill),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryLight : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) const Icon(Icons.check, size: 14, color: AppColors.primary),
                    if (isSelected) const SizedBox(width: 4),
                    Text(skill,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  final Map<String, dynamic> internship;
  final String? resumeFilename;
  final String coverLetter;
  final List<String> skills;

  const _ReviewStep({
    required this.internship,
    required this.resumeFilename,
    required this.coverLetter,
    required this.skills,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.reviewYourApplication, style: AppTextStyles.h3),
        const SizedBox(height: 4),
        Text(l10n.pleaseReviewBeforeSubmitting,
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        _ReviewSection(
          title: l10n.position,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(internship['title'] as String,
                  style: TextStyle(
                      fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text(internship['company_name'] as String, style: AppTextStyles.bodySecondary),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _ReviewSection(
          title: l10n.resume,
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(resumeFilename ?? l10n.noResume,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _ReviewSection(
          title: l10n.coverLetter,
          child: Text(
            coverLetter.isEmpty
                ? l10n.noCoverLetterProvided
                : coverLetter.length > 100
                    ? '${coverLetter.substring(0, 100)}...'
                    : coverLetter,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: coverLetter.isEmpty ? AppColors.textMuted : AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: 10),
        _ReviewSection(
          title: l10n.hrSkills,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: skills
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(6)),
                      child: Text(s,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.primary)),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.warning),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.applicationCannotBeEditedNote,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.warning),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ReviewSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: AppTextStyles.label),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SuccessScreen extends StatelessWidget {
  final Map<String, dynamic> internship;

  const _SuccessScreen({required this.internship});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
                child: Icon(Icons.check_circle_outline, color: AppColors.success, size: 44),
              ),
              const SizedBox(height: 24),
              Text(l10n.applicationSubmittedExclaim, style: AppTextStyles.h2, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                l10n.applicationSubmittedDetail(internship['company_name'] as String),
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.backToSearch),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
