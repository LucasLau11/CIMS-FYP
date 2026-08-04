import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/admin_data_service.dart';
import '../../utils/format_utils.dart';
import '../student/address_picker_screen.dart';
import '../../l10n/app_localizations.dart';

class AdminCompaniesScreen extends StatefulWidget {
  const AdminCompaniesScreen({super.key});

  @override
  State<AdminCompaniesScreen> createState() => _AdminCompaniesScreenState();
}

class _AdminCompaniesScreenState extends State<AdminCompaniesScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _companies = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final companies = await AdminDataService.instance.getCompanies();
      if (!mounted) return;
      setState(() {
        _companies = companies;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchController.text.isEmpty) return _companies;
    final q = _searchController.text.toLowerCase();
    return _companies.where((c) => (c['name'] as String).toLowerCase().contains(q)).toList();
  }

  List<String> get _existingIndustries {
    final set = <String>{};
    for (final c in _companies) {
      final industry = c['industry'] as String?;
      if (industry != null && industry.trim().isNotEmpty) set.add(industry.trim());
    }
    final list = set.toList()..sort();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final results = _filtered;
    final pendingCount = _companies.where((c) => c['status'] == 'pending').length;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: l10n.adminCompaniesTitle),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(hintText: l10n.adminSearchCompaniesHint, prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textMuted)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        Text(l10n.adminRegisteredCompaniesCount(results.length), style: AppTextStyles.caption),
                        const Spacer(),
                        if (pendingCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(6)),
                            child: Text(l10n.adminPendingVerificationCount(pendingCount),
                                style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning)),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: results.isEmpty
                        ? EmptyState(icon: Icons.business_outlined, title: l10n.adminNoCompaniesTitle, description: l10n.adminNoCompaniesDescription)
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: results.length,
                            itemBuilder: (_, i) => _CompanyCard(
                              data: results[i],
                              onTap: () async {
                                final changed = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(builder: (_) => _CompanyDetailScreen(data: results[i], existingIndustries: _existingIndustries)),
                                );
                                if (changed == true) _load();
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => _AddEditCompanyScreen(existingIndustries: _existingIndustries)),
          );
          if (added == true) _load();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _CompanyCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPending = data['status'] == 'pending';
    final name = data['name'] as String;
    return AccentCard(
      onTap: onTap,
      accentColor: isPending ? AppColors.warning : AppColors.success,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: nameColor(name).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: Text(logoLetter(name), style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: nameColor(name))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text('${data['industry'] ?? l10n.setupIndustryNotSet} · ${data['location'] ?? l10n.adminLocationNotSet}', style: AppTextStyles.caption),
              ],
            ),
          ),
          isPending
              ? StatusBadge(label: l10n.adminStatusPending, backgroundColor: const Color(0xFFFEF3C7), textColor: const Color(0xFFD97706))
              : StatusBadge(label: l10n.adminStatusVerified, backgroundColor: const Color(0xFFE2F6EF), textColor: const Color(0xFF1A9E6E)),
        ],
      ),
    );
  }
}

