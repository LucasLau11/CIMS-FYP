import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../utils/validators.dart';
import '../../widgets/common/validated_field.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/student_data_service.dart';
import '../../utils/file_picker_utils.dart';
import '../../utils/format_utils.dart';
import '../document_letter_fill_screen.dart';
import '../document_preview_screen.dart';
import '../../services/document_template_service.dart';
import 'parent_acknowledgement_screen.dart';
import 'student_profile_screen.dart';
import '../../utils/error_text.dart';
import '../../utils/lang.dart';
import '../../utils/letter_auto_values.dart';

// The Parent Acknowledgement Form has its own tile (_ParentFormTile): the
// student opens it from here and hands the phone to their parent, who signs on
// it (see ParentAcknowledgementScreen). There are no parent accounts.
// Industrial Training Form (LI01) was replaced by two separate documents. There's no optional-documents section anymore —
// every required document is required.
//
// None of these three are manually uploaded by the student anymore:
// offer_letter and company_acceptance_letter are provided by company HR
// (uploaded / filled+signed respectively) once the student is accepted —
// see hr_applicants_screen.dart. Only indemnity_letter is filled + signed
// by the student themselves, via DocumentLetterFillScreen (see _LetterTile
// below), which records the generated PDF straight into `documents` — this
// list still just reads `documents`/`v_document_with_review`, so nothing
// else about how these render needs to change.
const List<String> _requiredDocCategories = ['offer_letter', 'indemnity_letter', 'company_acceptance_letter'];

String _requiredDocTitle(AppLocalizations l10n, String category) {
  switch (category) {
    case 'offer_letter':
      return l10n.docTypeOfferLetter;
    case 'indemnity_letter':
      return l10n.docTypeIndemnityLetter;
    default:
      return l10n.docTypeCompanyAcceptanceLetter;
  }
}

class StudentReportsScreen extends StatefulWidget {
  const StudentReportsScreen({super.key});

  @override
  State<StudentReportsScreen> createState() => _StudentReportsScreenState();
}

