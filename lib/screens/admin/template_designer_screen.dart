import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/document_template_service.dart';
import '../../services/pdf_template_service.dart';

/// Known fields the app can resolve automatically at fill time (see
/// parent_acknowledgement_screen.dart's `_resolveAutoValue`). Admin picks
/// one of these for 'auto' markers instead of typing a free-form key, so
/// the fill screen and the designer always agree on the vocabulary.
const Map<String, String> kAutoFieldOptions = {
  'student_name': 'Student Name',
  'student_reg_no': 'Student Reg. No.',
  'programme': 'Programme',
  'company_name': 'Company Name',
  'today_date': "Today's Date",
};

const Map<String, String> _typeLabels = {
  'auto': 'Auto-filled',
  'text': 'Typed by user',
  'date': 'Date',
  'signature': 'Signature',
};

Size _defaultFieldSize(String type) => type == 'signature' ? const Size(0.22, 0.09) : const Size(0.30, 0.035);

String _slugify(String label) {
  final slug = label.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  return slug.isEmpty ? 'field' : slug;
}

/// Lets an admin tap on a rendered PDF page to drop fillable field markers
/// (auto-filled / typed / date / signature), then embeds real AcroForm
/// fields into the PDF and activates it for its purpose.
class TemplateDesignerScreen extends StatefulWidget {
  final String templateId;

  const TemplateDesignerScreen({super.key, required this.templateId});

  @override
  State<TemplateDesignerScreen> createState() => _TemplateDesignerScreenState();
}

class _TemplateDesignerScreenState extends State<TemplateDesignerScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  Uint8List? _pageImage;
  double _pageAspectRatio = 1;
  List<TemplateField> _fields = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final templates = await DocumentTemplateService.instance.listTemplates();
      final template = templates.firstWhere((t) => t['id'] == widget.templateId);
      final storagePath = template['storage_path'] as String;
      final pdfBytes = await DocumentTemplateService.instance.downloadTemplatePdf(storagePath);
      final image = await PdfTemplateService.instance.renderPageImage(pdfBytes);
      final pageWidth = (template['page_width'] as num).toDouble();
      final pageHeight = (template['page_height'] as num).toDouble();
      final existingFields = (template['fields'] as List).map((f) => TemplateField.fromJson(f as Map<String, dynamic>)).toList();
      if (!mounted) return;
      setState(() {
        _pageImage = image;
        _pageAspectRatio = pageWidth / pageHeight;
        _fields = existingFields;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load template: $e'), backgroundColor: AppColors.error));
    }
  }

  Set<String> get _usedKeys => _fields.map((f) => f.key).toSet();

  Future<void> _addFieldAt(double normX, double normY) async {
    final spec = await _showFieldTypeSheet();
    if (spec == null) return;
    final size = _defaultFieldSize(spec.type);
    setState(() {
      _fields = [
        ..._fields,
        TemplateField(
          key: spec.key,
          type: spec.type,
          label: spec.label,
          x: (normX - size.width / 2).clamp(0, 1 - size.width),
          y: (normY - size.height / 2).clamp(0, 1 - size.height),
          width: size.width,
          height: size.height,
        ),
      ];
    });
  }

  void _moveField(int index, double dNormX, double dNormY) {
    final field = _fields[index];
    setState(() {
      _fields = [
        ..._fields.sublist(0, index),
        TemplateField(
          key: field.key,
          type: field.type,
          label: field.label,
          x: (field.x + dNormX).clamp(0, 1 - field.width),
          y: (field.y + dNormY).clamp(0, 1 - field.height),
          width: field.width,
          height: field.height,
        ),
        ..._fields.sublist(index + 1),
      ];
    });
  }

  Future<void> _removeFieldAt(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove field?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text('Remove "${_fields[index].label}" from this template.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text('Remove', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _fields = [..._fields]..removeAt(index));
  }

  Future<_FieldSpec?> _showFieldTypeSheet() async {
    String type = 'auto';
    String? autoKey = kAutoFieldOptions.keys.first;
    final labelController = TextEditingController();

    return showModalBottomSheet<_FieldSpec>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add field', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    children: _typeLabels.entries.map((entry) {
                      return ChoiceChip(
                        label: Text(entry.value),
                        selected: type == entry.key,
                        onSelected: (_) => setSheetState(() => type = entry.key),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  if (type == 'auto') ...[
                    Text('Field', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: autoKey,
                      items: kAutoFieldOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (val) => setSheetState(() => autoKey = val),
                    ),
                  ] else ...[
                    Text('Label', style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: labelController,
                      decoration: InputDecoration(hintText: type == 'signature' ? 'e.g. Parent Signature' : 'e.g. Parent Full Name'),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (type == 'auto') {
                          Navigator.pop(sheetContext, _FieldSpec(key: autoKey!, type: 'auto', label: kAutoFieldOptions[autoKey]!));
                          return;
                        }
                        final label = labelController.text.trim();
                        if (label.isEmpty) return;
                        var key = _slugify(label);
                        var suffix = 2;
                        while (_usedKeys.contains(key)) {
                          key = '${_slugify(label)}_$suffix';
                          suffix++;
                        }
                        Navigator.pop(sheetContext, _FieldSpec(key: key, type: type, label: label));
                      },
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _save() async {
    if (_fields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Add at least one field before saving.'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await DocumentTemplateService.instance.saveTemplateFields(templateId: widget.templateId, fields: _fields);
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Template saved and activated.'), backgroundColor: AppColors.primary),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Place fillable fields', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading || _pageImage == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  color: AppColors.primary.withValues(alpha: 0.15),
                  padding: const EdgeInsets.all(10),
                  child: const Text(
                    'Tap anywhere on the page to add a field. Drag a field to reposition it, tap it to remove it.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: AspectRatio(
                        aspectRatio: _pageAspectRatio,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final size = constraints.biggest;
                            return GestureDetector(
                              onTapUp: (details) => _addFieldAt(
                                (details.localPosition.dx / size.width).clamp(0, 1),
                                (details.localPosition.dy / size.height).clamp(0, 1),
                              ),
                              child: Stack(
                                children: [
                                  Image.memory(_pageImage!, width: size.width, height: size.height, fit: BoxFit.fill),
                                  for (int i = 0; i < _fields.length; i++)
                                    Positioned(
                                      left: _fields[i].x * size.width,
                                      top: _fields[i].y * size.height,
                                      width: _fields[i].width * size.width,
                                      height: _fields[i].height * size.height,
                                      child: GestureDetector(
                                        onTap: () => _removeFieldAt(i),
                                        onPanUpdate: (details) => _moveField(i, details.delta.dx / size.width, details.delta.dy / size.height),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.25),
                                            border: Border.all(color: AppColors.primary, width: 1.5),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            _fields[i].label,
                                            style: const TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _FieldSpec {
  final String key;
  final String type;
  final String label;
  const _FieldSpec({required this.key, required this.type, required this.label});
}
