import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/hr_data_service.dart';
import '../../utils/format_utils.dart';
import '../student/address_picker_screen.dart';
import 'hr_recommended_candidates_screen.dart';

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
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _AddEditPostingScreen())).then((_) => _load()),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Text(l10n.hrPostingsCount(_postings.length), style: AppTextStyles.caption),
                        const Spacer(),
                        Text(l10n.hrActiveCount(_postings.where((p) => p['status'] == 'open').length),
                            style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
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
                            onButton: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _AddEditPostingScreen())).then((_) => _load()),
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
                                await HrDataService.instance.setPostingStatus(id: _postings[i]['id'] as String, status: newStatus);
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
              isActive ? StatusBadge.active() : StatusBadge(label: l10n.hrClosedStatus, backgroundColor: const Color(0xFFF1EFE8), textColor: const Color(0xFF5F5E5A)),
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
              Text(formatAllowance(parseNum(data['allowance_month'])), style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(20)),
                child: Text(l10n.hrApplicantsCount(data['applicant_count'] as int? ?? 0),
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
              const Spacer(),
              if (data['posted_at'] != null)
                Flexible(
                  child: Text(l10n.hrPostedAgo(timeAgo(DateTime.parse(data['posted_at'] as String))),
                      style: AppTextStyles.caption, textAlign: TextAlign.end),
                ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                onSelected: (v) {
                  if (v == 'recommend') onRecommend();
                  if (v == 'toggle') onToggleStatus();
                  if (v == 'delete') _confirmDelete(context);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'recommend', child: Text('Recommended candidates')),
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
  final _customCategoryController = TextEditingController();
  String _category = _kCategories.first;
  bool _isCustomCategory = false;
  int _durationMonths = 3;
  String? _jobType;
  DateTime? _deadline;
  DateTime? _closesAt;
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
      final closesAtRaw = p['posting_closes_at'] as String?;
      _closesAt = closesAtRaw != null ? DateTime.tryParse(closesAtRaw) : null;
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

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _pickClosesAt() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _closesAt ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _closesAt = picked);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_titleController.text.trim().isEmpty || _locationText == null || _locationText!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.hrTitleLocationRequired), backgroundColor: AppColors.error));
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.hrDescriptionRequired), backgroundColor: AppColors.error));
      return;
    }
    final allowance = double.tryParse(_allowanceController.text.trim());
    if (_allowanceController.text.trim().isEmpty || allowance == null || allowance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.hrValidAllowanceRequired), backgroundColor: AppColors.error));
      return;
    }
    if (_skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.hrSkillRequired), backgroundColor: AppColors.error));
      return;
    }
    if (_isCustomCategory && _customCategoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Enter a custom category or pick one from the list.'), backgroundColor: AppColors.error));
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
          postingClosesAt: _closesAt,
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
          postingClosesAt: _closesAt,
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save posting: $e'), backgroundColor: AppColors.error));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete posting: $e'), backgroundColor: AppColors.error));
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.hrPostingDetails, style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(controller: _titleController, decoration: InputDecoration(labelText: l10n.hrJobTitle, hintText: l10n.hrJobTitleHint)),
            const SizedBox(height: 12),
            TextFormField(controller: _descriptionController, decoration: InputDecoration(labelText: l10n.hrJobDescription, hintText: l10n.hrJobDescriptionHint), maxLines: 4),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: l10n.hrCategory),
              value: _isCustomCategory ? _kCustomCategoryOption : _category,
              items: [
                ..._kCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))),
                const DropdownMenuItem(value: _kCustomCategoryOption, child: Text('Custom…', style: TextStyle(fontSize: 13))),
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
              TextFormField(
                controller: _customCategoryController,
                decoration: const InputDecoration(labelText: 'Custom category', hintText: 'e.g. Marketing'),
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
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: l10n.hrJobType),
              value: _jobType,
              items: _kJobTypes.map((j) => DropdownMenuItem(value: j, child: Text(j, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _jobType = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(labelText: l10n.hrDuration),
              value: _durationMonths,
              items: [3, 4, 5, 6].map((m) => DropdownMenuItem(value: m, child: Text(l10n.hrMonths(m), style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _durationMonths = v ?? _durationMonths),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _allowanceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.hrMonthlyAllowance, hintText: l10n.hrMonthlyAllowanceHint),
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
                    Text(
                      _deadline != null ? l10n.hrDeadlineLabel('${_deadline!.day}/${_deadline!.month}/${_deadline!.year}') : l10n.hrApplicationDeadlineOptional,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: _deadline != null ? AppColors.textPrimary : AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Posting closes automatically after (optional)', style: AppTextStyles.caption),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [7, 14, 30, 60, 90].map((days) {
                final target = DateTime.now().add(Duration(days: days));
                final selected = _closesAt != null && _closesAt!.year == target.year && _closesAt!.month == target.month && _closesAt!.day == target.day;
                return ChoiceChip(
                  label: Text('${days}d', style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
                  selected: selected,
                  selectedColor: AppColors.accent,
                  onSelected: (_) => setState(() => _closesAt = target),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickClosesAt,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                child: Row(
                  children: [
                    Icon(Icons.lock_clock_outlined, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _closesAt != null ? 'Posting closes on ${_closesAt!.day}/${_closesAt!.month}/${_closesAt!.year}' : 'Auto-close date (optional)',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: _closesAt != null ? AppColors.textPrimary : AppColors.textMuted),
                      ),
                    ),
                    if (_closesAt != null)
                      IconButton(
                        icon: Icon(Icons.close, size: 16, color: AppColors.textMuted),
                        onPressed: () => setState(() => _closesAt = null),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(l10n.hrSkillsRequired, style: AppTextStyles.label),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _skillController, decoration: InputDecoration(hintText: l10n.hrAddASkill), onFieldSubmitted: (_) => _addSkill())),
                IconButton(icon: const Icon(Icons.add_circle, color: AppColors.primary), onPressed: _addSkill),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills
                  .map((s) => Chip(
                        label: Text(s, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.primary)),
                        backgroundColor: AppColors.accent,
                        onDeleted: () => setState(() => _skills.remove(s)),
                      ))
                  .toList(),
            ),
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
    );
  }

  void _addSkill() {
    final value = _skillController.text.trim();
    if (value.isEmpty || _skills.contains(value)) return;
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
