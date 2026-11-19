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
import '../../utils/error_text.dart';
import '../../utils/letter_auto_values.dart';
import '../../utils/lang.dart';
import '../../widgets/reason_dialog.dart';
import '../../widgets/interview_slot_picker.dart';
import '../../services/auth_service.dart';
import '../../services/interview_service.dart';
import '../../utils/interview_format.dart';
import '../../utils/validators.dart';
import '../../widgets/common/validated_field.dart';
import 'hr_availability_screen.dart';
import 'applicant_profile_screen.dart';
import '../../utils/calendar_link.dart';
import '../../widgets/reschedule_request_card.dart';

class HrApplicantsScreen extends StatefulWidget {
  const HrApplicantsScreen({super.key});

  @override
  State<HrApplicantsScreen> createState() => _HrApplicantsScreenState();
}

class _HrApplicantsScreenState extends State<HrApplicantsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _applicants = [];
  String _query = '';
  String? _posting; // null = every posting
  bool _shortlistedOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
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

  bool get _filtersActive => _query.trim().isNotEmpty || _posting != null || _shortlistedOnly;

  /// Applicants that match the search box, the posting and the shortlist filter.
  List<Map<String, dynamic>> get _visible {
    final q = _query.trim().toLowerCase();
    return _applicants.where((a) {
      if (_posting != null && a['internship_title'] != _posting) return false;
      if (_shortlistedOnly && a['shortlisted'] != true) return false;
      if (q.isEmpty) return true;
      final haystack = [
        a['student_name'],
        a['programme'],
        a['student_reg_no'],
        a['internship_title'],
        ...List<String>.from(a['skills'] as List? ?? const []),
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> _filtered(String status) => _visible.where((a) => a['status'] == status).toList();

  Widget _buildFilters(AppLocalizations l10n) {
    final postings = _applicants.map((a) => a['internship_title']).whereType<String>().toSet().toList()..sort();
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.hrSearchApplicants,
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _query = '')),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: postings.contains(_posting) ? _posting : null,
                    isExpanded: true,
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textPrimary),
                    dropdownColor: AppColors.surface,
                    onChanged: (v) => setState(() => _posting = v),
                    items: [
                      DropdownMenuItem<String?>(value: null, child: Text(l10n.hrAllPostings, overflow: TextOverflow.ellipsis)),
                      for (final t in postings) DropdownMenuItem<String?>(value: t, child: Text(t, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                avatar: Icon(_shortlistedOnly ? Icons.star : Icons.star_border, size: 16, color: _shortlistedOnly ? AppColors.textPrimary : AppColors.textSecondary),
                label: Text(l10n.hrShortlisted),
                selected: _shortlistedOnly,
                onSelected: (v) => setState(() => _shortlistedOnly = v),
                labelStyle: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final newCount = _filtered('pending').length;
    final interviewCount = _filtered('interview').length;
    final offeredCount = _filtered('offered').length;
    final acceptedCount = _filtered('active').length;
    final rejectedCount = _filtered('rejected').length;
    final closedCount = _filtered('unavailable').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: l10n.hrApplicants),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                _buildFilters(l10n),
                Container(
                  color: AppColors.surface,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: AppColors.primaryText,
                    unselectedLabelColor: AppColors.textMuted,
                    indicatorColor: AppColors.primary,
                    labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
                    tabs: [
                      Tab(text: l10n.hrTabNew(newCount)),
                      Tab(text: l10n.hrTabInterview(interviewCount)),
                      Tab(text: l10n.hrTabOffered(offeredCount)),
                      Tab(text: l10n.hrTabAccepted(acceptedCount)),
                      Tab(text: l10n.hrTabRejected(rejectedCount)),
                      Tab(text: l10n.hrTabClosed(closedCount)),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: ['pending', 'interview', 'offered', 'active', 'rejected', 'unavailable'].map((status) {
                      final items = _filtered(status);
                      if (items.isEmpty) {
                        return _filtersActive
                            ? EmptyState(icon: Icons.search_off, title: l10n.hrNoMatchingApplicants, description: '')
                            : EmptyState(icon: Icons.people_outline, title: l10n.hrNoApplicantsHere, description: l10n.hrApplicantsAppearHere);
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
      case 'offered':
        return AppColors.info;
      case 'unavailable':
        return AppColors.textMuted;
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
              ProfileAvatar(name: name, avatarUrl: data['avatar_url'] as String?, radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(name, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                        if (data['shortlisted'] == true) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.star, size: 15, color: AppColors.warning),
                        ],
                      ],
                    ),
                    Text('${data['programme'] ?? l10n.notSpecified} · ${data['internship_title'] ?? ''}', style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          if ((data['interview'] as InterviewInfo?) != null && (data['interview'] as InterviewInfo).status != 'completed') ...[
            const SizedBox(height: 10),
            Builder(builder: (_) {
              final iv = data['interview'] as InterviewInfo;
              final cancelled = iv.isCancelled;
              final color = cancelled ? AppColors.error : AppColors.warning;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(color: cancelled ? AppColors.errorBg : AppColors.warningBg, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(cancelled ? Icons.event_busy_outlined : Icons.videocam_outlined, size: 15, color: color),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                          cancelled ? AppLocalizations.of(context)!.hrvInterviewCancelledWas(formatInterviewDateTime(iv.start)) : AppLocalizations.of(context)!.hrvInterviewLine(formatInterviewDateTime(iv.start)),
                          style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: color)),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (data['status'] == 'rejected' && (data['rejection_reason'] as String?) != null) ...[
            const SizedBox(height: 8),
            Text('Reason: ${data['rejection_reason']}',
                maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
          ],
          if (data['status'] == 'unavailable') ...[
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.hrvAcceptedAnother, style: AppTextStyles.caption),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Flexible(child: Text(l10n.hrAppliedAgo(timeAgo(context, DateTime.parse(data['applied_at'] as String))), style: AppTextStyles.caption, overflow: TextOverflow.ellipsis)),
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
  // The company supervisor of an intern who accepted (assigned by this HR, or automatically when there is only one).
  List<Map<String, dynamic>> _supervisors = [];
  String? _supervisorId;
  bool _isLoadingSupervisors = false;
  bool _isAssigning = false;
  // The letter that came with the offer (stored on the application until the student accepts it).
  String? _offerPath;
  String? _offerName;
  int? _offerSize;

  @override
  void initState() {
    super.initState();
    _offerPath = widget.data['offer_letter_path'] as String?;
    _offerName = widget.data['offer_letter_name'] as String?;
    _offerSize = parseNum(widget.data['offer_letter_size'])?.toInt();
    _refreshInterview();
    _supervisorId = widget.data['company_supervisor_id'] as String?;
    if (widget.data['status'] == 'active') {
      _loadOfferLetter();
      _loadAcceptanceLetter();
      _loadSupervisors();
    }
  }

  Future<void> _loadSupervisors() async {
    setState(() => _isLoadingSupervisors = true);
    try {
      final list = await HrDataService.instance.getCompanySupervisors();
      if (!mounted) return;
      setState(() {
        _supervisors = list;
        // one supervisor: the database has already assigned the intern to them
        if (_supervisorId == null && list.length == 1) _supervisorId = list.first['profile_id'] as String?;
        _isLoadingSupervisors = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingSupervisors = false);
    }
  }

  Future<void> _assignSupervisor(String supervisorId) async {
    final before = _supervisorId;
    setState(() {
      _isAssigning = true;
      _supervisorId = supervisorId;
    });
    try {
      await HrDataService.instance.assignCompanySupervisor(applicationId: widget.data['id'] as String, supervisorId: supervisorId);
      if (!mounted) return;
      setState(() => _isAssigning = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('Company supervisor assigned.', ms: 'Penyelia syarikat ditugaskan.', zh: '已分配公司督导。')),
          backgroundColor: AppColors.primary));
      _loadSupervisors();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAssigning = false;
        _supervisorId = before;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.error));
    }
  }

  /// Who supervises this intern at the company. One supervisor: automatic. Several: HR chooses.
  Widget _buildSupervisorSection() {
    String nameOf(Map<String, dynamic> s) {
      final n = (s['full_name'] as String?)?.trim();
      return (n != null && n.isNotEmpty) ? n : (s['email'] as String? ?? '');
    }

    final label = Text(tr('Company supervisor', ms: 'Penyelia syarikat', zh: '公司督导'), style: AppTextStyles.label);
    Widget body;
    if (_isLoadingSupervisors) {
      body = Center(child: CircularProgressIndicator(color: AppColors.primary));
    } else if (_supervisors.isEmpty) {
      body = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(10)),
        child: Text(
            tr('Your company has no approved company supervisor yet. This student is assigned automatically as soon as one is approved.',
                ms: 'Syarikat anda belum mempunyai penyelia syarikat yang diluluskan. Pelajar ini ditugaskan secara automatik sebaik sahaja seorang diluluskan.',
                zh: '贵公司尚无已批准的公司督导。一旦有督导获批，该学生将自动分配给他。'),
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.warning)),
      );
    } else if (_supervisors.length == 1) {
      body = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(Icons.verified_user_outlined, size: 18, color: AppColors.info),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  tr('Assigned automatically to ${nameOf(_supervisors.first)}, the only company supervisor.',
                      ms: 'Ditugaskan secara automatik kepada ${nameOf(_supervisors.first)}, satu-satunya penyelia syarikat.',
                      zh: '已自动分配给${nameOf(_supervisors.first)}（唯一的公司督导）。'),
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.info)),
            ),
          ],
        ),
      );
    } else {
      final selected = _supervisors.any((s) => s['profile_id'] == _supervisorId) ? _supervisorId : null;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: selected,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: tr('Choose a company supervisor', ms: 'Pilih penyelia syarikat', zh: '选择公司督导'),
            ),
            items: [
              for (final s in _supervisors)
                DropdownMenuItem(
                  value: s['profile_id'] as String,
                  child: Text('${nameOf(s)} (${s['interns']})', overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _isAssigning ? null : (v) {
              if (v != null && v != _supervisorId) _assignSupervisor(v);
            },
          ),
          const SizedBox(height: 6),
          Text(
              selected == null
                  ? tr('Nobody is responsible for this intern yet: choose a company supervisor so reports can be reviewed and the evaluation done.',
                      ms: 'Belum ada yang bertanggungjawab ke atas pelatih ini: pilih penyelia syarikat supaya laporan boleh disemak dan penilaian dibuat.',
                      zh: '目前没有人负责该实习生：请选择公司督导，以便审阅报告并完成评估。')
                  : tr('The number is how many interns each supervisor has. You can change this until the intern has been evaluated.',
                      ms: 'Nombor ialah bilangan pelatih setiap penyelia. Anda boleh menukarnya sehingga pelatih dinilai.',
                      zh: '括号内为每位督导的实习生人数。在实习生被评估之前，您可以更改。'),
              style: AppTextStyles.caption),
        ],
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [label, const SizedBox(height: 8), body, const SizedBox(height: 20)]);
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
          loadAutoValues: () async {
            // what the application list already holds, then everything the profile and the internship can add
            final values = <String, String>{
              'student_name': widget.data['student_name'] as String? ?? '',
              'student_reg_no': widget.data['student_reg_no'] as String? ?? '',
              'programme': widget.data['programme'] as String? ?? '',
              'company_name': widget.data['company_name'] as String? ?? '',
              'job_title': widget.data['internship_title'] as String? ?? '',
              'today_date': _formatToday(),
            };
            try {
              final context = await HrDataService.instance.getLetterContext(widget.data['id'] as String);
              values.addAll(letterValuesFromContext(context));
            } catch (_) {
              // Non-fatal: the form just starts with fewer fields filled in.
            }
            return values;
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.hrvCouldNotUploadOffer(friendlyError(e))), backgroundColor: AppColors.error));
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

  Future<void> _reject({bool withdrawingOffer = false}) async {
    final name = widget.data['student_name'] as String;
    final reason = await showReasonDialog(
      context,
      title: withdrawingOffer ? AppLocalizations.of(context)!.hrvWithdrawOffer : AppLocalizations.of(context)!.hrvRejectApplication,
      prompt: withdrawingOffer ? AppLocalizations.of(context)!.hrvWithdrawPrompt(name) : AppLocalizations.of(context)!.hrvRejectPrompt(name),
      confirmLabel: withdrawingOffer ? AppLocalizations.of(context)!.hrvWithdrawOffer : AppLocalizations.of(context)!.hrvReject,
      hintText: AppLocalizations.of(context)!.hrvRejectHint,
      destructive: true,
    );
    if (reason == null || !mounted) return;

    setState(() => _isBusy = true);
    try {
      await HrDataService.instance.updateApplicationStatus(
        applicationId: widget.data['id'] as String,
        studentId: widget.data['student_id'] as String,
        status: 'rejected',
        rejectionReason: reason,
        internshipTitle: widget.data['internship_title'] as String?,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.hrvCouldNotReject(friendlyError(e))), backgroundColor: AppColors.error));
    }
  }

  /// The offer letter that goes with the offer (required; PDF, Word or a photo of the signed letter, 10 MB at most).
  Future<PlatformFile?> _pickOfferLetter() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'docx', 'jpg', 'jpeg', 'png'], withData: true);
    if (result == null || result.files.isEmpty) return null;
    final picked = result.files.single;
    if (picked.size > 10 * 1024 * 1024) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorFileTooLarge10mb), backgroundColor: AppColors.error));
      return null;
    }
    return picked;
  }

  Future<void> _makeOffer() async {
    final name = widget.data['student_name'] as String;
    final l10n = AppLocalizations.of(context)!;
    PlatformFile? letter;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(l10n.hrvMakeOfferTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.hrvMakeOfferBody(name)),
              const SizedBox(height: 16),
              Text(tr('Offer letter (required)', ms: 'Surat tawaran (wajib)', zh: '录取信（必填）'), style: AppTextStyles.label),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await _pickOfferLetter();
                    if (picked != null) setLocal(() => letter = picked);
                  },
                  icon: Icon(letter == null ? Icons.attach_file : Icons.check_circle_outline, size: 18),
                  label: Text(letter?.name ?? tr('Choose the offer letter', ms: 'Pilih surat tawaran', zh: '选择录取信'), overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(height: 6),
              Text(tr('The student sees this letter before accepting. PDF, Word, JPG or PNG, up to 10 MB.',
                  ms: 'Pelajar melihat surat ini sebelum menerima. PDF, Word, JPG atau PNG, sehingga 10 MB.',
                  zh: '学生在接受前会看到这封信。支持 PDF、Word、JPG 或 PNG，最大 10 MB。'), style: AppTextStyles.caption),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            TextButton(onPressed: letter == null ? null : () => Navigator.pop(ctx, true), child: Text(l10n.hrvMakeOffer)),
          ],
        ),
      ),
    );
    if (confirmed != true || letter == null || !mounted) return;

    setState(() => _isBusy = true);
    String? uploadedPath;
    try {
      final file = await resolvePickedFile(letter!);
      uploadedPath = await HrDataService.instance.uploadApplicationOfferLetter(
        applicationId: widget.data['id'] as String,
        studentId: widget.data['student_id'] as String,
        file: file,
        fileName: letter!.name,
      );
      await HrDataService.instance.updateApplicationStatus(
        applicationId: widget.data['id'] as String,
        studentId: widget.data['student_id'] as String,
        status: 'offered',
        internshipTitle: widget.data['internship_title'] as String?,
        offerLetterPath: uploadedPath,
        offerLetterName: letter!.name,
        offerLetterSize: letter!.size,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      await HrDataService.instance.removeStoredFile(uploadedPath); // the offer failed: do not keep the letter
      if (!mounted) return;
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.hrvCouldNotMakeOffer(friendlyError(e))), backgroundColor: AppColors.error));
    }
  }

  /// Opens the letter that came with the offer (before the student accepts it).
  Future<void> _viewOfferLetterOfOffer() async {
    final path = _offerPath;
    if (path == null) return;
    try {
      final url = await HrDataService.instance.getOfferLetterSignedUrl(path);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentPreviewScreen(url: url, fileName: _offerName ?? path.split('/').last)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.hrvCouldNotUploadOffer(friendlyError(e))), backgroundColor: AppColors.error));
    }
  }

  /// Attaches or replaces the letter of an offer already sent (until the student accepts it).
  Future<void> _replaceOfferLetterOfOffer() async {
    final picked = await _pickOfferLetter();
    if (picked == null || !mounted) return;
    setState(() => _isBusy = true);
    String? uploadedPath;
    try {
      final file = await resolvePickedFile(picked);
      uploadedPath = await HrDataService.instance.uploadApplicationOfferLetter(
        applicationId: widget.data['id'] as String,
        studentId: widget.data['student_id'] as String,
        file: file,
        fileName: picked.name,
      );
      await HrDataService.instance.setApplicationOfferLetter(
        applicationId: widget.data['id'] as String,
        path: uploadedPath,
        fileName: picked.name,
        fileSizeBytes: picked.size,
      );
      final old = _offerPath;
      setState(() {
        _offerPath = uploadedPath;
        _offerName = picked.name;
        _offerSize = picked.size;
        _isBusy = false;
      });
      await HrDataService.instance.removeStoredFile(old);
    } catch (e) {
      await HrDataService.instance.removeStoredFile(uploadedPath);
      if (!mounted) return;
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.hrvCouldNotUploadOffer(friendlyError(e))), backgroundColor: AppColors.error));
    }
  }

  Future<void> _viewResume() async {
    final path = widget.data['resume_path'] as String?;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.hrvNoResumeUploaded), backgroundColor: AppColors.warning));
      return;
    }
    try {
      final url = await HrDataService.instance.getResumeSignedUrl(path);
      if (!mounted) return;
      final fileName = (widget.data['resume_filename'] as String?) ?? path.split('/').last;
      Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentPreviewScreen(url: url, fileName: fileName)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.apCouldNotOpenResume(friendlyError(e))), backgroundColor: AppColors.error));
    }
  }

  Future<void> _addToCalendar(InterviewInfo iv) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await addInterviewToCalendar(
      title: l10n.calendarEventTitle('${widget.data['student_name']} - ${widget.data['internship_title'] ?? ''}'),
      start: iv.start,
      end: iv.end,
      location: iv.location,
      details: l10n.calendarEventDetails('${widget.data['company_name'] ?? 'CIMS'}'),
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.calendarCouldNotOpen), backgroundColor: AppColors.error));
    }
  }

  void _openProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ApplicantProfileScreen(applicant: widget.data)));
  }

  InterviewInfo? _fresh;

  InterviewInfo? get _interview => _fresh ?? widget.data['interview'] as InterviewInfo?;

  /// The copy handed to this screen may be old (for example the student has
  /// since declined a request), so load the current state.
  Future<void> _refreshInterview() async {
    final id = (widget.data['interview'] as InterviewInfo?)?.id;
    if (id == null) return;
    try {
      final latest = await InterviewService.instance.fetch(id);
      if (!mounted || latest == null) return;
      setState(() => _fresh = latest);
    } catch (_) {
      // Keep showing the copy we were given.
    }
  }

  Future<void> _showScheduleInterviewSheet() async {
    final booked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _ScheduleInterviewSheet(
        onSubmit: (slot, mode, location) => InterviewService.instance.book(
          applicationId: widget.data['id'] as String,
          start: slot.start,
          mode: mode,
          location: location,
        ),
      ),
    );
    if (booked == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Interview booked. ${widget.data['student_name']} has been notified.'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context); // back to the list, which refreshes
    }
  }

  Future<void> _rescheduleInterview() async {
    final iv = _interview!;
    final done = await showRescheduleSheet(
      context,
      otherParty: widget.data['student_name'] as String,
      loadSlots: (from, to) => InterviewService.instance.freeSlots(AuthService.instance.currentUserId!, from, to),
      emptyAction: TextButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HrAvailabilityScreen())),
        child: Text(AppLocalizations.of(context)!.hrvSetMyAvailability),
      ),
      onSubmit: (slot, reason) => InterviewService.instance.requestReschedule(interviewId: iv.id, newStart: slot.start, reason: reason),
    );
    if (done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request sent to ${widget.data['student_name']}. The interview moves only if they accept.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _answerRequest(RescheduleRequest request, {required bool accept}) async {
    String? note;
    if (!accept) {
      note = await showReasonDialog(
        context,
        title: AppLocalizations.of(context)!.ivDeclineNewTimeTitle,
        prompt: AppLocalizations.of(context)!.hrvDeclinePrompt('${widget.data['student_name']}'),
        confirmLabel: AppLocalizations.of(context)!.ivDecline,
        hintText: AppLocalizations.of(context)!.hrvDeclineHint,
        destructive: true,
      );
      if (note == null || !mounted) return;
    }
    setState(() => _isBusy = true);
    try {
      await InterviewService.instance.respondToReschedule(requestId: request.id, accept: accept, note: note);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accept ? AppLocalizations.of(context)!.hrvAcceptedMoved : AppLocalizations.of(context)!.ivDeclinedStays), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.error));
    }
  }

  Future<void> _withdrawRequest(RescheduleRequest request) async {
    setState(() => _isBusy = true);
    try {
      await InterviewService.instance.withdrawRescheduleRequest(request.id);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.error));
    }
  }

  Future<void> _cancelInterview() async {
    final iv = _interview!;
    final name = widget.data['student_name'] as String;
    final reason = await showReasonDialog(
      context,
      title: AppLocalizations.of(context)!.ivCancelInterview,
      prompt: AppLocalizations.of(context)!.hrvCancelPrompt(name, formatInterviewDateTime(iv.start)),
      confirmLabel: AppLocalizations.of(context)!.ivCancelInterview,
      hintText: AppLocalizations.of(context)!.hrvCancelHint,
      destructive: true,
    );
    if (reason == null || !mounted) return;
    setState(() => _isBusy = true);
    try {
      await InterviewService.instance.cancel(interviewId: iv.id, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.hrvCancelledNotified(name)), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.ivCouldNotCancel(friendlyError(e))), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = widget.data;
    final name = data['student_name'] as String;
    final isNew = data['status'] == 'pending';
    final isInterview = data['status'] == 'interview';
    final isOffered = data['status'] == 'offered';
    final isActive = data['status'] == 'active';
    final isRejected = data['status'] == 'rejected';
    final isClosed = data['status'] == 'unavailable';
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
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _openProfile,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    ProfileAvatar(name: name, avatarUrl: data['avatar_url'] as String?, radius: 38),
                    const SizedBox(height: 10),
                    Text(name, style: AppTextStyles.h2, textAlign: TextAlign.center),
                    Text((data['programme'] as String?) ?? l10n.notSpecified, style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_search_outlined, size: 16, color: AppColors.primaryText),
                        const SizedBox(width: 4),
                        Text('View full profile', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
                      ],
                    ),
                  ],
                ),
              ),
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
                Icon(Icons.work_outline, size: 18, color: AppColors.primaryText),
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
                Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.primaryText),
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
                        child: Text(s, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.primaryText)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          _PrivateNotesCard(
            applicationId: data['id'] as String,
            initialShortlisted: data['shortlisted'] == true,
            initialNote: data['hr_note'] as String?,
          ),
          const SizedBox(height: 24),
          if (_isBusy)
            Center(child: CircularProgressIndicator(color: AppColors.primary))
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
            if (_interview != null && _interview!.isScheduled) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_interview!.mode == 'online' ? Icons.videocam_outlined : Icons.business_outlined, size: 18, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(formatInterviewDateTime(_interview!.start),
                              style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.warning)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${formatInterviewTime(_interview!.start)} – ${formatInterviewTime(_interview!.end)} (${_interview!.end.difference(_interview!.start).inMinutes} min)',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.warning)),
                    if (_interview!.location != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${_interview!.mode == 'online' ? l10n.hrMeetingLink : l10n.hrLocation}: ${_interview!.location}',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.warning),
                      ),
                    ],
                    if (_interview!.lastReasonedChange != null) ...[
                      const SizedBox(height: 8),
                      _ChangeNote(change: _interview!.lastReasonedChange!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _addToCalendar(_interview!),
                  icon: const Icon(Icons.event_available_outlined, size: 18),
                  label: Text(l10n.addToCalendar),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
              const SizedBox(height: 10),
              if (_interview!.pendingRequest != null) ...[
                RescheduleRequestCard(
                  request: _interview!.pendingRequest!,
                  requestedByMe: _interview!.pendingRequest!.requestedBy == AuthService.instance.currentUserId,
                  otherParty: widget.data['student_name'] as String,
                  currentStart: _interview!.start,
                  busy: _isBusy,
                  onAccept: () => _answerRequest(_interview!.pendingRequest!, accept: true),
                  onDecline: () => _answerRequest(_interview!.pendingRequest!, accept: false),
                  onWithdraw: () => _withdrawRequest(_interview!.pendingRequest!),
                ),
                const SizedBox(height: 10),
              ],
              if (_interview!.canBeChanged)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _cancelInterview,
                        icon: Icon(Icons.event_busy_outlined, size: 16, color: AppColors.error),
                        label: Text(l10n.cancel, style: TextStyle(color: AppColors.error)),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: BorderSide(color: AppColors.error)),
                      ),
                    ),
                    if (_interview!.pendingRequest == null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _rescheduleInterview,
                          icon: const Icon(Icons.edit_calendar_outlined, size: 16),
                          label: Text(l10n.ivRescheduleButton),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                    ],
                  ],
                )
              else
                Text(l10n.hrvChangeWindow, style: AppTextStyles.caption),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.event_busy_outlined, size: 18, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                              _interview == null ? l10n.hrvNoInterviewBooked : l10n.hrvInterviewWasCancelled(formatInterviewDateTime(_interview!.start)),
                              style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.error)),
                        ),
                      ],
                    ),
                    if (_interview?.lastReasonedChange != null) ...[
                      const SizedBox(height: 8),
                      _ChangeNote(change: _interview!.lastReasonedChange!, onError: true),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showScheduleInterviewSheet,
                  icon: const Icon(Icons.event_available_outlined, size: 16),
                  label: Text(l10n.hrvScheduleNew),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ],
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
                    onPressed: _makeOffer,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: Text(l10n.hrvMakeOffer),
                  ),
                ),
              ],
            ),
          ] else if (isOffered) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(10)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.hourglass_top_outlined, size: 18, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l10n.hrvOfferSent(name),
                        style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.info)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.hrOfferLetterSectionTitle, style: AppTextStyles.label),
            const SizedBox(height: 8),
            if (_offerPath != null)
              GestureDetector(
                onTap: _viewOfferLetterOfOffer,
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
                            Text(_offerName ?? _offerPath!.split('/').last,
                                style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(formatFileSize(_offerSize ?? 0), style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(onPressed: _isBusy ? null : _replaceOfferLetterOfOffer, child: Text(l10n.hrReplaceOfferLetter)),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isBusy ? null : _replaceOfferLetterOfOffer,
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: Text(l10n.hrUploadOfferLetter),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _reject(withdrawingOffer: true),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: BorderSide(color: AppColors.error)),
                child: Text(l10n.hrvWithdrawOffer, style: TextStyle(color: AppColors.error)),
              ),
            ),
          ] else if (isRejected) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reason given to the student', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error)),
                  const SizedBox(height: 4),
                  Text((data['rejection_reason'] as String?) ?? 'No reason was recorded.',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.error)),
                ],
              ),
            ),
          ] else if (isClosed) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
              child: Text(l10n.hrvAcceptedAnotherCompany(name),
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
            ),
          ] else if (isActive) ...[
            _buildSupervisorSection(),
            Text(l10n.hrOfferLetterSectionTitle, style: AppTextStyles.label),
            const SizedBox(height: 8),
            if (_isLoadingOfferLetter)
              Center(child: CircularProgressIndicator(color: AppColors.primary))
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
              Center(child: CircularProgressIndicator(color: AppColors.primary))
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

class _ChangeNote extends StatelessWidget {
  final InterviewChange change;
  final bool onError;

  const _ChangeNote({required this.change, this.onError = false});

  @override
  Widget build(BuildContext context) {
    final color = onError ? AppColors.error : AppColors.warning;
    final l10n = AppLocalizations.of(context)!;
    final actor = change.actorRole == 'student'
        ? l10n.ivTheStudent
        : (change.actorRole == null ? l10n.ivTheSystem : l10n.ivTheCompany);
    final verb = switch (change.action) {
      'reschedule_requested' => l10n.ivVerbAsked,
      'reschedule_declined' => l10n.ivVerbDeclined,
      'rescheduled' => l10n.ivVerbMoved,
      'auto_cancelled' => l10n.ivVerbAutoCancelled,
      'cancelled' => l10n.ivVerbCancelled,
      _ => l10n.ivVerbBooked,
    };
    return Text(l10n.hrvChangeNote(actor, verb, '${change.reason}'),
        style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontStyle: FontStyle.italic, color: color));
  }
}

