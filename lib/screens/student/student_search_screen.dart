import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/student_data_service.dart';
import '../../utils/format_utils.dart';
import 'student_internship_details_screen.dart';

class StudentSearchScreen extends StatefulWidget {
  const StudentSearchScreen({super.key});

  @override
  State<StudentSearchScreen> createState() => _StudentSearchScreenState();
}

class _StudentSearchScreenState extends State<StudentSearchScreen> {
  final _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _internships = [];
  Set<String> _appliedIds = {};

  String _selectedCategory = 'All';
  String _selectedLocation = 'All';
  int? _selectedDuration;
  RangeValues _allowanceRange = const RangeValues(0, 5000);

  final List<String> _categories = ['All', 'Software', 'Data', 'Design', 'Network', 'Business'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final internships = await StudentDataService.instance.getOpenInternships();
      final appliedIds = await StudentDataService.instance.getAppliedInternshipIds();
      if (!mounted) return;
      setState(() {
        _internships = internships;
        _appliedIds = appliedIds;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _error = l10n.errorLoadInternships(e.toString());
        _isLoading = false;
      });
    }
  }

  List<String> get _availableLocations {
    final locations = _internships.map((i) => i['location'] as String).toSet().toList()..sort();
    return ['All', ...locations];
  }

  List<int> get _availableDurations {
    final durations = _internships.map((i) => i['duration_months'] as int).toSet().toList()..sort();
    return durations;
  }

  List<Map<String, dynamic>> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _internships.where((i) {
      if (_selectedCategory != 'All' && i['category'] != _selectedCategory) return false;
      if (_selectedLocation != 'All' && i['location'] != _selectedLocation) return false;
      if (_selectedDuration != null && i['duration_months'] != _selectedDuration) return false;

      final allowance = parseNum(i['allowance_month'])?.toDouble() ?? 0;
      if (allowance < _allowanceRange.start || allowance > _allowanceRange.end) return false;

      if (query.isNotEmpty) {
        final skills = (i['required_skills'] as List).cast<String>().join(' ').toLowerCase();
        final haystack = '${i['title']} ${i['company_name']} $skills'.toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final results = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: l10n.searchInternships,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: l10n.titleSomethingWentWrong,
                  description: _error!,
                  buttonLabel: l10n.retry,
                  onButton: _load,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: Column(
                    children: [
                      // Search bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: l10n.searchByRoleCompanySkillHint,
                            prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),

                      // Category filter chips
                      SizedBox(
                        height: 42,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final selected = _selectedCategory == _categories[i];
                            return FilterChip(
                              label: Text(_categories[i]),
                              selected: selected,
                              onSelected: (_) => setState(() => _selectedCategory = _categories[i]),
                              backgroundColor: AppColors.surface,
                              selectedColor: AppColors.accent,
                              checkmarkColor: AppColors.primary,
                              labelStyle: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                color: selected ? AppColors.primary : AppColors.textSecondary,
                              ),
                            );
                          },
                        ),
                      ),

                      // Results count
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Row(
                          children: [
                            Text(l10n.opportunitiesFoundCount(results.length), style: AppTextStyles.caption),
                          ],
                        ),
                      ),

                      // Listing
                      Expanded(
                        child: results.isEmpty
                            ? EmptyState(
                                icon: Icons.search_off,
                                title: l10n.noMatches,
                                description: l10n.tryAdjustingSearchFilters,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 16),
                                itemCount: results.length,
                                itemBuilder: (_, i) {
                                  final internship = results[i];
                                  final applied = _appliedIds.contains(internship['id']);
                                  return _InternshipCard(
                                    data: internship,
                                    applied: applied,
                                    onTap: () async {
                                      final result = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => StudentInternshipDetailsScreen(internship: internship, applied: applied),
                                        ),
                                      );
                                      if (result == true) _load();
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FilterSheet(
        locations: _availableLocations,
        durations: _availableDurations,
        selectedLocation: _selectedLocation,
        selectedDuration: _selectedDuration,
        allowanceRange: _allowanceRange,
        onApply: (location, duration, range) {
          setState(() {
            _selectedLocation = location;
            _selectedDuration = duration;
            _allowanceRange = range;
          });
        },
      ),
    );
  }
}

