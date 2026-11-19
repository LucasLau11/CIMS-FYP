import 'package:flutter/material.dart';
import '../../utils/validators.dart';
import '../../widgets/common/validated_field.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/hr_data_service.dart';
import '../../utils/format_utils.dart';
import '../student/address_picker_screen.dart';
import 'hr_recommended_candidates_screen.dart';
import '../../utils/error_text.dart';
import '../../services/company_service.dart';
import 'hr_company_verification_screen.dart';
import '../../utils/lang.dart';

const List<String> _kJobTypes = ['On-site', 'Remote', 'Hybrid'];

class HrPostingsScreen extends StatefulWidget {
  const HrPostingsScreen({super.key});

  @override
  State<HrPostingsScreen> createState() => _HrPostingsScreenState();
}

class _HrPostingsScreenState extends State<HrPostingsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _postings = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final postings = await HrDataService.instance.getPostings();
      if (!mounted) return;
      setState(() {
        _postings = postings;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// A company that has not been verified yet cannot post (the database refuses it too): explain and
  /// point to the documents instead of opening an empty form.
  Future<void> _newPosting() async {
    Map<String, dynamic>? company;
    try {
      company = await CompanyService.instance.getMyCompany();
    } catch (_) {
      // fall through: the form opens and the database has the last word
    }
    if (!mounted) return;
    if (company != null && company['status'] != 'verified') {
      final rejected = company['status'] == 'rejected';
      final seeDocs = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr('Your company is not verified yet', ms: 'Syarikat anda belum disahkan', zh: '您的公司尚未认证')),
          content: Text(rejected
              ? tr('An administrator turned your company down. Open your company documents to see why and upload the right ones.',
                  ms: 'Pentadbir menolak syarikat anda. Buka dokumen syarikat untuk melihat sebab dan memuat naik yang betul.',
                  zh: '管理员未通过您的公司。请打开公司文件查看原因并上传正确的文件。')
              : tr('You can post internships once an administrator has verified your company documents.',
                  ms: 'Anda boleh menyiarkan latihan industri selepas pentadbir mengesahkan dokumen syarikat anda.',
                  zh: '管理员认证您的公司文件后，您就可以发布实习职位。')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Close', ms: 'Tutup', zh: '关闭'))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Company documents', ms: 'Dokumen syarikat', zh: '公司文件'))),
          ],
        ),
      );
      if (seeDocs == true && mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const HrCompanyVerificationScreen()));
      }
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const _AddEditPostingScreen()));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: l10n.hrJobPostings,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _newPosting,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Flexible(child: Text(l10n.hrPostingsCount(_postings.length), style: AppTextStyles.caption, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Flexible(child: Text(l10n.hrActiveCount(_postings.where((p) => p['status'] == 'open').length),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success))),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _postings.isEmpty
                        ? EmptyState(
                            icon: Icons.work_outline,
                            title: l10n.hrNoPostingsYet,
                            description: l10n.hrCreateFirstPosting,
                            buttonLabel: l10n.hrNewPosting,
                            onButton: _newPosting,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: _postings.length,
                            itemBuilder: (_, i) => _PostingCard(
                              data: _postings[i],
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _AddEditPostingScreen(posting: _postings[i]))).then((_) => _load()),
                              onRecommend: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RecommendedCandidatesScreen(
                                    postingTitle: _postings[i]['title'] as String,
                                    requiredSkills: List<String>.from(_postings[i]['required_skills'] as List? ?? []),
                                  ),
                                ),
                              ),
                              onToggleStatus: () async {
                                final newStatus = _postings[i]['status'] == 'open' ? 'closed' : 'open';
                                if (newStatus == 'open' && _postings[i]['expired'] == true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppLocalizations.of(context)!.hpDeadlinePassed),
                                      backgroundColor: AppColors.warning,
                                    ),
                                  );
                                  return;
                                }
                                try {
                                  await HrDataService.instance.setPostingStatus(id: _postings[i]['id'] as String, status: newStatus);
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.error));
                                }
                                _load();
                              },
                              onDelete: () async {
                                await HrDataService.instance.deletePosting(_postings[i]['id'] as String);
                                _load();
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _AddEditPostingScreen())).then((_) => _load()),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _PostingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback onRecommend;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _PostingCard({required this.data, required this.onTap, required this.onRecommend, required this.onToggleStatus, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isActive = data['status'] == 'open';
    final expired = data['expired'] == true;
    return AccentCard(
      onTap: onTap,
      accentColor: isActive ? AppColors.success : AppColors.textMuted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(data['title'] as String, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ),
              isActive
                  ? StatusBadge.active(context)
                  : (expired
                      ? StatusBadge(label: AppLocalizations.of(context)!.hpExpired, backgroundColor: AppColors.warningBg, textColor: AppColors.warning)
                      : StatusBadge(label: l10n.hrClosedStatus, backgroundColor: const Color(0xFFF1EFE8), textColor: const Color(0xFF5F5E5A))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 3),
              Flexible(
                child: Text((data['location'] as String?) ?? l10n.notSpecified,
                    style: AppTextStyles.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 12),
              Icon(Icons.schedule, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 3),
              Text(l10n.hrMonths(data['duration_months'] as int? ?? 0), style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.attach_money, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 1),
              Flexible(child: Text(formatAllowance(parseNum(data['allowance_month'])), style: AppTextStyles.caption, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(l10n.hrApplicantsCount(data['applicant_count'] as int? ?? 0),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
                ),
              ),
              const SizedBox(width: 8),
              if (data['posted_at'] != null)
                Expanded(
                  child: Text(l10n.hrPostedAgo(timeAgo(context, DateTime.parse(data['posted_at'] as String))),
                      style: AppTextStyles.caption, textAlign: TextAlign.end, overflow: TextOverflow.ellipsis),
                )
              else
                const Spacer(),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                onSelected: (v) {
                  if (v == 'recommend') onRecommend();
                  if (v == 'toggle') onToggleStatus();
                  if (v == 'delete') _confirmDelete(context);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'recommend', child: Text(AppLocalizations.of(context)!.hpRecommended)),
                  PopupMenuItem(value: 'toggle', child: Text(isActive ? l10n.hrClosePosting : l10n.hrReopenPosting)),
                  PopupMenuItem(value: 'delete', child: Text(l10n.delete, style: TextStyle(color: AppColors.error))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(l10n.hrDeletePostingTitle, style: AppTextStyles.h3),
        content: Text(l10n.hrDeletePostingMessage, style: AppTextStyles.bodySecondary),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: Text(l10n.delete, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

const _kCategories = ['Software', 'Data', 'Design', 'Network', 'Business'];
const _kCustomCategoryOption = '__custom__';

class _AddEditPostingScreen extends StatefulWidget {
  final Map<String, dynamic>? posting;

  const _AddEditPostingScreen({this.posting});

  @override
  State<_AddEditPostingScreen> createState() => _AddEditPostingScreenState();
}

class _AddEditPostingScreenState extends State<_AddEditPostingScreen> {
  late bool isEdit;
  bool _isSaving = false;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _allowanceController = TextEditingController();
  final _skillController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _skillFieldKey = GlobalKey<FormFieldState<String>>();
  bool _attempted = false;
  final _customCategoryController = TextEditingController();
  String _category = _kCategories.first;
  bool _isCustomCategory = false;
  int _durationMonths = 3;
  String? _jobType;
  DateTime? _deadline;
  String? _locationText;
  double? _locationLat;
  double? _locationLng;
  final List<String> _skills = [];

  @override
  void initState() {
    super.initState();
    isEdit = widget.posting != null;
    if (isEdit) {
      final p = widget.posting!;
      _titleController.text = p['title'] as String? ?? '';
      _descriptionController.text = p['description'] as String? ?? '';
      _locationText = p['location'] as String?;
      _allowanceController.text = p['allowance_month'] != null ? '${parseNum(p['allowance_month'])}' : '';
      _category = (p['category'] as String?) ?? _kCategories.first;
      if (!_kCategories.contains(_category)) {
        _isCustomCategory = true;
        _customCategoryController.text = _category;
      }
      _durationMonths = p['duration_months'] as int? ?? 3;
      _jobType = p['job_type'] as String?;
      final deadlineRaw = p['application_deadline'] as String?;
      _deadline = deadlineRaw != null ? DateTime.tryParse(deadlineRaw) : null;
      _skills.addAll(List<String>.from(p['required_skills'] as List? ?? []));
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<PickedAddress>(
      context,
      MaterialPageRoute(builder: (_) => AddressPickerScreen(initialLat: _locationLat, initialLng: _locationLng)),
    );
    if (result != null) {
      setState(() {
        _locationText = result.addressText;
        _locationLat = result.lat;
        _locationLng = result.lng;
      });
    }
  }

  String? get _locationError =>
      (_locationText == null || _locationText!.trim().isEmpty) ? AppLocalizations.of(context)!.hpChooseLocation : null;

  String? get _skillsError => _skills.isEmpty ? AppLocalizations.of(context)!.hpAddOneSkill : null;

  Widget _inlineError(String? message) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(message, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
    );
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      // Never earlier than firstDate: editing an expired posting starts from a future date.
      initialDate: (_deadline != null && !_deadline!.isBefore(DateTime.now())) ? _deadline! : DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _save() async {
    setState(() => _attempted = true);
    // Text fields show their own message under the field; the location,
    // skills and dates show theirs inline too.
    final fieldsOk = _formKey.currentState?.validate() ?? false;
    final allowance = double.tryParse(_allowanceController.text.trim());
    if (!fieldsOk || _locationError != null || _skillsError != null || allowance == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.hpFixFields),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    final category = _isCustomCategory ? _customCategoryController.text.trim() : _category;
    setState(() => _isSaving = true);
    try {
      if (isEdit) {
        await HrDataService.instance.updatePosting(
          id: widget.posting!['id'] as String,
          title: _titleController.text,
          description: _descriptionController.text,
          category: category,
          location: _locationText!,
          durationMonths: _durationMonths,
          allowanceMonth: allowance,
          requiredSkills: _skills,
          jobType: _jobType,
          applicationDeadline: _deadline,
          // The posting closes with its application deadline (no separate closing date).
          postingClosesAt: null,
        );
      } else {
        await HrDataService.instance.createPosting(
          title: _titleController.text,
          description: _descriptionController.text,
          category: category,
          location: _locationText!,
          durationMonths: _durationMonths,
          allowanceMonth: allowance,
          requiredSkills: _skills,
          jobType: _jobType,
          applicationDeadline: _deadline,
          // The posting closes with its application deadline (no separate closing date).
          postingClosesAt: null,
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.hpCouldNotSave(friendlyError(e))), backgroundColor: AppColors.error));
    }
  }

  Future<void> _delete() async {
    setState(() => _isSaving = true);
    try {
      await HrDataService.instance.deletePosting(widget.posting!['id'] as String);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.hpCouldNotDelete(friendlyError(e))), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(isEdit ? l10n.hrEditPosting : l10n.hrNewPosting, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        actions: [
          if (isEdit) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white), onPressed: () => _confirmDelete(context)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.hrPostingDetails, style: AppTextStyles.label),
            const SizedBox(height: 8),
            ValidatedField(
              controller: _titleController,
              fieldValidator: (v) => v.trim().isEmpty ? l10n.hrTitleLocationRequired : Validators.text(v, field: 'Job title', min: 5, max: 100),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              maxLength: 100,
              labelText: l10n.hrJobTitle,
              hintText: l10n.hrJobTitleHint,
            ),
            const SizedBox(height: 12),
            ValidatedField(
              controller: _descriptionController,
              fieldValidator: (v) => v.trim().isEmpty ? l10n.hrDescriptionRequired : Validators.text(v, field: 'Description', min: 30, max: 2000),
              maxLines: 4,
              maxLength: 2000,
              showSuccess: false,
              labelText: l10n.hrJobDescription,
              hintText: l10n.hrJobDescriptionHint,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.hrCategory),
              value: _isCustomCategory ? _kCustomCategoryOption : _category,
              items: [
                ..._kCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))),
                DropdownMenuItem(value: _kCustomCategoryOption, child: Text(AppLocalizations.of(context)!.hpCustom, style: const TextStyle(fontSize: 13))),
              ],
              onChanged: (v) {
                setState(() {
                  if (v == _kCustomCategoryOption) {
                    _isCustomCategory = true;
                  } else {
                    _isCustomCategory = false;
                    _category = v ?? _category;
                  }
                });
              },
            ),
            if (_isCustomCategory) ...[
              const SizedBox(height: 12),
              ValidatedField(
                controller: _customCategoryController,
                fieldValidator: (v) => Validators.text(v, field: 'Custom category', min: 2, max: 40),
                textCapitalization: TextCapitalization.words,
                maxLength: 40,
                labelText: AppLocalizations.of(context)!.hpCustomCategory,
                hintText: AppLocalizations.of(context)!.hpCustomCategoryHint,
              ),
            ],
            const SizedBox(height: 20),
            Text(l10n.hrLogistics, style: AppTextStyles.label),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickLocation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _locationText ?? l10n.hrLocationHint,
                        style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: _locationText != null ? AppColors.textPrimary : AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_attempted || _locationText != null) _inlineError(_locationError),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.hrJobType),
              value: _jobType,
              items: _kJobTypes.map((j) => DropdownMenuItem(value: j, child: Text(j, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _jobType = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.hrDuration),
              value: _durationMonths,
              items: [3, 4, 5, 6].map((m) => DropdownMenuItem(value: m, child: Text(l10n.hrMonths(m), style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _durationMonths = v ?? _durationMonths),
            ),
            const SizedBox(height: 12),
            ValidatedField(
              controller: _allowanceController,
              fieldValidator: (v) {
                if (v.trim().isEmpty) return l10n.hrValidAllowanceRequired;
                final money = Validators.money(v, field: 'Allowance', max: 20000);
                if (money != null) return money;
                if (double.parse(v.trim()) <= 0) return AppLocalizations.of(context)!.hpAllowancePositive;
                return null;
              },
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              showSuccess: false,
              labelText: l10n.hrMonthlyAllowance,
              hintText: l10n.hrMonthlyAllowanceHint,
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDeadline,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                child: Row(
                  children: [
                    Icon(Icons.event_busy_outlined, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _deadline != null ? l10n.hrDeadlineLabel('${_deadline!.day}/${_deadline!.month}/${_deadline!.year}') : l10n.hrApplicationDeadlineOptional,
                        style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: _deadline != null ? AppColors.textPrimary : AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(AppLocalizations.of(context)!.hpClosesAfterDeadline, style: AppTextStyles.caption),
            ),
            const SizedBox(height: 20),
            Text(l10n.hrSkillsRequired, style: AppTextStyles.label),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ValidatedField(
                    key: _skillFieldKey,
                    controller: _skillController,
                    fieldValidator: (v) => Validators.skill(v, existing: _skills),
                    showSuccess: false,
                    maxLength: 40,
                    hintText: l10n.hrAddASkill,
                    onSubmitted: (_) => _addSkill(),
                  ),
                ),
                IconButton(icon: Icon(Icons.add_circle, color: AppColors.primaryText), onPressed: _addSkill),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills
                  .map((s) => Chip(
                        label: Text(s, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.primaryText)),
                        backgroundColor: AppColors.accent,
                        onDeleted: () => setState(() => _skills.remove(s)),
                      ))
                  .toList(),
            ),
            if (_attempted) _inlineError(_skillsError),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isEdit ? l10n.hrSaveChanges : l10n.hrPublishPosting),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _addSkill() {
    final value = _skillController.text.trim();
    if (value.isEmpty) return;
    if (Validators.skill(value, existing: _skills) != null) {
      _skillFieldKey.currentState?.validate();
      return;
    }
    setState(() {
      _skills.add(value);
      _skillController.clear();
    });
  }

  void _confirmDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(l10n.hrDeletePostingTitle, style: AppTextStyles.h3),
        content: Text(l10n.hrDeletePostingMessage, style: AppTextStyles.bodySecondary),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _delete();
            },
            child: Text(l10n.delete, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
