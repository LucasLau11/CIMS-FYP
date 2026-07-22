import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';

class StudentApplyScreen extends StatefulWidget {
  final Map<String, dynamic> internship;

  const StudentApplyScreen({super.key, required this.internship});

  @override
  State<StudentApplyScreen> createState() => _StudentApplyScreenState();
}

class _StudentApplyScreenState extends State<StudentApplyScreen> {
  int _currentStep = 0;
  final _coverLetterController = TextEditingController();
  bool _useExistingResume = true;
  final List<String> _selectedSkills = ['Flutter', 'Dart'];
  bool _submitted = false;

  final List<String> _availableSkills = [
    'Flutter', 'Dart', 'Firebase', 'Python', 'SQL',
    'Java', 'React', 'Node.js', 'Git', 'REST API',
  ];

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _SuccessScreen(internship: widget.internship);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Apply',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
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
                    color: (widget.internship['logoColor'] as Color)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(widget.internship['logo'],
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: widget.internship['logoColor'])),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.internship['role'],
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    Text(
                        '${widget.internship['company']} · ${widget.internship['location']}',
                        style: AppTextStyles.bodySecondary
                            .copyWith(fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          // Step indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ProgressStepper(
              steps: const ['Resume', 'Cover Letter', 'Skills', 'Review'],
              currentStep: _currentStep,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: _buildStep(),
            ),
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
                      onPressed: () =>
                          setState(() => _currentStep--),
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentStep < 3) {
                        setState(() => _currentStep++);
                      } else {
                        setState(() => _submitted = true);
                      }
                    },
                    child: Text(
                        _currentStep == 3 ? 'Submit application' : 'Continue'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _ResumeStep(
          useExisting: _useExistingResume,
          onToggle: (v) => setState(() => _useExistingResume = v),
        );
      case 1:
        return _CoverLetterStep(controller: _coverLetterController);
      case 2:
        return _SkillsStep(
          available: _availableSkills,
          selected: _selectedSkills,
          onToggle: (skill) {
            setState(() {
              _selectedSkills.contains(skill)
                  ? _selectedSkills.remove(skill)
                  : _selectedSkills.add(skill);
            });
          },
        );
      case 3:
        return _ReviewStep(
          internship: widget.internship,
          useExistingResume: _useExistingResume,
          coverLetter: _coverLetterController.text,
          skills: _selectedSkills,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ResumeStep extends StatelessWidget {
  final bool useExisting;
  final ValueChanged<bool> onToggle;

  const _ResumeStep({required this.useExisting, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Resume / CV', style: AppTextStyles.h3),
        const SizedBox(height: 4),
        const Text('Select the resume you want to submit.',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        _OptionTile(
          title: 'Use existing resume',
          subtitle: 'tankai_resume_2026.pdf · 312 KB',
          icon: Icons.description_outlined,
          selected: useExisting,
          onTap: () => onToggle(true),
        ),
        const SizedBox(height: 10),
        _OptionTile(
          title: 'Upload a new resume',
          subtitle: 'PDF or DOCX, up to 5MB',
          icon: Icons.upload_file_outlined,
          selected: !useExisting,
          onTap: () => onToggle(false),
        ),
        if (!useExisting) ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      color: AppColors.primary, size: 32),
                  SizedBox(height: 8),
                  Text('Tap to upload',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CoverLetterStep extends StatelessWidget {
  final TextEditingController controller;

  const _CoverLetterStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cover letter', style: AppTextStyles.h3),
        const SizedBox(height: 4),
        const Text('Tell the company why you are a great fit.',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        TextField(
          controller: controller,
          maxLines: 12,
          decoration: const InputDecoration(
            hintText:
                'Dear Hiring Manager,\n\nI am writing to express my interest in...',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Icon(Icons.info_outline,
                size: 14, color: AppColors.textMuted),
            const SizedBox(width: 4),
            const Text('Tip: Mention relevant skills and experiences.',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textMuted)),
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

  const _SkillsStep({
    required this.available,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Relevant skills', style: AppTextStyles.h3),
        const SizedBox(height: 4),
        const Text('Select skills that match this internship.',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: available.map((skill) {
            final isSelected = selected.contains(skill);
            return GestureDetector(
              onTap: () => onToggle(skill),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryLight
                        : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      const Icon(Icons.check,
                          size: 14, color: AppColors.primary),
                    if (isSelected) const SizedBox(width: 4),
                    Text(skill,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary)),
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
  final bool useExistingResume;
  final String coverLetter;
  final List<String> skills;

  const _ReviewStep({
    required this.internship,
    required this.useExistingResume,
    required this.coverLetter,
    required this.skills,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review your application', style: AppTextStyles.h3),
        const SizedBox(height: 4),
        const Text('Please review before submitting.',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        _ReviewSection(
          title: 'Position',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(internship['role'],
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text(internship['company'],
                  style: AppTextStyles.bodySecondary),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _ReviewSection(
          title: 'Resume',
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf_outlined,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                useExistingResume
                    ? 'tankai_resume_2026.pdf'
                    : 'New resume uploaded',
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _ReviewSection(
          title: 'Cover letter',
          child: Text(
            coverLetter.isEmpty
                ? 'No cover letter provided'
                : coverLetter.length > 100
                    ? '${coverLetter.substring(0, 100)}...'
                    : coverLetter,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: coverLetter.isEmpty
                    ? AppColors.textMuted
                    : AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: 10),
        _ReviewSection(
          title: 'Skills',
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: skills
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(s,
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.primary)),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warningBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.warning),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Once submitted, your application cannot be edited.',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.warning),
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

class _OptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.infoBg : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 22,
                color: selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textPrimary)),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessScreen extends StatelessWidget {
  final Map<String, dynamic> internship;

  const _SuccessScreen({required this.internship});

  @override
  Widget build(BuildContext context) {
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
                decoration: const BoxDecoration(
                  color: AppColors.successBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline,
                    color: AppColors.success, size: 44),
              ),
              const SizedBox(height: 24),
              const Text('Application submitted!',
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                'Your application to ${internship['company']} has been sent. You will be notified when there is an update.',
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to search'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('View my applications'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
