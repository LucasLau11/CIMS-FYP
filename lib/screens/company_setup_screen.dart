import 'package:flutter/material.dart';
import '../utils/validators.dart';
import '../widgets/common/validated_field.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/common/shared_widgets.dart';
import '../services/company_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'student/address_picker_screen.dart';
import '../utils/error_text.dart';
import '../utils/lang.dart';
import '../utils/company_document_picker.dart';

const List<String> kCompanyIndustries = [
  'Technology',
  'Finance & Banking',
  'Manufacturing',
  'Retail & E-commerce',
  'Healthcare',
  'Education',
  'Telecommunications',
  'Logistics & Transportation',
  'Hospitality & Tourism',
  'Construction & Engineering',
  'Media & Entertainment',
  'Other',
];

/// Shown to HR / Company Supervisor accounts that have no `company_id` yet
/// (a brand-new sign-up) — every screen in those shells (postings,
/// applicants, interns, reviews) is scoped to the caller's company, so
/// there's nothing meaningful to show until one is picked. Lets the user
/// join an existing company from the same list admin manages, or register
/// a new one (`companies_insert_hr_or_company_supervisor` policy).
class CompanySetupScreen extends StatefulWidget {
  final VoidCallback onDone;

  const CompanySetupScreen({super.key, required this.onDone});

  @override
  State<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends State<CompanySetupScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _companies = [];
  String? _selectedCompanyId;
  bool _registeringNew = false;

  final _nameController = TextEditingController();
  final _nameFieldKey = GlobalKey<FormFieldState<String>>();
  String? _industry;
  String? _locationText;
  double? _locationLat;
  double? _locationLng;
  // the legal documents an administrator verifies the company by (required for a new company)
  final List<PickedCompanyDocument> _docs = [];
  String? _docsError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final companies = await CompanyService.instance.getCompanies();
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

  Future<void> _join() async {
    if (_selectedCompanyId == null) return;
    setState(() => _isSubmitting = true);
    try {
      await CompanyService.instance.joinCompany(_selectedCompanyId!);
      widget.onDone();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tt('Could not join company')}: ${friendlyError(e)}'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _register() async {
    // The name field shows its own message (required, length, or "already registered").
    final nameOk = _nameFieldKey.currentState?.validate() ?? false;
    if (_docs.isEmpty) {
      setState(() => _docsError = tr('Upload at least one legal document of your company (for example the SSM certificate).',
          ms: 'Muat naik sekurang-kurangnya satu dokumen perundangan syarikat anda (contohnya sijil SSM).',
          zh: '请至少上传一份公司的法律文件（例如 SSM 证书）。'));
    }
    if (!nameOk || _docs.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await CompanyService.instance.createAndJoinCompany(
        name: _nameController.text,
        industry: _industry,
        location: _locationText,
        documents: _docs,
      );
      widget.onDone();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tt('Could not register company')}: ${friendlyError(e)}'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _addDocs() async {
    final result = await pickCompanyDocuments();
    if (!mounted) return;
    if (result.rejected.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('Not added: ${result.rejected.join(', ')}', ms: 'Tidak ditambah: ${result.rejected.join(', ')}', zh: '未添加：${result.rejected.join('、')}')),
        backgroundColor: AppColors.warning,
      ));
    }
    if (result.accepted.isEmpty) return;
    setState(() {
      _docs.addAll(result.accepted);
      _docsError = null;
    });
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        title: Text(l10n.setupYourCompany, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService.instance.signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.primaryText),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.setupLinkCompanyNote,
                          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.primaryText),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text(l10n.setupJoinExisting),
                        selected: !_registeringNew,
                        onSelected: (_) => setState(() => _registeringNew = false),
                        labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: Text(l10n.setupRegisterNew),
                        selected: _registeringNew,
                        onSelected: (_) => setState(() => _registeringNew = true),
                        labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (!_registeringNew) ...[
                  if (_companies.isEmpty)
                    EmptyState(icon: Icons.business_outlined, title: l10n.setupNoCompaniesYet, description: l10n.setupSwitchToRegister)
                  else ...[
                    ..._companies.map((c) => RadioListTile<String>(
                          value: c['company_id'] as String,
                          groupValue: _selectedCompanyId,
                          onChanged: (v) => setState(() => _selectedCompanyId = v),
                          title: Text(c['name'] as String, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text((c['industry'] as String?) ?? l10n.setupIndustryNotSet, style: AppTextStyles.caption),
                          activeColor: AppColors.primary,
                        )),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting || _selectedCompanyId == null ? null : _join,
                        child: _isSubmitting ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(l10n.setupJoinCompany),
                      ),
                    ),
                  ],
                ] else ...[
                  ValidatedField(
                    key: _nameFieldKey,
                    controller: _nameController,
                    fieldValidator: (v) {
                      if (v.trim().isEmpty) return l10n.setupCompanyNameRequired;
                      final rule = Validators.text(v, field: 'Company name', min: 2, max: 100);
                      if (rule != null) return rule;
                      if (!RegExp(r'\p{L}', unicode: true).hasMatch(v)) return 'Company name must contain letters.';
                      final taken = _companies.any((c) => (c['name'] as String).trim().toLowerCase() == v.trim().toLowerCase());
                      if (taken) return 'A company with this name is already registered. Use "Join existing" instead.';
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                    maxLength: 100,
                    labelText: l10n.setupCompanyName,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _industry,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l10n.setupIndustryOptional),
                    items: kCompanyIndustries.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => _industry = v),
                  ),
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
                              _locationText ?? l10n.setupLocationOptional,
                              style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: _locationText != null ? AppColors.textPrimary : AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(tr('Company legal documents (required)', ms: 'Dokumen perundangan syarikat (wajib)', zh: '公司法律文件（必填）'), style: AppTextStyles.label),
                  const SizedBox(height: 4),
                  Text(
                    tr('An administrator verifies your company from these, for example the SSM business registration certificate. Until then you can use the app but cannot post internships.',
                        ms: 'Pentadbir mengesahkan syarikat anda berdasarkan dokumen ini, contohnya sijil pendaftaran perniagaan SSM. Sehingga itu anda boleh menggunakan aplikasi tetapi tidak boleh menyiarkan latihan industri.',
                        zh: '管理员会根据这些文件（例如 SSM 商业注册证书）认证您的公司。认证之前您可以使用应用，但无法发布实习职位。'),
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _docs.length; i++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.fromLTRB(12, 2, 2, 2),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                      child: Row(
                        children: [
                          Icon(Icons.description_outlined, size: 18, color: AppColors.primaryText),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_docs[i].name, style: const TextStyle(fontFamily: 'Inter', fontSize: 13), overflow: TextOverflow.ellipsis)),
                          IconButton(icon: const Icon(Icons.close, size: 18), onPressed: _isSubmitting ? null : () => setState(() => _docs.removeAt(i))),
                        ],
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _addDocs,
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: Text(tr('Add document', ms: 'Tambah dokumen', zh: '添加文件')),
                  ),
                  if (_docsError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(_docsError!, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _register,
                      child: _isSubmitting ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(l10n.setupRegisterCompany),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