class _StudentReportsScreenState extends State<StudentReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoadingReports = true;
  List<Map<String, dynamic>> _reports = [];
  bool _hasActiveInternship = false;

  bool _isLoadingDocuments = true;
  List<Map<String, dynamic>> _documents = [];
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _requirements;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReports();
    _loadDocuments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoadingReports = true);
    try {
      final reports = await StudentDataService.instance.getMyReports();
      final hasActiveInternship = await StudentDataService.instance.hasActiveInternship();
      Map<String, dynamic>? requirements;
      try {
        requirements = await StudentDataService.instance.getReportRequirements();
      } catch (_) {
        // Non-fatal: without it the screen simply does not show the monthly-report count.
      }
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _requirements = requirements;
        _hasActiveInternship = hasActiveInternship;
        _isLoadingReports = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingReports = false);
    }
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoadingDocuments = true);
    try {
      final documents = await StudentDataService.instance.getMyDocuments();
      final profile = await AuthService.instance.getCurrentProfile();
      if (!mounted) return;
      setState(() {
        _documents = documents;
        _profile = profile;
        _isLoadingDocuments = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingDocuments = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: l10n.submissions,
        actions: [
          if (_hasActiveInternship)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showSubmitSheet(context),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryText,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2,
              labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: l10n.reports),
                Tab(text: l10n.documents),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _isLoadingReports
                    ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : RefreshIndicator(
                        onRefresh: _loadReports,
                        child: _reports.isEmpty
                            ? ListView(
                                children: [
                                  _buildRequirementBanner(),
                                  EmptyState(
                                    icon: Icons.assignment_outlined,
                                    title: l10n.noReportsYet,
                                    description: _hasActiveInternship ? l10n.tapSubmitFirstReportNote : l10n.reportsRequireActiveInternshipNote,
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(top: 8, bottom: 80),
                                itemCount: _reports.length + 1,
                                itemBuilder: (_, i) => i == 0 ? _buildRequirementBanner() : _ReportCard(data: _reports[i - 1]),
                              ),
                      ),
                _isLoadingDocuments
                    ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : RefreshIndicator(
                        onRefresh: _loadDocuments,
                        child: _DocumentsTab(
                          documents: _documents,
                          profile: _profile,
                          onChanged: _loadDocuments,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _hasActiveInternship
          ? FloatingActionButton.extended(
              onPressed: () => _showSubmitSheet(context),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: Text(l10n.submit, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Colors.white)),
            )
          : null,
    );
  }

  /// "Monthly reports: 2 of 3 submitted": the number of monthly reports comes from the length of the student's intake.
  Widget _buildRequirementBanner() {
    final req = _requirements;
    final required = (req?['required'] as num?)?.toInt();
    if (req == null || required == null || !_hasActiveInternship) return const SizedBox.shrink();
    final submitted = (req['submitted'] as num?)?.toInt() ?? 0;
    final done = submitted >= required;
    final intake = (req['intake'] as String?) ?? '';
    final plural = required == 1 ? '' : 's';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: done ? AppColors.successBg : AppColors.infoBg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(done ? Icons.check_circle_outline : Icons.assignment_outlined, size: 20, color: done ? AppColors.success : AppColors.info),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    tr('Monthly reports: $submitted of $required submitted',
                        ms: 'Laporan bulanan: $submitted daripada $required dihantar',
                        zh: '月度报告：已提交 $submitted / $required'),
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: done ? AppColors.success : AppColors.info)),
                const SizedBox(height: 2),
                Text(
                    done
                        ? tr('All the monthly reports your intake needs are in.',
                            ms: 'Semua laporan bulanan yang diperlukan oleh intake anda telah dihantar.',
                            zh: '您所在批次要求的月度报告已全部提交。')
                        : tr('Your intake ($intake) lasts $required month$plural, so $required monthly report${required == 1 ? ' is' : 's are'} required.',
                            ms: 'Intake anda ($intake) berlangsung $required bulan, jadi $required laporan bulanan diperlukan.',
                            zh: '您的批次（$intake）为期 $required 个月，因此需要提交 $required 份月度报告。'),
                    style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _SubmitBottomSheet(onSubmitted: _loadReports, requirements: _requirements),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ReportCard({required this.data});

  Color get _accentColor {
    switch (data['status']) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  StatusBadge _badge(BuildContext context) {
    switch (data['status']) {
      case 'approved':
        return StatusBadge.approved(context);
      case 'rejected':
        return StatusBadge.rejected(context);
      default:
        return StatusBadge.submitted(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isFinal = data['type'] == 'final';
    final title = '${isFinal ? l10n.finalReportLabel : l10n.monthlyReportLabel} — ${data['period_label']}';
    final submittedAt = DateTime.parse(data['submitted_at'] as String);
    final storagePath = data['storage_path'] as String?;
    final feedback = data['feedback'] as String?;

    return AccentCard(
      accentColor: _accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isFinal ? AppColors.infoBg : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isFinal ? Icons.library_books_outlined : Icons.assignment_outlined,
                  size: 18,
                  color: isFinal ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text(l10n.supSubmittedAgo(timeAgo(context, submittedAt)), style: AppTextStyles.caption),
                  ],
                ),
              ),
              _badge(context),
            ],
          ),
          if ((data['notes'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(data['notes'] as String,
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
          ],
          if (data['status'] == 'submitted' && data['company_review_status'] == 'approved') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 13, color: AppColors.primaryText),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(l10n.approvedByCompanyAwaitingUniversity,
                        style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.primaryText)),
                  ),
                ],
              ),
            ),
          ],
          if (storagePath != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                try {
                  final url = await StudentDataService.instance.getReportSignedUrl(storagePath);
                  if (!context.mounted) return;
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => DocumentPreviewScreen(url: url, fileName: (data['file_name'] as String?) ?? storagePath.split('/').last),
                  ));
                } catch (_) {}
              },
              child: Row(
                children: [
                  Icon(Icons.attach_file, size: 14, color: AppColors.primaryText),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(data['file_name'] as String? ?? l10n.attachment,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: 'Inter', fontSize: 12, color: AppColors.primary, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ),
          ],
          if (feedback != null && feedback.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.rate_review_outlined, size: 14, color: AppColors.success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('"$feedback"',
                        style: TextStyle(
                            fontFamily: 'Inter', fontSize: 12, color: AppColors.success, fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DocumentsTab extends StatelessWidget {
  final List<Map<String, dynamic>> documents;
  final Map<String, dynamic>? profile;
  final VoidCallback onChanged;

  const _DocumentsTab({required this.documents, required this.profile, required this.onChanged});

  Map<String, dynamic>? _docFor(String category) {
    for (final d in documents) {
      if (d['category'] == category) return d;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final others = documents.where((d) => d['category'] == 'other').toList();
    final resumeFilename = profile?['resume_filename'] as String?;

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      children: [
        SectionHeader(title: l10n.requiredDocuments),
        _ResumeChecklistTile(resumeFilename: resumeFilename),
        ..._requiredDocCategories.map(
          (category) => _LetterTile(
            category: category,
            title: _requiredDocTitle(l10n, category),
            document: _docFor(category),
            onChanged: onChanged,
          ),
        ),
        _ParentFormTile(profile: profile),
        SectionHeader(title: l10n.otherDocuments),
        ...others.map((d) => _DocumentTile(category: 'other', title: d['title'] as String? ?? d['file_name'] as String, document: d, onChanged: onChanged)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: OutlinedButton.icon(
            onPressed: () => _uploadOther(context),
            icon: const Icon(Icons.add, size: 16),
            label: Text(l10n.addOtherDocument),
          ),
        ),
      ],
    );
  }

  Future<void> _uploadOther(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController();
    final titleFormKey = GlobalKey<FormState>();
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.documentTitleDialogTitle),
        content: Form(
          key: titleFormKey,
          child: ValidatedField(
            controller: titleController,
            fieldValidator: (v) => Validators.text(v, field: 'Document title', min: 3, max: 80),
            autofocus: true,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            hintText: l10n.documentTitleHint,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              if (titleFormKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, titleController.text.trim());
              }
            },
            child: Text(l10n.continueLabel),
          ),
        ],
      ),
    );
    titleController.dispose();
    if (title == null || title.isEmpty) return;
    if (!context.mounted) return;
    await pickAndUploadDocument(context, category: 'other', title: title, onChanged: onChanged);
  }
}

