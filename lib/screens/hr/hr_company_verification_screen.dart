import 'package:flutter/material.dart';

import '../../services/company_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/company_document_picker.dart';
import '../../utils/error_text.dart';
import '../../utils/format_utils.dart';
import '../../utils/lang.dart';
import '../../widgets/common/shared_widgets.dart';
import '../document_preview_screen.dart';

/// Where an HR person sees whether their company is verified, and adds or removes the legal documents
/// an administrator checks it by. An unverified company cannot post internships.
class HrCompanyVerificationScreen extends StatefulWidget {
  const HrCompanyVerificationScreen({super.key});

  @override
  State<HrCompanyVerificationScreen> createState() => _HrCompanyVerificationScreenState();
}

class _HrCompanyVerificationScreenState extends State<HrCompanyVerificationScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _company;
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final company = await CompanyService.instance.getMyCompany();
      final documents = company == null ? <Map<String, dynamic>>[] : await CompanyService.instance.getCompanyDocuments(company['company_id'] as String);
      if (!mounted) return;
      setState(() {
        _company = company;
        _documents = documents;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _add() async {
    final company = _company;
    if (company == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final result = await pickCompanyDocuments();
    if (result.rejected.isNotEmpty) {
      messenger.showSnackBar(SnackBar(
        content: Text(tr('Not added: ${result.rejected.join(', ')}', ms: 'Tidak ditambah: ${result.rejected.join(', ')}', zh: '未添加：${result.rejected.join('、')}')),
        backgroundColor: AppColors.warning,
      ));
    }
    if (result.accepted.isEmpty) return;
    setState(() => _busy = true);
    try {
      for (final d in result.accepted) {
        await CompanyService.instance.uploadCompanyDocument(
            companyId: company['company_id'] as String, file: d.file, fileName: d.name, sizeBytes: d.size);
      }
      await _load();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.error));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _remove(Map<String, dynamic> doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Remove this document?', ms: 'Buang dokumen ini?', zh: '移除此文件？')),
        content: Text(doc['file_name'] as String),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tt('Cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tt('Remove'), style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await CompanyService.instance.deleteCompanyDocument(doc);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.error));
    }
  }

  Future<void> _view(Map<String, dynamic> doc) async {
    try {
      final url = await CompanyService.instance.getCompanyDocumentUrl(doc['storage_path'] as String);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentPreviewScreen(url: url, fileName: doc['file_name'] as String)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tt('Could not open file')}: ${friendlyError(e)}'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (_company?['status'] as String?) ?? 'pending';
    final verified = status == 'verified';
    final rejected = status == 'rejected';
    final note = _company?['verification_note'] as String?;

    final (Color bg, Color fg, IconData icon, String title, String text) = verified
        ? (
            AppColors.successBg,
            AppColors.success,
            Icons.verified_outlined,
            tr('Your company is verified', ms: 'Syarikat anda telah disahkan', zh: '您的公司已通过认证'),
            tr('You can post internships.', ms: 'Anda boleh menyiarkan latihan industri.', zh: '您可以发布实习职位。'),
          )
        : rejected
            ? (
                AppColors.errorBg,
                AppColors.error,
                Icons.error_outline,
                tr('Your company was not verified', ms: 'Syarikat anda tidak disahkan', zh: '您的公司未通过认证'),
                note ?? '',
              )
            : (
                AppColors.warningBg,
                AppColors.warning,
                Icons.hourglass_top,
                tr('Waiting for verification', ms: 'Menunggu pengesahan', zh: '等待认证'),
                tr('An administrator checks your documents. Until then you cannot post internships.',
                    ms: 'Pentadbir menyemak dokumen anda. Sehingga itu anda tidak boleh menyiarkan latihan industri.',
                    zh: '管理员正在审核您的文件。在此之前，您无法发布实习职位。'),
              );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: tr('Company verification', ms: 'Pengesahan syarikat', zh: '公司认证')),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: TextStyle(color: AppColors.error))))
              : _company == null
                  ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(tr('Your account is not linked to a company yet.', ms: 'Akaun anda belum dipautkan kepada syarikat.', zh: '您的账户尚未关联公司。'))))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(icon, color: fg),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(title, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: fg)),
                                      if (text.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(text, style: TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.4, color: fg)),
                                      ],
                                      if (rejected)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Text(
                                            tr('Upload the correct documents below and your company will be reviewed again.',
                                                ms: 'Muat naik dokumen yang betul di bawah dan syarikat anda akan disemak semula.',
                                                zh: '请在下方上传正确的文件，您的公司将被重新审核。'),
                                            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: fg),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(tr('Legal documents', ms: 'Dokumen perundangan', zh: '法律文件'), style: AppTextStyles.h3),
                          const SizedBox(height: 4),
                          Text(
                            tr('For example your SSM business registration certificate or business licence. PDF, JPG or PNG, up to 10 MB each.',
                                ms: 'Contohnya sijil pendaftaran perniagaan SSM atau lesen perniagaan. PDF, JPG atau PNG, sehingga 10 MB setiap satu.',
                                zh: '例如 SSM 商业注册证书或营业执照。PDF、JPG 或 PNG，每个最大 10 MB。'),
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: 12),
                          if (_documents.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                              child: Text(tr('No documents uploaded yet.', ms: 'Belum ada dokumen dimuat naik.', zh: '尚未上传文件。'), style: AppTextStyles.bodySecondary),
                            ),
                          for (final d in _documents)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                              child: Row(
                                children: [
                                  Icon(Icons.description_outlined, size: 20, color: AppColors.primaryText),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(d['file_name'] as String, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                                        if (d['file_size_bytes'] != null) Text(formatFileSize((d['file_size_bytes'] as num).toInt()), style: AppTextStyles.caption),
                                      ],
                                    ),
                                  ),
                                  IconButton(icon: const Icon(Icons.visibility_outlined, size: 20), onPressed: () => _view(d)),
                                  if (!verified) IconButton(icon: Icon(Icons.delete_outline, size: 20, color: AppColors.error), onPressed: () => _remove(d)),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                          if (!verified)
                            OutlinedButton.icon(
                              onPressed: _busy ? null : _add,
                              icon: _busy
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.upload_file, size: 18),
                              label: Text(tr('Upload document', ms: 'Muat naik dokumen', zh: '上传文件')),
                            ),
                        ],
                      ),
                    ),
    );
  }
}