class _CompanyDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final List<String> existingIndustries;

  const _CompanyDetailScreen({required this.data, this.existingIndustries = const []});

  @override
  State<_CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<_CompanyDetailScreen> {
  bool _changed = false;

  Future<void> _verify() async {
    try {
      await AdminDataService.instance.verifyCompany(widget.data['id'] as String);
      _changed = true;
      if (!mounted) return;
      setState(() => widget.data['status'] = 'verified');
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.adminCouldNotVerify(e.toString())), backgroundColor: AppColors.error));
    }
  }

  Future<void> _remove() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.adminRemoveCompanyTitle),
        content: Text(l10n.adminRemoveCompanyMessage(widget.data['name'] as String)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.remove, style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AdminDataService.instance.deleteCompany(widget.data['id'] as String);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.adminCouldNotRemove(e.toString())), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = widget.data;
    final name = data['name'] as String;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context, _changed)),
          title: Text(l10n.adminCompanyDetailsTitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: () async {
                final edited = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => _AddEditCompanyScreen(company: data, existingIndustries: widget.existingIndustries)),
                );
                if (edited == true) {
                  _changed = true;
                  if (!mounted) return;
                  setState(() {});
                }
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: nameColor(name).withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
                    child: Center(
                      child: Text(logoLetter(name), style: TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w700, color: nameColor(name))),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(name, style: AppTextStyles.h2, textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text((data['industry'] as String?) ?? l10n.setupIndustryNotSet, style: AppTextStyles.bodySecondary),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(l10n.adminCompanyInformation, style: AppTextStyles.label),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Column(
                children: [
                  _DetailRow(icon: Icons.location_on_outlined, label: l10n.adminLocationLabel, value: (data['location'] as String?) ?? l10n.notSet),
                  const Divider(height: 1, indent: 44),
                  _DetailRow(icon: Icons.person_outline, label: l10n.adminHrContactLabel, value: (data['hr_contact_name'] as String?) ?? l10n.notSet),
                  const Divider(height: 1, indent: 44),
                  _DetailRow(icon: Icons.email_outlined, label: l10n.adminHrEmailLabel, value: (data['hr_contact_email'] as String?) ?? l10n.notSet),
                  const Divider(height: 1, indent: 44),
                  _DetailRow(icon: Icons.phone_outlined, label: l10n.adminHrPhoneLabel, value: (data['hr_contact_phone'] as String?) ?? l10n.notSet),
                  const Divider(height: 1, indent: 44),
                  _DetailRow(icon: Icons.verified_outlined, label: l10n.adminStatusLabel, value: data['status'] == 'verified' ? l10n.adminStatusVerified : l10n.adminStatusPending),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (data['status'] == 'pending')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(onPressed: _verify, icon: const Icon(Icons.check_circle_outline, size: 18), label: Text(l10n.adminVerifyCompany)),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _remove,
                icon: Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                label: Text(l10n.adminRemoveCompanyButton, style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.error)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddEditCompanyScreen extends StatefulWidget {
  final Map<String, dynamic>? company;
  final List<String> existingIndustries;

  const _AddEditCompanyScreen({this.company, this.existingIndustries = const []});

  @override
  State<_AddEditCompanyScreen> createState() => _AddEditCompanyScreenState();
}

const String _kOtherIndustryValue = '__other__';

class _AddEditCompanyScreenState extends State<_AddEditCompanyScreen> {
  late bool isEdit;
  late final _nameController = TextEditingController(text: widget.company?['name'] as String? ?? '');
  late final _hrNameController = TextEditingController(text: widget.company?['hr_contact_name'] as String? ?? '');
  late final _hrEmailController = TextEditingController(text: widget.company?['hr_contact_email'] as String? ?? '');
  late final _hrPhoneController = TextEditingController(text: widget.company?['hr_contact_phone'] as String? ?? '');
  final _industryOtherController = TextEditingController();
  String? _industry;
  bool _useOtherIndustry = false;
  bool _isSaving = false;

  String? _locationText;
  double? _locationLat;
  double? _locationLng;

  late final List<String> _industryOptions = widget.existingIndustries;

  @override
  void initState() {
    super.initState();
    isEdit = widget.company != null;
    final existingIndustry = widget.company?['industry'] as String?;
    if (existingIndustry != null && existingIndustry.trim().isNotEmpty) {
      if (_industryOptions.contains(existingIndustry)) {
        _industry = existingIndustry;
        _useOtherIndustry = false;
      } else {
        _useOtherIndustry = true;
        _industryOtherController.text = existingIndustry;
      }
    }
    _locationText = widget.company?['location'] as String?;
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

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.adminCompanyNameRequired), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _isSaving = true);
    final industryValue = _useOtherIndustry
        ? (_industryOtherController.text.trim().isEmpty ? null : _industryOtherController.text.trim())
        : _industry;
    try {
      if (isEdit) {
        await AdminDataService.instance.updateCompany(
          id: widget.company!['id'] as String,
          name: _nameController.text.trim(),
          industry: industryValue,
          location: _locationText == null || _locationText!.trim().isEmpty ? null : _locationText!.trim(),
          hrContactName: _hrNameController.text.trim().isEmpty ? null : _hrNameController.text.trim(),
          hrContactEmail: _hrEmailController.text.trim().isEmpty ? null : _hrEmailController.text.trim(),
          hrContactPhone: _hrPhoneController.text.trim().isEmpty ? null : _hrPhoneController.text.trim(),
        );
      } else {
        await AdminDataService.instance.addCompany(
          name: _nameController.text.trim(),
          industry: industryValue,
          location: _locationText == null || _locationText!.trim().isEmpty ? null : _locationText!.trim(),
          hrContactName: _hrNameController.text.trim().isEmpty ? null : _hrNameController.text.trim(),
          hrContactEmail: _hrEmailController.text.trim().isEmpty ? null : _hrEmailController.text.trim(),
          hrContactPhone: _hrPhoneController.text.trim().isEmpty ? null : _hrPhoneController.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.adminCouldNotSave(e.toString())), backgroundColor: AppColors.error));
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
        title: Text(isEdit ? l10n.adminEditCompanyTitle : l10n.adminAddCompany,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.adminCompanyInformation, style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(controller: _nameController, decoration: InputDecoration(labelText: l10n.adminCompanyNameLabel)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: l10n.adminIndustryLabel),
              value: _useOtherIndustry ? _kOtherIndustryValue : _industry,
              items: [
                ..._industryOptions.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))),
                DropdownMenuItem(value: _kOtherIndustryValue, child: Text(l10n.adminOtherIndustryOption, style: const TextStyle(fontSize: 13))),
              ],
              onChanged: (v) => setState(() {
                if (v == _kOtherIndustryValue) {
                  _useOtherIndustry = true;
                  _industry = null;
                } else {
                  _useOtherIndustry = false;
                  _industry = v;
                }
              }),
            ),
            if (_useOtherIndustry) ...[
              const SizedBox(height: 12),
              TextFormField(controller: _industryOtherController, decoration: InputDecoration(labelText: l10n.adminIndustryNameLabel)),
            ],
            const SizedBox(height: 12),
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
                        _locationText ?? l10n.adminSelectLocation,
                        style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: _locationText != null ? AppColors.textPrimary : AppColors.textMuted),
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(l10n.adminHrContactSection, style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(controller: _hrNameController, decoration: InputDecoration(labelText: l10n.adminHrContactNameLabel)),
            const SizedBox(height: 12),
            TextFormField(controller: _hrEmailController, decoration: InputDecoration(labelText: l10n.adminHrEmailFieldLabel)),
            const SizedBox(height: 12),
            TextFormField(controller: _hrPhoneController, decoration: InputDecoration(labelText: l10n.adminHrPhoneNumberLabel)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isEdit ? l10n.hrSaveChanges : l10n.adminAddCompany),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