/// Status of the Parent Acknowledgement Form and the way into it. Unlike the
/// other letters this one is signed by the parent on the student's phone, and
/// it lives in `document_submissions` rather than `documents`.
class _ParentFormTile extends StatefulWidget {
  final Map<String, dynamic>? profile;

  const _ParentFormTile({required this.profile});

  @override
  State<_ParentFormTile> createState() => _ParentFormTileState();
}

class _ParentFormTileState extends State<_ParentFormTile> {
  bool _loading = true;
  bool _templateMissing = false;
  Map<String, dynamic>? _submission;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final template = await DocumentTemplateService.instance.getActiveTemplate('parent_acknowledgement');
      if (template == null) {
        if (!mounted) return;
        setState(() {
          _templateMissing = true;
          _loading = false;
        });
        return;
      }
      final submission = await DocumentTemplateService.instance
          .getSubmission(templateId: template['id'] as String, studentId: AuthService.instance.currentUserId!);
      if (!mounted) return;
      setState(() {
        _templateMissing = false;
        _submission = submission;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _open() async {
    final activeApplication = await StudentDataService.instance.getActiveApplicationSummary();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParentAcknowledgementScreen(
          studentId: AuthService.instance.currentUserId!,
          studentName: widget.profile?['full_name'] as String? ?? '',
          studentRegNo: widget.profile?['student_reg_no'] as String?,
          programme: widget.profile?['programme'] as String?,
          companyName: activeApplication?['company_name'] as String?,
        ),
      ),
    );
    _load();
  }

