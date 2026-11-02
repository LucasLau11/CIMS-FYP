import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/hr_data_service.dart';
import '../../utils/file_picker_utils.dart';
import '../../utils/format_utils.dart';
import '../document_letter_fill_screen.dart';
import '../document_preview_screen.dart';
import '../student/address_picker_screen.dart';

class HrApplicantsScreen extends StatefulWidget {
  const HrApplicantsScreen({super.key});

  @override
  State<HrApplicantsScreen> createState() => _HrApplicantsScreenState();
}

class _HrApplicantsScreenState extends State<HrApplicantsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _applicants = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final applicants = await HrDataService.instance.getApplicants();
      if (!mounted) return;
      setState(() {
        _applicants = applicants;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _filtered(String status) => _applicants.where((a) => a['status'] == status).toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final newCount = _filtered('pending').length;
    final interviewCount = _filtered('interview').length;
    final acceptedCount = _filtered('active').length;
    final rejectedCount = _filtered('rejected').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: l10n.hrApplicants),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Container(
                  color: AppColors.surface,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textMuted,
                    indicatorColor: AppColors.primary,
                    labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
                    tabs: [
                      Tab(text: l10n.hrTabNew(newCount)),
                      Tab(text: l10n.hrTabInterview(interviewCount)),
                      Tab(text: l10n.hrTabAccepted(acceptedCount)),
                      Tab(text: l10n.hrTabRejected(rejectedCount)),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: ['pending', 'interview', 'active', 'rejected'].map((status) {
                      final items = _filtered(status);
                      if (items.isEmpty) {
                        return EmptyState(icon: Icons.people_outline, title: l10n.hrNoApplicantsHere, description: l10n.hrApplicantsAppearHere);
                      }
                      return RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 24),
                          itemCount: items.length,
                          itemBuilder: (_, i) => _ApplicantCard(
                            data: items[i],
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => ApplicantDetailScreen(data: items[i])));
                              _load();
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _ApplicantCard({required this.data, required this.onTap});

  Color get _accentColor {
    switch (data['status']) {
      case 'active':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'interview':
        return AppColors.warning;
      default:
        return AppColors.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = data['student_name'] as String;
    return AccentCard(
      onTap: onTap,
      accentColor: _accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceVariant,
                child: Text(logoLetter(name), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text('${data['programme'] ?? l10n.notSpecified} · ${data['internship_title'] ?? ''}', style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          if (data['interview_at'] != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.videocam_outlined, size: 15, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(l10n.hrInterviewColon('${DateTime.parse(data['interview_at'] as String).toLocal()}'.split('.').first),
                        style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.warning)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(l10n.hrAppliedAgo(timeAgo(context, DateTime.parse(data['applied_at'] as String))), style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class ApplicantDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const ApplicantDetailScreen({super.key, required this.data});

  @override
  State<ApplicantDetailScreen> createState() => _ApplicantDetailScreenState();
}

class _ApplicantDetailScreenState extends State<ApplicantDetailScreen> {
  bool _isBusy = false;
  bool _isLoadingOfferLetter = false;
  Map<String, dynamic>? _offerLetterDoc;
  bool _isLoadingAcceptanceLetter = false;
  Map<String, dynamic>? _acceptanceLetterDoc;

  @override
  void initState() {
    super.initState();
    if (widget.data['status'] == 'active') {
      _loadOfferLetter();
      _loadAcceptanceLetter();
    }
  }

  Future<void> _loadAcceptanceLetter() async {
    setState(() => _isLoadingAcceptanceLetter = true);
    try {
      final doc = await HrDataService.instance.getLetterDocument(widget.data['student_id'] as String, 'company_acceptance_letter');
      if (!mounted) return;
      setState(() {
        _acceptanceLetterDoc = doc;
        _isLoadingAcceptanceLetter = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingAcceptanceLetter = false);
    }
  }

  String _formatToday() {
    final d = DateTime.now();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _fillAcceptanceLetter() async {
    final l10n = AppLocalizations.of(context)!;
    final studentId = widget.data['student_id'] as String;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentLetterFillScreen(
          purpose: 'company_acceptance_letter',
          title: l10n.docTypeCompanyAcceptanceLetter,
          studentId: studentId,
          loadAutoValues: () async => {
            'student_name': widget.data['student_name'] as String? ?? '',
            'student_reg_no': widget.data['student_reg_no'] as String? ?? '',
            'programme': widget.data['programme'] as String? ?? '',
            'company_name': widget.data['company_name'] as String? ?? '',
            'job_title': widget.data['internship_title'] as String? ?? '',
            'today_date': _formatToday(),
          },
          recordDocument: (bytes, fileName) => HrDataService.instance.uploadGeneratedLetter(
            studentId: studentId,
            category: 'company_acceptance_letter',
            pdfBytes: bytes,
            fileName: fileName,
          ),
        ),
      ),
    );
    _loadAcceptanceLetter();
  }

  Future<void> _viewAcceptanceLetter() async {
    final path = _acceptanceLetterDoc?['storage_path'] as String?;
    if (path == null) return;
    try {
      final url = await HrDataService.instance.getOfferLetterSignedUrl(path);
      if (!mounted) return;
      final fileName = (_acceptanceLetterDoc?['file_name'] as String?) ?? path.split('/').last;
      Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentPreviewScreen(url: url, fileName: fileName)));
    } catch (_) {
      // Non-fatal — just don't navigate.
    }
  }

  Future<void> _loadOfferLetter() async {
    setState(() => _isLoadingOfferLetter = true);
    try {
      final doc = await HrDataService.instance.getOfferLetterDocument(widget.data['student_id'] as String);
      if (!mounted) return;
      setState(() {
        _offerLetterDoc = doc;
        _isLoadingOfferLetter = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingOfferLetter = false);
    }
  }

  Future<void> _uploadOfferLetter() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'docx'], withData: true);
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;

    if (picked.size > 10 * 1024 * 1024) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorFileTooLarge10mb), backgroundColor: AppColors.error));
      return;
    }

    setState(() => _isLoadingOfferLetter = true);
    try {
      final file = await resolvePickedFile(picked);
      await HrDataService.instance.uploadOfferLetter(
        studentId: widget.data['student_id'] as String,
        file: file,
        fileName: picked.name,
        fileSizeBytes: picked.size,
      );
      await _loadOfferLetter();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingOfferLetter = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not upload offer letter: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _viewOfferLetter() async {
    final path = _offerLetterDoc?['storage_path'] as String?;
    if (path == null) return;
    try {
      final url = await HrDataService.instance.getOfferLetterSignedUrl(path);
      if (!mounted) return;
      final fileName = (_offerLetterDoc?['file_name'] as String?) ?? path.split('/').last;
      Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentPreviewScreen(url: url, fileName: fileName)));
    } catch (_) {
      // Non-fatal — just don't navigate.
    }
  }

  Future<void> _reject() async {
    setState(() => _isBusy = true);
    try {
      await HrDataService.instance.updateApplicationStatus(
        applicationId: widget.data['id'] as String,
        studentId: widget.data['student_id'] as String,
        status: 'rejected',
        internshipTitle: widget.data['internship_title'] as String?,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not reject: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _accept() async {
    setState(() => _isBusy = true);
    try {
      await HrDataService.instance.updateApplicationStatus(
        applicationId: widget.data['id'] as String,
        studentId: widget.data['student_id'] as String,
        status: 'active',
        internshipTitle: widget.data['internship_title'] as String?,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not accept: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _viewResume() async {
    final path = widget.data['resume_path'] as String?;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No resume uploaded.'), backgroundColor: AppColors.warning));
      return;
    }
    try {
      final url = await HrDataService.instance.getResumeSignedUrl(path);
      if (!mounted) return;
      final fileName = (widget.data['resume_filename'] as String?) ?? path.split('/').last;
      Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentPreviewScreen(url: url, fileName: fileName)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open resume: $e'), backgroundColor: AppColors.error));
    }
  }

  void _showScheduleInterviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _ScheduleInterviewSheet(
        onScheduled: (dateTime, mode, location) async {
          setState(() => _isBusy = true);
          try {
            await HrDataService.instance.updateApplicationStatus(
              applicationId: widget.data['id'] as String,
              studentId: widget.data['student_id'] as String,
              status: 'interview',
              interviewAt: dateTime,
              interviewMode: mode,
              interviewLocation: location,
              internshipTitle: widget.data['internship_title'] as String?,
            );
            if (!mounted) return;
            Navigator.pop(context); // close the sheet
            Navigator.pop(context); // close the detail screen — back to the list, which refreshes
          } catch (e) {
            if (!mounted) return;
            setState(() => _isBusy = false);
            Navigator.pop(context); // close the sheet so the error is visible
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not schedule interview: $e'), backgroundColor: AppColors.error));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = widget.data;
    final name = data['student_name'] as String;
    final isNew = data['status'] == 'pending';
    final isInterview = data['status'] == 'interview';
    final isActive = data['status'] == 'active';
    final skills = List<String>.from(data['skills'] as List? ?? []);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(l10n.hrApplicantProfile, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.infoBg,
                  child: Text(logoLetter(name), style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
                const SizedBox(height: 10),
                Text(name, style: AppTextStyles.h2),
                Text((data['programme'] as String?) ?? l10n.notSpecified, style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(l10n.hrAppliedFor, style: AppTextStyles.label),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Row(
              children: [
                const Icon(Icons.work_outline, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text((data['internship_title'] as String?) ?? '', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(l10n.hrAppliedAgo(timeAgo(context, DateTime.parse(data['applied_at'] as String))), style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.resume, style: AppTextStyles.label),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text((data['resume_filename'] as String?) ?? l10n.hrNoResumeUploaded, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500)),
                ),
                if (data['resume_path'] != null) TextButton(onPressed: _viewResume, child: Text(l10n.view)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.hrCoverLetter, style: AppTextStyles.label),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Text(
              (data['cover_letter'] as String?)?.isNotEmpty == true ? data['cover_letter'] as String : l10n.hrNoCoverLetterProvided,
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
          ),
          if (skills.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l10n.hrSkills, style: AppTextStyles.label),
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
          const SizedBox(height: 24),
          if (_isBusy)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (isNew) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reject,
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: BorderSide(color: AppColors.error)),
                    child: Text(l10n.hrReject, style: TextStyle(color: AppColors.error)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showScheduleInterviewSheet,
                    icon: const Icon(Icons.videocam_outlined, size: 16),
                    label: Text(l10n.hrScheduleInterview),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ],
            ),
          ] else if (isInterview) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.videocam_outlined, size: 18, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(l10n.hrInterviewScheduledColon('${DateTime.parse(data['interview_at'] as String).toLocal()}'.split('.').first),
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.warning)),
                      ),
                    ],
                  ),
                  if (data['interview_location'] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${data['interview_mode'] == 'online' ? l10n.hrMeetingLink : l10n.hrLocation}: ${data['interview_location']}',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.warning),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reject,
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: BorderSide(color: AppColors.error)),
                    child: Text(l10n.hrReject, style: TextStyle(color: AppColors.error)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _accept,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: Text(l10n.hrAccept),
                  ),
                ),
              ],
            ),
          ] else if (isActive) ...[
            Text(l10n.hrOfferLetterSectionTitle, style: AppTextStyles.label),
            const SizedBox(height: 8),
            if (_isLoadingOfferLetter)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else if (_offerLetterDoc != null)
              GestureDetector(
                onTap: _viewOfferLetter,
                child: AccentCard(
                  accentColor: AppColors.success,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.picture_as_pdf_outlined, size: 20, color: AppColors.success),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_offerLetterDoc!['file_name'] as String,
                                style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(formatFileSize(parseNum(_offerLetterDoc!['file_size_bytes'])?.toInt() ?? 0), style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(onPressed: _uploadOfferLetter, child: Text(l10n.hrReplaceOfferLetter)),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _uploadOfferLetter,
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: Text(l10n.hrUploadOfferLetter),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            const SizedBox(height: 20),
            Text(l10n.docTypeCompanyAcceptanceLetter, style: AppTextStyles.label),
            const SizedBox(height: 8),
            if (_isLoadingAcceptanceLetter)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else if (_acceptanceLetterDoc != null)
              GestureDetector(
                onTap: _viewAcceptanceLetter,
                child: AccentCard(
                  accentColor: AppColors.success,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.picture_as_pdf_outlined, size: 20, color: AppColors.success),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_acceptanceLetterDoc!['file_name'] as String,
                                style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(formatFileSize(parseNum(_acceptanceLetterDoc!['file_size_bytes'])?.toInt() ?? 0), style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _fillAcceptanceLetter,
                  icon: const Icon(Icons.edit_document, size: 16),
                  label: Text(l10n.docFillAndSignAction),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ScheduleInterviewSheet extends StatefulWidget {
  final void Function(DateTime dateTime, String mode, String? location) onScheduled;

  const _ScheduleInterviewSheet({required this.onScheduled});

  @override
  State<_ScheduleInterviewSheet> createState() => _ScheduleInterviewSheetState();
}

class _ScheduleInterviewSheetState extends State<_ScheduleInterviewSheet> {
  DateTime? _date;
  TimeOfDay? _time;
  String _mode = 'online';
  final _locationController = TextEditingController();
  String? _error;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<PickedAddress>(context, MaterialPageRoute(builder: (_) => const AddressPickerScreen()));
    if (result != null) {
      setState(() {
        _locationController.text = result.addressText;
        _error = null;
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
              Text(l10n.hrScheduleInterview, style: AppTextStyles.h3),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.hrDate, style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextFormField(
            readOnly: true,
            controller: TextEditingController(text: _date == null ? '' : '${_date!.day}/${_date!.month}/${_date!.year}'),
            decoration: InputDecoration(hintText: l10n.hrSelectDate, suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18)),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          Text(l10n.hrTime, style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextFormField(
            readOnly: true,
            controller: TextEditingController(text: _time == null ? '' : _time!.format(context)),
            decoration: InputDecoration(hintText: l10n.hrSelectTime, suffixIcon: const Icon(Icons.access_time, size: 18)),
            onTap: _pickTime,
          ),
          const SizedBox(height: 12),
          Text(l10n.hrInterviewMode, style: AppTextStyles.label),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ModeOption(
                  label: l10n.hrOnline,
                  icon: Icons.videocam_outlined,
                  selected: _mode == 'online',
                  onTap: () => setState(() => _mode = 'online'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ModeOption(
                  label: l10n.hrInPerson,
                  icon: Icons.business_outlined,
                  selected: _mode == 'in_person',
                  onTap: () => setState(() => _mode = 'in_person'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _locationController,
            readOnly: _mode == 'in_person',
            onTap: _mode == 'in_person' ? _pickLocation : null,
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              labelText: _mode == 'online' ? l10n.hrMeetingLink : l10n.hrLocation,
              hintText: _mode == 'online' ? l10n.hrMeetingLinkHint : l10n.hrLocationTapToSelect,
              suffixIcon: _mode == 'in_person' ? const Icon(Icons.location_on_outlined, size: 18) : null,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_date == null || _time == null)
                  ? null
                  : () {
                      if (_locationController.text.trim().isEmpty) {
                        setState(() => _error = _mode == 'online' ? l10n.hrMeetingLinkRequired : l10n.hrLocationRequired);
                        return;
                      }
                      final dateTime = DateTime(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
                      widget.onScheduled(dateTime, _mode, _locationController.text.trim());
                    },
              child: Text(l10n.hrConfirmNotifyApplicant),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeOption({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.infoBg : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.primary : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
