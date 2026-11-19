import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/document_template_service.dart';
import 'template_designer_screen.dart';
import '../../utils/error_text.dart';
import '../../utils/lang.dart';

/// Admin entry point for the generic fillable-PDF-template system: upload a
/// blank PDF, then place fillable field markers on it via
/// [TemplateDesignerScreen]. [purpose] identifies which app flow consumes a
/// given template — it's matched by exact string against
/// `DocumentTemplateService.getActiveTemplate(purpose)`'s caller (currently
/// only `parent_acknowledgement_screen.dart`, which looks up
/// 'parent_acknowledgement'), so it must be picked from [kTemplatePurposes]
/// rather than freely typed — a human-readable description here (or any
/// other typo) silently breaks the consuming screen with no error, since
/// "no active template for this purpose" and "purpose string doesn't
/// match" look identical from the query's side.
const Map<String, String> kTemplatePurposes = {
  'parent_acknowledgement': 'Parent Acknowledgement Form',
  'indemnity_letter': 'Indemnity Letter',
  'company_acceptance_letter': 'Company Acceptance Letter',
};

class AdminDocumentTemplatesScreen extends StatefulWidget {
  const AdminDocumentTemplatesScreen({super.key});

  @override
  State<AdminDocumentTemplatesScreen> createState() =>
      _AdminDocumentTemplatesScreenState();
}