  Future<void> _view() async {
    final path = _submission?['generated_pdf_path'] as String?;
    if (path == null) return;
    try {
      final url = await DocumentTemplateService.instance.getSubmissionSignedUrl(path);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentPreviewScreen(url: url, fileName: 'Parent Acknowledgement Form.pdf')));
    } catch (_) {
      // Non-fatal — just don't navigate.
    }
  }

  @override
  Widget build(BuildContext context) {
    final signed = _submission != null;
    final submittedAt = DateTime.tryParse(_submission?['submitted_at'] as String? ?? '')?.toLocal();
    final accent = signed ? AppColors.success : (_templateMissing ? AppColors.textMuted : AppColors.error);

    final String subtitle;
    if (_loading) {
      subtitle = 'Checking…';
    } else if (_templateMissing) {
      subtitle = 'The form has not been published yet. Please check back later.';
    } else if (signed) {
      subtitle = submittedAt == null ? 'Signed' : 'Signed on ${submittedAt.day}/${submittedAt.month}/${submittedAt.year}';
    } else {
      subtitle = 'Not signed yet. Your parent or guardian signs it on your phone.';
    }

    return GestureDetector(
      onTap: signed ? _view : null,
      child: AccentCard(
        accentColor: accent,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: signed ? AppColors.successBg : (_templateMissing ? AppColors.surfaceVariant : AppColors.errorBg),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(signed ? Icons.picture_as_pdf_outlined : Icons.family_restroom_outlined, size: 20, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Parent / guardian acknowledgement',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: signed || _templateMissing || _loading ? AppColors.textSecondary : AppColors.error)),
                ],
              ),
            ),
            if (!_loading && !_templateMissing && !signed) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _open,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                  child: const Text('Open form', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResumeChecklistTile extends StatelessWidget {
  final String? resumeFilename;

  const _ResumeChecklistTile({required this.resumeFilename});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasResume = resumeFilename != null && resumeFilename!.isNotEmpty;
    return AccentCard(
      accentColor: hasResume ? AppColors.success : AppColors.error,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasResume ? AppColors.successBg : AppColors.errorBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(hasResume ? Icons.picture_as_pdf_outlined : Icons.upload_file_outlined,
                size: 20, color: hasResume ? AppColors.success : AppColors.error),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.resumeCvHeading,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(hasResume ? resumeFilename! : l10n.notUploadedYet,
                    style: TextStyle(
                        fontFamily: 'Inter', fontSize: 12, color: hasResume ? AppColors.textSecondary : AppColors.error)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentProfileScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
              child: Text(hasResume ? l10n.manage : l10n.upload,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final String category;
  final String title;
  final Map<String, dynamic>? document;
  final VoidCallback onChanged;

  const _DocumentTile({required this.category, required this.title, required this.document, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMissing = document == null;

    return AccentCard(
      accentColor: isMissing ? AppColors.error : AppColors.success,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isMissing ? AppColors.errorBg : AppColors.successBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(isMissing ? Icons.upload_file_outlined : Icons.picture_as_pdf_outlined,
                size: 20, color: isMissing ? AppColors.error : AppColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                if (!isMissing)
                  Text('${document!['file_name']} · ${formatFileSize(parseNum(document!['file_size_bytes'])?.toInt() ?? 0)}',
                      style: AppTextStyles.caption, overflow: TextOverflow.ellipsis)
                else
                  Text(l10n.notUploadedYet, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isMissing)
            GestureDetector(
              onTap: () => pickAndUploadDocument(context, category: category, title: null, onChanged: onChanged),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                child: Text(l10n.upload,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            )
          else
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
              onSelected: (value) async {
                if (value == 'open') {
                  try {
                    final url = await StudentDataService.instance.getDocumentSignedUrl(document!['storage_path'] as String);
                    if (!context.mounted) return;
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => DocumentPreviewScreen(
                        url: url,
                        fileName: (document!['file_name'] as String?) ?? (document!['storage_path'] as String).split('/').last,
                      ),
                    ));
                  } catch (_) {}
                } else if (value == 'remove') {
                  await StudentDataService.instance
                      .removeDocument(document!['id'] as String, document!['storage_path'] as String);
                  onChanged();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'open', child: Text(l10n.view)),
                PopupMenuItem(value: 'remove', child: Text(l10n.remove)),
              ],
            ),
        ],
      ),
    );
  }
}

/// Tile for offer_letter/indemnity_letter/company_acceptance_letter — none
/// of which the student manually uploads anymore (see the comment above
/// `_requiredDocCategories`). Only indemnity_letter is student-filled (Fill
/// & Sign); offer_letter and company_acceptance_letter are both provided by
/// company HR (upload / fill+sign respectively — see hr_applicants_screen
/// .dart), so the student only ever views them once present.
class _LetterTile extends StatelessWidget {
  final String category;
  final String title;
  final Map<String, dynamic>? document;
  final VoidCallback onChanged;

  const _LetterTile({required this.category, required this.title, required this.document, required this.onChanged});

  String _formatToday() {
    final d = DateTime.now();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _openFillScreen(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentLetterFillScreen(
          purpose: category,
          title: title,
          studentId: AuthService.instance.currentUserId!,
          loadAutoValues: () async {
            final profile = await AuthService.instance.getCurrentProfile();
            final activeApplication = await StudentDataService.instance.getActiveApplicationSummary();
            final values = <String, String>{
              'student_name': profile?['full_name'] as String? ?? '',
              'student_reg_no': profile?['student_reg_no'] as String? ?? '',
              'programme': profile?['programme'] as String? ?? '',
              'company_name': activeApplication?['company_name'] as String? ?? '',
              'job_title': activeApplication?['job_title'] as String? ?? '',
              'today_date': _formatToday(),
            };
            try {
              // IC, address, phone, dates of the internship, the company's address and supervisor...
              values.addAll(letterValuesFromContext(await StudentDataService.instance.getLetterContext()));
            } catch (_) {
              // Non-fatal: the form just starts with fewer fields filled in.
            }
            return values;
          },
          recordDocument: (bytes, fileName) => StudentDataService.instance.recordGeneratedDocument(category: category, pdfBytes: bytes, fileName: fileName),
        ),
      ),
    );
    onChanged();
  }

  Future<void> _viewDocument(BuildContext context) async {
    try {
      final url = await StudentDataService.instance.getDocumentSignedUrl(document!['storage_path'] as String);
      if (!context.mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => DocumentPreviewScreen(
          url: url,
          fileName: (document!['file_name'] as String?) ?? (document!['storage_path'] as String).split('/').last,
        ),
      ));
    } catch (_) {
      // Matches _DocumentTile's "open" action — non-fatal, just don't navigate.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPresent = document != null;
    final isProvidedByCompany = category == 'offer_letter' || category == 'company_acceptance_letter';
    final canFillSign = !isPresent && !isProvidedByCompany;

    return GestureDetector(
      onTap: isPresent ? () => _viewDocument(context) : null,
      child: AccentCard(
        accentColor: isPresent ? AppColors.success : AppColors.error,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPresent ? AppColors.successBg : AppColors.errorBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPresent ? Icons.picture_as_pdf_outlined : Icons.edit_document,
                size: 20,
                color: isPresent ? AppColors.success : AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  if (isPresent)
                    Text('${document!['file_name']} · ${formatFileSize(parseNum(document!['file_size_bytes'])?.toInt() ?? 0)}',
                        style: AppTextStyles.caption, overflow: TextOverflow.ellipsis)
                  else if (isProvidedByCompany)
                    Text(l10n.docAwaitingCompanyUpload, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error))
                  else
                    Text(l10n.notUploadedYet, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
                ],
              ),
            ),
            if (canFillSign) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _openFillScreen(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                  child: Text(l10n.docFillAndSignAction,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> pickAndUploadDocument(
  BuildContext context, {
  required String category,
  required String? title,
  required VoidCallback onChanged,
}) async {
  final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'docx'], withData: true);
  if (result == null || result.files.isEmpty) return;
  final picked = result.files.single;

  if (picked.size > 10 * 1024 * 1024) {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.errorFileTooLarge10mb), backgroundColor: AppColors.error));
    return;
  }

  try {
    final file = await resolvePickedFile(picked);
    await StudentDataService.instance.uploadDocument(
      category: category,
      title: title,
      file: file,
      fileName: picked.name,
      fileSizeBytes: picked.size,
    );
    onChanged();
  } catch (e) {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorUploadFailed(friendlyError(e))), backgroundColor: AppColors.error));
  }
}

