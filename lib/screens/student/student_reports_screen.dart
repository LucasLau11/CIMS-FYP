import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/student_data_service.dart';
import '../../utils/file_picker_utils.dart';
import '../../utils/format_utils.dart';
import '../document_preview_screen.dart';
import 'student_profile_screen.dart';

// Parent Acknowledgement Form is intentionally not here — it's submitted by
// the parent account directly (see ParentAcknowledgementScreen), not
// uploaded by the student. Industrial Training Form (LI01) was replaced by
// two separate documents. There's no optional-documents section anymore —
// every required document is required.
const List<Map<String, String>> _requiredDocTypes = [
  {'category': 'offer_letter', 'title': 'Offer Letter'},
  {'category': 'indemnity_letter', 'title': 'Indemnity Letter'},
  {'category': 'company_acceptance_letter', 'title': 'Company Acceptance Letter'},
];

class StudentReportsScreen extends StatefulWidget {
  const StudentReportsScreen({super.key});

  @override
  State<StudentReportsScreen> createState() => _StudentReportsScreenState();
}

class _StudentReportsScreenState extends State<StudentReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoadingReports = true;
  List<Map<String, dynamic>> _reports = [];

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
      if (!mounted) return;
      setState(() {
        _reports = reports;
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: 'Submissions',
        actions: [
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
              tabs: const [
                Tab(text: 'Reports'),
                Tab(text: 'Documents'),
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
                                children: const [
                                  EmptyState(
                                    icon: Icons.assignment_outlined,
                                    title: 'No reports yet',
                                    description: 'Tap Submit to upload your first monthly or final report.',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubmitSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text('Submit', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Colors.white)),
      ),
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

  StatusBadge get _badge {
    switch (data['status']) {
      case 'approved':
        return StatusBadge.approved();
      case 'rejected':
        return StatusBadge.rejected();
      default:
        return StatusBadge.submitted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFinal = data['type'] == 'final';
    final title = '${isFinal ? 'Final Report' : 'Monthly Report'} — ${data['period_label']}';
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
                    Text('Submitted ${timeAgo(submittedAt)}', style: AppTextStyles.caption),
                  ],
                ),
              ),
              _badge,
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
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 13, color: AppColors.primary),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text('Approved by company supervisor · awaiting university review',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.primary)),
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
                    child: Text(data['file_name'] as String? ?? 'Attachment',
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
    final others = documents.where((d) => d['category'] == 'other').toList();
    final resumeFilename = profile?['resume_filename'] as String?;

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      children: [
        const SectionHeader(title: 'Required documents'),
        _ResumeChecklistTile(resumeFilename: resumeFilename),
        ..._requiredDocTypes.map(
          (t) => _DocumentTile(
            category: t['category']!,
            title: t['title']!,
            document: _docFor(t['category']!),
            onChanged: onChanged,
          ),
        ),
        const SectionHeader(title: 'Other documents'),
        ...others.map((d) => _DocumentTile(category: 'other', title: d['title'] as String? ?? d['file_name'] as String, document: d, onChanged: onChanged)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: OutlinedButton.icon(
            onPressed: () => _uploadOther(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add other document'),
          ),
        ),
      ],
    );
  }

  Future<void> _uploadOther(BuildContext context) async {
    final titleController = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Document title'),
        content: TextField(controller: titleController, decoration: const InputDecoration(hintText: 'e.g. Transcript')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, titleController.text.trim()), child: const Text('Continue')),
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
                Text('Resume / CV',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(hasResume ? resumeFilename! : 'Not uploaded yet',
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
              child: Text(hasResume ? 'Manage' : 'Upload',
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
                  Text('Not uploaded yet', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
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
                child: const Text('Upload',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
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
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'open', child: Text('View')),
                PopupMenuItem(value: 'remove', child: Text('Remove')),
              ],
            ),
        ],
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: const Text('File is too large. Maximum size is 10MB.'), backgroundColor: AppColors.error));
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.error));
  }
}

class _SubmitBottomSheet extends StatefulWidget {
  final VoidCallback onSubmitted;

  const _SubmitBottomSheet({required this.onSubmitted});

  @override
  State<_SubmitBottomSheet> createState() => _SubmitBottomSheetState();
}

class _SubmitBottomSheetState extends State<_SubmitBottomSheet> {
  String _selectedType = 'Monthly Report';
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
    if (_periodController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a period, e.g. "June 2026".');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final file = _pickedFile != null ? await resolvePickedFile(_pickedFile!) : null;
      await StudentDataService.instance.submitReport(
        type: _selectedType == 'Final Report' ? 'final' : 'monthly',
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
        _error = 'Could not submit: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('New submission', style: AppTextStyles.h3),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Submission type', style: AppTextStyles.label),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(),
            value: _selectedType,
            items: ['Monthly Report', 'Final Report'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _selectedType = v!),
          ),
          const SizedBox(height: 14),
          Text('Period', style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextField(
            controller: _periodController,
            decoration: const InputDecoration(hintText: 'e.g. June 2026'),
          ),
          const SizedBox(height: 14),
          Text('Notes (optional)', style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Add any notes for your supervisor...'),
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
                  Text(_pickedFile?.name ?? 'Tap to select file',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary)),
                  Text('PDF, DOCX up to 10MB',
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
                  : const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}