class _InternshipCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool applied;
  final VoidCallback onTap;

  const _InternshipCard({required this.data, required this.applied, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final companyName = data['company_name'] as String;
    final postedAt = DateTime.parse(data['posted_at'] as String);
    final skills = (data['required_skills'] as List).cast<String>();

    return AccentCard(
      onTap: onTap,
      accentColor: applied ? AppColors.success : AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: nameColor(companyName).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    logoLetter(companyName),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: nameColor(companyName),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['title'] as String,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    Text(companyName, style: AppTextStyles.bodySecondary.copyWith(fontSize: 13)),
                  ],
                ),
              ),
              if (applied)
                StatusBadge(
                  label: l10n.stepApplied,
                  backgroundColor: AppColors.successBg,
                  textColor: AppColors.success,
                ),
              if ((data['companies'] as Map<String, dynamic>?)?['status'] != 'verified')
                StatusBadge(
                  label: l10n.pendingVerification,
                  backgroundColor: AppColors.warningBg,
                  textColor: AppColors.warning,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Flexible(
                child: _InfoChip(icon: Icons.location_on_outlined, label: data['location'] as String),
              ),
              const SizedBox(width: 8),
              _InfoChip(icon: Icons.schedule, label: formatDuration(data['duration_months'] as int)),
              const SizedBox(width: 8),
              _InfoChip(icon: Icons.attach_money, label: formatAllowance(parseNum(data['allowance_month']))),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: skills.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(tag,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(timeAgo(context, postedAt), style: AppTextStyles.caption),
              const Spacer(),
              if (!applied)
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(l10n.viewDetails, style: const TextStyle(fontSize: 13)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final List<String> locations;
  final List<int> durations;
  final String selectedLocation;
  final int? selectedDuration;
  final RangeValues allowanceRange;
  final void Function(String location, int? duration, RangeValues range) onApply;

  const _FilterSheet({
    required this.locations,
    required this.durations,
    required this.selectedLocation,
    required this.selectedDuration,
    required this.allowanceRange,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _location = widget.selectedLocation;
  late int? _duration = widget.selectedDuration;
  late RangeValues _range = widget.allowanceRange;

  late final TextEditingController _minController = TextEditingController(
    text: widget.allowanceRange.start > 0 ? widget.allowanceRange.start.round().toString() : '',
  );
  late final TextEditingController _maxController = TextEditingController(
    text: widget.allowanceRange.end.isFinite ? widget.allowanceRange.end.round().toString() : '',
  );

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _updateRange() {
    final min = double.tryParse(_minController.text.trim());
    final max = double.tryParse(_maxController.text.trim());
    setState(() {
      _range = RangeValues(
        (min != null && min >= 0) ? min : 0,
        (max != null && max >= 0) ? max : double.infinity,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l10n.filters, style: AppTextStyles.h3),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() {
                  _location = 'All';
                  _duration = null;
                  _range = const RangeValues(0, 5000);
                  _minController.clear();
                  _maxController.text = '5000';
                }),
                child: Text(l10n.reset, style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.hrLocation, style: AppTextStyles.label),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(),
            isExpanded: true,
            value: _location,
            items: widget.locations
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e, overflow: TextOverflow.ellipsis, maxLines: 1),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _location = v!),
          ),
          const SizedBox(height: 16),
          Text(l10n.allowanceRange, style: AppTextStyles.label),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _minController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.minAllowanceLabel,
                  ),
                  onChanged: (_) => _updateRange(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _maxController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.maxAllowanceLabel,
                  ),
                  onChanged: (_) => _updateRange(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.hrDuration, style: AppTextStyles.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: widget.durations.map((d) {
              final selected = _duration == d;
              return FilterChip(
                label: Text(formatDuration(d)),
                selected: selected,
                onSelected: (_) => setState(() => _duration = selected ? null : d),
                labelStyle: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textPrimary),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_location, _duration, _range);
                Navigator.pop(context);
              },
              child: Text(l10n.applyFilters),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