class _AdminDocumentTemplatesScreenState
    extends State<AdminDocumentTemplatesScreen> {
  bool _isLoading = true;
  bool _isUploading = false;
  List<Map<String, dynamic>> _templates = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final templates = await DocumentTemplateService.instance.listTemplates();
      if (!mounted) return;
      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<_TemplateInfo?> _promptTemplateInfo() {
    final nameController = TextEditingController();
    String purpose = kTemplatePurposes.keys.first;
    return showDialog<_TemplateInfo>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text(
            'New template',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: tt('Name'),
                    hintText: 'e.g. Parent Acknowledgement Form',
                  ),
                ),
                const SizedBox(height: 12),
                // Fixed set, not free text — `purpose` is matched by exact
                // string against the one screen that consumes it
                // (getActiveTemplate('parent_acknowledgement')); a typo or a
                // human-readable description here used to fail silently with
                // no error anywhere, since the consuming screen just sees "no
                // active template" either way.
                DropdownButtonFormField<String>(
                  initialValue: purpose,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: tt('Used for')),
                  items: kTemplatePurposes.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setDialogState(() => purpose = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(tt('Cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(
                  dialogContext,
                  _TemplateInfo(
                    name: nameController.text.trim(),
                    purpose: purpose,
                  ),
                );
              },
              child: Text(tt('Continue')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDesigner(Map<String, dynamic> t) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => TemplateDesignerScreen(templateId: t['id'] as String)));
    _load();
  }

  void _toast(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: error ? AppColors.error : AppColors.primary));
  }

  /// Rename a template and/or change what it is used for.
  Future<void> _editDetails(Map<String, dynamic> t) async {
    final nameController = TextEditingController(text: t['name'] as String);
    String purpose = kTemplatePurposes.containsKey(t['purpose']) ? t['purpose'] as String : kTemplatePurposes.keys.first;
    final isActive = t['is_active'] == true;
    final result = await showDialog<_TemplateInfo>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(tr('Edit template', ms: 'Sunting templat', zh: '编辑模板'), style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: InputDecoration(labelText: tt('Name'))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: purpose,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: tt('Used for')),
                  items: kTemplatePurposes.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) => setDialogState(() => purpose = val!),
                ),
                if (isActive && purpose != t['purpose']) ...[
                  const SizedBox(height: 10),
                  Text(
                      tr('This template stays in use for its new purpose and replaces the one in use there. Nothing will be in use for the old purpose until you switch another template on.',
                          ms: 'Templat ini terus digunakan untuk tujuan baharu dan menggantikan yang sedang digunakan di situ. Tiada templat digunakan untuk tujuan lama sehingga anda menghidupkan templat lain.',
                          zh: '此模板将继续用于新的用途，并取代该用途下正在使用的模板。在您启用另一个模板之前，原用途将没有可用模板。'),
                      style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(tt('Cancel'))),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(dialogContext, _TemplateInfo(name: nameController.text.trim(), purpose: purpose));
              },
              child: Text(tt('Save')),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    if (result == null) return;
    try {
      await DocumentTemplateService.instance.updateTemplate(templateId: t['id'] as String, name: result.name, purpose: result.purpose);
      _toast(tr('Template updated.', ms: 'Templat dikemas kini.', zh: '模板已更新。'));
      _load();
    } catch (e) {
      _toast('${tr('Could not update the template', ms: 'Tidak dapat mengemas kini templat', zh: '无法更新模板')}: ${friendlyError(e)}', error: true);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> t) async {
    final makeActive = t['is_active'] != true;
    try {
      await DocumentTemplateService.instance.setTemplateActive(templateId: t['id'] as String, active: makeActive);
      _toast(makeActive
          ? tr('Template switched on.', ms: 'Templat dihidupkan.', zh: '模板已启用。')
          : tr('Template switched off.', ms: 'Templat dimatikan.', zh: '模板已停用。'));
      _load();
    } catch (e) {
      _toast(friendlyError(e), error: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> t) async {
    final isActive = t['is_active'] == true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('Delete this template?', ms: 'Padam templat ini?', zh: '删除此模板？'), style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text(
          '"${t['name']}" ${tr('and its PDF will be deleted for good.', ms: 'dan PDF-nya akan dipadam selama-lamanya.', zh: '及其 PDF 将被永久删除。')}'
          '${isActive ? '\n\n${tr('It is the template in use, so nobody can fill this form until you switch another one on.', ms: 'Ia ialah templat yang sedang digunakan, jadi tiada sesiapa boleh mengisi borang ini sehingga anda menghidupkan templat lain.', zh: '它是正在使用的模板，在您启用另一个模板之前，没有人可以填写此表格。')}' : ''}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(tt('Cancel'))),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(tr('Delete', ms: 'Padam', zh: '删除'), style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await DocumentTemplateService.instance.deleteTemplate(t['id'] as String);
      _toast(tr('Template deleted.', ms: 'Templat dipadam.', zh: '模板已删除。'));
      _load();
    } catch (e) {
      _toast(friendlyError(e), error: true);
    }
  }

  Future<void> _uploadTemplate() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) return;

    if (!mounted) return;
    final info = await _promptTemplateInfo();
    if (info == null) return;

    setState(() => _isUploading = true);
    try {
      final templateId = await DocumentTemplateService.instance.uploadTemplate(
        pdfBytes: bytes,
        purpose: info.purpose,
        name: info.name,
      );
      if (!mounted) return;
      setState(() => _isUploading = false);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TemplateDesignerScreen(templateId: templateId),
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${tt('Could not upload template')}: ${friendlyError(e)}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Document Templates',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _uploadTemplate,
        icon: _isUploading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.upload_file),
        label: Text(tt('Upload template')),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _templates.isEmpty
          ? EmptyState(
              icon: Icons.description_outlined,
              title: tt('No templates yet'),
              description:
                  "Upload a PDF and mark where people should fill things in — it becomes a real fillable form used through the app.",
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _templates.length,
                itemBuilder: (context, index) {
                  final t = _templates[index];
                  final isActive = t['is_active'] == true;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AccentCard(
                      accentColor: isActive
                          ? AppColors.success
                          : AppColors.textMuted,
                      onTap: () => _openDesigner(t),
                      child: Row(
                        children: [
                          Icon(
                            Icons.picture_as_pdf_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t['name'] as String,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Purpose: ${t['purpose']}',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          isActive
                              ? StatusBadge.active(context)
                              : StatusBadge.pending(context),
                          PopupMenuButton<String>(
                            tooltip: tr('Template options', ms: 'Pilihan templat', zh: '模板选项'),
                            onSelected: (value) {
                              switch (value) {
                                case 'fields':
                                  _openDesigner(t);
                                  break;
                                case 'details':
                                  _editDetails(t);
                                  break;
                                case 'active':
                                  _toggleActive(t);
                                  break;
                                case 'delete':
                                  _delete(t);
                                  break;
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'fields', child: Text(tr('Edit fields', ms: 'Sunting medan', zh: '编辑字段'))),
                              PopupMenuItem(value: 'details', child: Text(tr('Rename or change use', ms: 'Tukar nama atau kegunaan', zh: '重命名或更改用途'))),
                              PopupMenuItem(
                                value: 'active',
                                child: Text(isActive
                                    ? tr('Switch off', ms: 'Matikan', zh: '停用')
                                    : tr('Switch on', ms: 'Hidupkan', zh: '启用')),
                              ),
                              PopupMenuItem(value: 'delete', child: Text(tr('Delete', ms: 'Padam', zh: '删除'), style: TextStyle(color: AppColors.error))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _TemplateInfo {
  final String name;
  final String purpose;
  const _TemplateInfo({required this.name, required this.purpose});
}