class _SubmitBottomSheet extends StatefulWidget {
  final VoidCallback onSubmitted;
  final Map<String, dynamic>? requirements;

  const _SubmitBottomSheet({required this.onSubmitted, this.requirements});

  @override
  State<_SubmitBottomSheet> createState() => _SubmitBottomSheetState();
}

class _SubmitBottomSheetState extends State<_SubmitBottomSheet> {
  String _selectedType = 'monthly';
  String _autoPeriod = '';
  final _periodController = TextEditingController();
  final _notesController = TextEditingController();
  final _periodKey = GlobalKey<FormFieldState<String>>();
  final _notesKey = GlobalKey<FormFieldState<String>>();
  PlatformFile? _pickedFile;
  bool _isSubmitting = false;
  bool _attempted = false;
  String? _error;

  static const int _maxFileBytes = 10 * 1024 * 1024;

  int? get _required => (widget.requirements?['required'] as num?)?.toInt();
  int get _submittedMonthly => (widget.requirements?['submitted'] as num?)?.toInt() ?? 0;

  /// Every monthly report the intake needs is already in: only the final report can be sent now.
  bool get _monthlyAllowed => _required == null || _submittedMonthly < _required!;

  String _periodFor(String type) => type == 'final'
      ? tr('Final report', ms: 'Laporan akhir', zh: '最终报告')
      : tr('Month ${_submittedMonthly + 1}', ms: 'Bulan ${_submittedMonthly + 1}', zh: '第 ${_submittedMonthly + 1} 个月');

