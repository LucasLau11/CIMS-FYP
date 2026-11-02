import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/student_data_service.dart';
import '../../utils/file_picker_utils.dart';
import '../../utils/format_utils.dart';
import '../document_letter_fill_screen.dart';
import '../document_preview_screen.dart';
import 'student_profile_screen.dart';

// Parent Acknowledgement Form is intentionally not here — it's submitted by
// the parent account directly (see ParentAcknowledgementScreen), not
// uploaded by the student. Industrial Training Form (LI01) was replaced by
// two separate documents. There's no optional-documents section anymore —
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
      if (!mounted) return;
      setState(() {
        _reports = reports;
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
              labelColor: AppColors.primary,
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
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : RefreshIndicator(
                        onRefresh: _loadReports,
                        child: _reports.isEmpty
                            ? ListView(
                                children: [
                                  EmptyState(
                                    icon: Icons.assignment_outlined,
                                    title: l10n.noReportsYet,
                                    description: _hasActiveInternship ? l10n.tapSubmitFirstReportNote : l10n.reportsRequireActiveInternshipNote,
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(top: 8, bottom: 80),
                                itemCount: _reports.length,
                                itemBuilder: (_, i) => _ReportCard(data: _reports[i]),
                              ),
                      ),
                _isLoadingDocuments
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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

  void _showSubmitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _SubmitBottomSheet(onSubmitted: _loadReports),
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
                  const Icon(Icons.check_circle_outline, size: 13, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(l10n.approvedByCompanyAwaitingUniversity,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.primary)),
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
                  const Icon(Icons.attach_file, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(data['file_name'] as String? ?? l10n.attachment,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
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
    final title = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.documentTitleDialogTitle),
        content: TextField(controller: titleController, decoration: InputDecoration(hintText: l10n.documentTitleHint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, titleController.text.trim()), child: Text(l10n.continueLabel)),
        ],
      ),
    );
    if (title == null || title.isEmpty) return;
    if (!context.mounted) return;
    await pickAndUploadDocument(context, category: 'other', title: title, onChanged: onChanged);
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
            return {
              'student_name': profile?['full_name'] as String? ?? '',
              'student_reg_no': profile?['student_reg_no'] as String? ?? '',
              'programme': profile?['programme'] as String? ?? '',
              'company_name': activeApplication?['company_name'] as String? ?? '',
              'job_title': activeApplication?['job_title'] as String? ?? '',
              'today_date': _formatToday(),
            };
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorUploadFailed(e.toString())), backgroundColor: AppColors.error));
  }
}

class _SubmitBottomSheet extends StatefulWidget {
  final VoidCallback onSubmitted;

  const _SubmitBottomSheet({required this.onSubmitted});

  @override
  State<_SubmitBottomSheet> createState() => _SubmitBottomSheetState();
}

class _SubmitBottomSheetState extends State<_SubmitBottomSheet> {
  String _selectedType = 'monthly';
  final _periodController = TextEditingController();
  final _notesController = TextEditingController();
  PlatformFile? _pickedFile;
  bool _isSubmitting = false;
  String? _error;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'docx'], withData: true);
    if (result == null || result.files.isEmpty) return;
    setState(() => _pickedFile = result.files.single);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_periodController.text.trim().isEmpty) {
      setState(() => _error = l10n.errorEnterPeriod);
      return;
    }
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
        _error = l10n.errorCouldNotSubmit(e.toString());
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
              Text(l10n.newSubmission, style: AppTextStyles.h3),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.submissionType, style: AppTextStyles.label),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(),
            value: _selectedType,
            items: [
              DropdownMenuItem(value: 'monthly', child: Text(l10n.monthlyReportLabel)),
              DropdownMenuItem(value: 'final', child: Text(l10n.finalReportLabel)),
            ],
            onChanged: (v) => setState(() => _selectedType = v!),
          ),
          const SizedBox(height: 14),
          Text(l10n.period, style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextField(
            controller: _periodController,
            decoration: InputDecoration(hintText: l10n.periodHint),
          ),
          const SizedBox(height: 14),
          Text(l10n.notesOptional, style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(hintText: l10n.notesForSupervisorHint),
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
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary)),
                  Text(l10n.pdfDocxUpTo10mb,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
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
