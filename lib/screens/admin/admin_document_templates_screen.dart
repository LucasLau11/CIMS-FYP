import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/document_template_service.dart';
import 'template_designer_screen.dart';

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
                  decoration: const InputDecoration(
                    labelText: 'Name',
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
                  decoration: const InputDecoration(labelText: 'Used for'),
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
              child: const Text('Cancel'),
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
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
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
          content: Text('Could not upload template: $e'),
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
        label: const Text('Upload template'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _templates.isEmpty
          ? const EmptyState(
              icon: Icons.description_outlined,
              title: 'No templates yet',
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
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TemplateDesignerScreen(
                              templateId: t['id'] as String,
                            ),
                          ),
                        );
                        _load();
                      },
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