  @override
  void initState() {
    super.initState();
    _selectedType = _monthlyAllowed ? 'monthly' : 'final';
    _autoPeriod = _periodFor(_selectedType);
    _periodController.text = _autoPeriod; // suggested, still editable
  }

  void _chooseType(String type) {
    setState(() {
      // the suggested period follows the type, unless the student has typed their own
      if (_periodController.text.trim().isEmpty || _periodController.text == _autoPeriod) {
        _autoPeriod = _periodFor(type);
        _periodController.text = _autoPeriod;
      }
      _selectedType = type;
    });
  }

  /// The report itself must be attached, and within the size limit.
  String? get _fileError {
    final file = _pickedFile;
    if (file == null) return 'Attach your report file (PDF or DOCX).';
    if (file.size > _maxFileBytes) {
      final mb = (file.size / (1024 * 1024)).toStringAsFixed(1);
      return 'This file is $mb MB. The maximum is 10 MB.';
    }
    return null;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'docx'], withData: true);
    if (result == null || result.files.isEmpty) return;
    setState(() => _pickedFile = result.files.single);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _attempted = true);
    final periodOk = _periodKey.currentState?.validate() ?? false;
    final notesOk = _notesKey.currentState?.validate() ?? false;
    if (!periodOk || !notesOk || _fileError != null) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final file = _pickedFile != null ? await resolvePickedFile(_pickedFile!) : null;
      await StudentDataService.instance.submitReport(
        type: _selectedType,
        periodLabel: _periodController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        file: file,
        fileName: _pickedFile?.name,
        fileSizeBytes: _pickedFile?.size,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSubmitted();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = l10n.errorCouldNotSubmit(friendlyError(e));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(l10n.newSubmission, style: AppTextStyles.h3, overflow: TextOverflow.ellipsis)),
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.submissionType, style: AppTextStyles.label),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(),
            value: _selectedType,
            items: [
              if (_monthlyAllowed) DropdownMenuItem(value: 'monthly', child: Text(l10n.monthlyReportLabel)),
              DropdownMenuItem(value: 'final', child: Text(l10n.finalReportLabel)),
            ],
            onChanged: (v) => _chooseType(v!),
          ),
          if (!_monthlyAllowed) ...[
            const SizedBox(height: 6),
            Text(
                tr('All $_required monthly reports your intake needs are already in.',
                    ms: 'Semua $_required laporan bulanan yang diperlukan oleh intake anda telah dihantar.',
                    zh: '您所在批次要求的 $_required 份月度报告已全部提交。'),
                style: AppTextStyles.caption),
          ],
          const SizedBox(height: 14),
          Text(l10n.period, style: AppTextStyles.label),
          const SizedBox(height: 8),
          ValidatedField(
            key: _periodKey,
            controller: _periodController,
            fieldValidator: (v) => v.trim().isEmpty ? l10n.errorEnterPeriod : Validators.text(v, field: 'Period', min: 3, max: 60),
            maxLength: 60,
            hintText: l10n.periodHint,
          ),
          const SizedBox(height: 14),
          Text(l10n.notesOptional, style: AppTextStyles.label),
          const SizedBox(height: 8),
          ValidatedField(
            key: _notesKey,
            controller: _notesController,
            fieldValidator: (v) => Validators.text(v, field: 'Notes', required: false, max: 1000),
            maxLines: 3,
            maxLength: 1000,
            showSuccess: false,
            hintText: l10n.notesForSupervisorHint,
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Icon(_pickedFile != null ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
                      color: AppColors.primary, size: 28),
                  const SizedBox(height: 6),
                  Text(_pickedFile?.name ?? l10n.tapToSelectFile,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primaryText)),
                  Text(l10n.pdfDocxUpTo10mb,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
          if (_attempted && _fileError != null || (_pickedFile != null && _fileError != null)) ...[
            const SizedBox(height: 6),
            Text(_fileError!, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(l10n.submit),
            ),
          ),
        ],
      ),
    );
  }
}