class _ScheduleInterviewSheet extends StatefulWidget {
  final Future<void> Function(InterviewSlot slot, String mode, String location) onSubmit;

  const _ScheduleInterviewSheet({required this.onSubmit});

  @override
  State<_ScheduleInterviewSheet> createState() => _ScheduleInterviewSheetState();
}

class _ScheduleInterviewSheetState extends State<_ScheduleInterviewSheet> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  InterviewSlot? _slot;
  String _mode = 'online';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<PickedAddress>(context, MaterialPageRoute(builder: (_) => const AddressPickerScreen()));
    if (result != null) {
      setState(() {
        _locationController.text = result.addressText;
        _error = null;
      });
      _formKey.currentState?.validate();
    }
  }

  Future<void> _submit() async {
    if (_slot == null) {
      setState(() => _error = AppLocalizations.of(context)!.hrvPickDayTime);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_slot!, _mode, _locationController.text.trim());
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = friendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(child: Text(l10n.hrScheduleInterview, style: AppTextStyles.h3, overflow: TextOverflow.ellipsis)),
                IconButton(icon: const Icon(Icons.close, size: 20), onPressed: _busy ? null : () => Navigator.pop(context, false)),
              ],
            ),
            const SizedBox(height: 12),
            InterviewSlotPicker(
              loadSlots: (from, to) => InterviewService.instance.freeSlots(AuthService.instance.currentUserId!, from, to),
              onChanged: (s) => setState(() {
                _slot = s;
                _error = null;
              }),
              emptyAction: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HrAvailabilityScreen())),
                child: Text(AppLocalizations.of(context)!.hrvSetMyAvailability),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.hrInterviewMode, style: AppTextStyles.label),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ModeOption(
                    label: l10n.hrOnline,
                    icon: Icons.videocam_outlined,
                    selected: _mode == 'online',
                    onTap: () => setState(() {
                      _mode = 'online';
                      _locationController.clear();
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeOption(
                    label: l10n.hrInPerson,
                    icon: Icons.business_outlined,
                    selected: _mode == 'in_person',
                    onTap: () => setState(() {
                      _mode = 'in_person';
                      _locationController.clear();
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: ValidatedField(
                // A new field per mode so a stale error from the other mode never lingers.
                key: ValueKey(_mode),
                controller: _locationController,
                readOnly: _mode == 'in_person',
                onTap: _mode == 'in_person' ? _pickLocation : null,
                fieldValidator: (v) => _mode == 'online'
                    ? Validators.url(v, required: true)
                    : Validators.text(v, field: 'The location', min: 5, max: 300),
                labelText: _mode == 'online' ? l10n.hrMeetingLink : l10n.hrLocation,
                hintText: _mode == 'online' ? l10n.hrMeetingLinkHint : l10n.hrLocationTapToSelect,
                keyboardType: _mode == 'online' ? TextInputType.url : TextInputType.text,
                suffix: _mode == 'in_person' ? const Icon(Icons.location_on_outlined, size: 18) : null,
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
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(l10n.hrConfirmNotifyApplicant),
              ),
            ),
          ],
        ),
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


/// HR's own shortlist star and note on one applicant. Saved straight to the
/// database; the student and other roles can never read it.
class _PrivateNotesCard extends StatefulWidget {
  final String applicationId;
  final bool initialShortlisted;
  final String? initialNote;

  const _PrivateNotesCard({required this.applicationId, required this.initialShortlisted, required this.initialNote});

  @override
  State<_PrivateNotesCard> createState() => _PrivateNotesCardState();
}

class _PrivateNotesCardState extends State<_PrivateNotesCard> {
  late bool _shortlisted = widget.initialShortlisted;
  late final TextEditingController _note = TextEditingController(text: widget.initialNote ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _toggleShortlist() async {
    final next = !_shortlisted;
    setState(() => _shortlisted = next);
    try {
      await HrDataService.instance.setShortlisted(widget.applicationId, next);
    } catch (e) {
      if (!mounted) return;
      setState(() => _shortlisted = !next);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.error));
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      await HrDataService.instance.saveApplicantNote(widget.applicationId, _note.text);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.hrNoteSaved), backgroundColor: AppColors.success));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(l10n.hrPrivateNotes, style: AppTextStyles.label)),
              TextButton.icon(
                onPressed: _toggleShortlist,
                icon: Icon(_shortlisted ? Icons.star : Icons.star_border, size: 18, color: _shortlisted ? AppColors.warning : AppColors.textSecondary),
                label: Text(_shortlisted ? l10n.hrRemoveShortlist : l10n.hrShortlist,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.primaryText)),
              ),
            ],
          ),
          Text(l10n.hrPrivateNotesInfo, style: AppTextStyles.caption),
          const SizedBox(height: 8),
          TextField(
            controller: _note,
            minLines: 3,
            maxLines: 6,
            maxLength: 2000,
            decoration: InputDecoration(hintText: l10n.hrNoteHint),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(l10n.hrSaveNote),
            ),
          ),
        ],
      ),
    );
  }
}
