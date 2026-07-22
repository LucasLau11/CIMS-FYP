import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';

class StudentReportsScreen extends StatefulWidget {
  const StudentReportsScreen({super.key});

  @override
  State<StudentReportsScreen> createState() => _StudentReportsScreenState();
}

class _StudentReportsScreenState extends State<StudentReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              labelStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
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
                _ReportsTab(),
                _DocumentsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubmitSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text('Submit',
            style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ),
    );
  }

  void _showSubmitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _SubmitBottomSheet(),
    );
  }
}

class _ReportsTab extends StatelessWidget {
  final List<Map<String, dynamic>> _reports = const [
    {
      'title': 'Monthly Report — June 2026',
      'type': 'monthly',
      'submittedDate': null,
      'dueDate': '30 Jun 2026',
      'status': 'pending',
      'feedback': null,
    },
    {
      'title': 'Monthly Report — May 2026',
      'type': 'monthly',
      'submittedDate': '28 May 2026',
      'dueDate': '31 May 2026',
      'status': 'approved',
      'feedback': 'Good progress. Elaborate on technical challenges next time.',
    },
    {
      'title': 'Monthly Report — April 2026',
      'type': 'monthly',
      'submittedDate': '29 Apr 2026',
      'dueDate': '30 Apr 2026',
      'status': 'approved',
      'feedback': 'Well structured. Keep it up.',
    },
    {
      'title': 'Final Report',
      'type': 'final',
      'submittedDate': null,
      'dueDate': '31 Aug 2026',
      'status': 'upcoming',
      'feedback': null,
    },
  ];

  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: _reports.length,
      itemBuilder: (_, i) => _ReportCard(data: _reports[i]),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ReportCard({required this.data});

  Color get _accentColor {
    switch (data['status']) {
      case 'approved': return AppColors.success;
      case 'rejected': return AppColors.error;
      case 'submitted': return AppColors.primary;
      case 'upcoming': return AppColors.textMuted;
      default: return AppColors.warning;
    }
  }

  StatusBadge get _badge {
    switch (data['status']) {
      case 'approved': return StatusBadge.approved();
      case 'rejected': return StatusBadge.rejected();
      case 'submitted': return StatusBadge.submitted();
      case 'upcoming': return const StatusBadge(
          label: 'Upcoming',
          backgroundColor: Color(0xFFF1EFE8),
          textColor: Color(0xFF5F5E5A));
      default: return StatusBadge.pending();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFinal = data['type'] == 'final';
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
                    Text(data['title'],
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    Text(
                      data['submittedDate'] != null
                          ? 'Submitted ${data['submittedDate']}'
                          : 'Due ${data['dueDate']}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              _badge,
            ],
          ),
          if (data['feedback'] != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.rate_review_outlined,
                      size: 14, color: AppColors.success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '"${data['feedback']}"',
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.success,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (data['status'] == 'pending') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.upload_file, size: 16),
                label: const Text('Submit report'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DocumentsTab extends StatelessWidget {
  final List<Map<String, dynamic>> _documents = const [
    {
      'title': 'Offer Letter',
      'fileName': 'offer_letter_tencent.pdf',
      'uploadedDate': '2 Jun 2026',
      'status': 'approved',
      'required': true,
      'fileSize': '245 KB',
    },
    {
      'title': 'Parent Acknowledgement Form',
      'fileName': 'parent_ack_form.pdf',
      'uploadedDate': '2 Jun 2026',
      'status': 'approved',
      'required': true,
      'fileSize': '180 KB',
    },
    {
      'title': 'Industrial Training Form (LI01)',
      'fileName': null,
      'uploadedDate': null,
      'status': 'missing',
      'required': true,
      'fileSize': null,
    },
    {
      'title': 'Resume / CV',
      'fileName': 'tankai_resume_2026.pdf',
      'uploadedDate': '30 May 2026',
      'status': 'approved',
      'required': true,
      'fileSize': '312 KB',
    },
    {
      'title': 'Insurance Certificate',
      'fileName': null,
      'uploadedDate': null,
      'status': 'missing',
      'required': false,
      'fileSize': null,
    },
  ];

  const _DocumentsTab();

  @override
  Widget build(BuildContext context) {
    final required = _documents.where((d) => d['required'] == true).toList();
    final optional = _documents.where((d) => d['required'] == false).toList();

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      children: [
        const SectionHeader(title: 'Required documents'),
        ...required.map((d) => _DocumentCard(data: d)),
        const SectionHeader(title: 'Optional documents'),
        ...optional.map((d) => _DocumentCard(data: d)),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _DocumentCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final bool isMissing = data['status'] == 'missing';

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
            child: Icon(
              isMissing ? Icons.upload_file_outlined : Icons.picture_as_pdf_outlined,
              size: 20,
              color: isMissing ? AppColors.error : AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'],
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                if (!isMissing)
                  Text('${data['fileName']} · ${data['fileSize']}',
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis)
                else
                  const Text('Not uploaded yet',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.error)),
                if (data['uploadedDate'] != null)
                  Text('Uploaded ${data['uploadedDate']}',
                      style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isMissing)
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Upload',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            )
          else
            StatusBadge.approved(),
        ],
      ),
    );
  }
}

class _SubmitBottomSheet extends StatefulWidget {
  const _SubmitBottomSheet();

  @override
  State<_SubmitBottomSheet> createState() => _SubmitBottomSheetState();
}

class _SubmitBottomSheetState extends State<_SubmitBottomSheet> {
  String _selectedType = 'Monthly Report';
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('New submission', style: AppTextStyles.h3),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Submission type', style: AppTextStyles.label),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(),
            value: _selectedType,
            items: ['Monthly Report', 'Final Report', 'Document']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _selectedType = v!),
          ),
          const SizedBox(height: 14),
          const Text('Notes (optional)', style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add any notes for your supervisor...',
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, style: BorderStyle.solid),
              ),
              child: const Column(
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      color: AppColors.primary, size: 28),
                  SizedBox(height: 6),
                  Text('Tap to select file',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary)),
                  Text('PDF, DOCX up to 10MB',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}
