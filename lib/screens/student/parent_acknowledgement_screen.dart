import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../services/document_template_service.dart';
import '../../services/pdf_template_service.dart';
import '../document_preview_screen.dart';
import '../../utils/error_text.dart';

/// Fills in the active 'parent_acknowledgement' document template — a real
/// PDF with fillable fields an admin placed via the template designer.
///
/// The student opens this from their own Documents tab and hands the phone to
/// their parent or guardian, who fills in the text/date fields and draws the
/// signature with a finger. (There are no parent accounts.) Auto fields
/// (student name, programme, company) resolve from the student's details.
/// Submitting stamps everything onto the PDF and flattens it; the submission
/// is recorded under the student's own account.
class ParentAcknowledgementScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String? studentRegNo;
  final String? programme;
  final String? companyName;

  const ParentAcknowledgementScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    this.studentRegNo,
    this.programme,
    this.companyName,
  });

  @override
  State<ParentAcknowledgementScreen> createState() => _ParentAcknowledgementScreenState();
}

class _ParentAcknowledgementScreenState extends State<ParentAcknowledgementScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _loadError;

  Map<String, dynamic>? _template;
  List<TemplateField> _fields = [];
  Uint8List? _preparedPdfBytes;
  List<Uint8List> _pageImages = [];
  double _pageAspectRatio = 1;
  Map<String, dynamic>? _existingSubmission;

  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, DateTime?> _dateValues = {};
  final Map<String, Uint8List?> _signatureValues = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String get _studentId => widget.studentId;

  Future<void> _load() async {
    try {
      final template = await DocumentTemplateService.instance.getActiveTemplate('parent_acknowledgement');
      if (template == null) {
        if (!mounted) return;
        setState(() {
          _loadError = AppLocalizations.of(context)!.parentFormNotConfiguredError;
          _isLoading = false;
        });
        return;
      }

      final fields = (template['fields'] as List).map((f) => TemplateField.fromJson(f as Map<String, dynamic>)).toList();
      final existing = await DocumentTemplateService.instance.getSubmission(templateId: template['id'] as String, studentId: _studentId);
      if (existing != null) {
        if (!mounted) return;
        setState(() {
          _template = template;
          _existingSubmission = existing;
          _isLoading = false;
        });
        return;
      }

      final preparedBytes = await DocumentTemplateService.instance.downloadTemplatePdf(template['storage_path'] as String);
      final pageCount = await PdfTemplateService.instance.getPageCount(preparedBytes);
      final images = <Uint8List>[];
      for (var i = 0; i < pageCount; i++) {
        images.add(await PdfTemplateService.instance.renderPageImage(preparedBytes, pageIndex: i));
      }
      final pageWidth = (template['page_width'] as num).toDouble();
      final pageHeight = (template['page_height'] as num).toDouble();

      for (final f in fields) {
        if (f.type == 'text') _textControllers[f.key] = TextEditingController();
      }

      if (!mounted) return;
      setState(() {
        _template = template;
        _fields = fields;
        _preparedPdfBytes = preparedBytes;
        _pageImages = images;
        _pageAspectRatio = pageWidth / pageHeight;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _showHandoverNotice());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = AppLocalizations.of(context)!.parentCouldNotLoadFormError(friendlyError(e));
        _isLoading = false;
      });
    }
  }

  Future<void> _showHandoverNotice() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.family_restroom_outlined, size: 32, color: AppColors.primaryText),
        title: const Text('Hand the phone to your parent or guardian'),
        content: const Text(
          'This form is signed by your parent or guardian. Give them your phone so they can read it, '
          'fill in their details and sign with their finger. You will see the signed form afterwards.',
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('My parent or guardian has the phone')),
        ],
      ),
    );
  }

  String _resolveAutoValue(String key) {
    switch (key) {
      case 'student_name':
        return widget.studentName;
      case 'student_reg_no':
        return widget.studentRegNo ?? '';
      case 'programme':
        return widget.programme ?? '';
      case 'company_name':
        return widget.companyName ?? '';
      case 'today_date':
        return _formatDate(DateTime.now());
      default:
        return '';
    }
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  bool get _canSubmit {
    for (final f in _fields) {
      switch (f.type) {
        case 'text':
          if ((_textControllers[f.key]?.text.trim().isEmpty ?? true)) return false;
          break;
        case 'date':
          if (_dateValues[f.key] == null) return false;
          break;
        case 'signature':
          if (_signatureValues[f.key] == null) return false;
          break;
      }
    }
    return true;
  }

  Future<void> _pickDate(String key) async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null) setState(() => _dateValues[key] = picked);
  }

  Future<void> _captureSignature(String key) async {
    final controller = SignatureController(penColor: Colors.black, penStrokeWidth: 3, exportBackgroundColor: Colors.transparent);
    final bytes = await showDialog<Uint8List>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(l10n.parentDrawSignatureTitle, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 300,
            height: 180,
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
              child: Signature(controller: controller, backgroundColor: Colors.white),
            ),
          ),
          actions: [
            TextButton(onPressed: controller.clear, child: Text(l10n.clear)),
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: () async {
                if (controller.isEmpty) return;
                final png = await controller.toPngBytes();
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext, png);
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (bytes != null) setState(() => _signatureValues[key] = bytes);
  }

  Future<void> _submit() async {
    if (!_canSubmit || _preparedPdfBytes == null || _template == null) return;
    setState(() => _isSubmitting = true);
    try {
      final values = <String, dynamic>{};
      final textValues = <String, dynamic>{};
      for (final f in _fields) {
        switch (f.type) {
          case 'auto':
            final v = _resolveAutoValue(f.key);
            values[f.key] = v;
            textValues[f.key] = v;
            break;
          case 'text':
            final v = _textControllers[f.key]!.text.trim();
            values[f.key] = v;
            textValues[f.key] = v;
            break;
          case 'date':
            final v = _formatDate(_dateValues[f.key]!);
            values[f.key] = v;
            textValues[f.key] = v;
            break;
          case 'signature':
            values[f.key] = _signatureValues[f.key];
            break;
        }
      }

      final generatedBytes = PdfTemplateService.instance.fillAndFlatten(
        preparedPdfBytes: _preparedPdfBytes!,
        fields: _fields,
        values: values,
      );
      await DocumentTemplateService.instance.submitDocument(
        templateId: _template!['id'] as String,
        studentId: _studentId,
        textValues: textValues,
        generatedPdfBytes: generatedBytes,
      );
      final saved = await DocumentTemplateService.instance.getSubmission(templateId: _template!['id'] as String, studentId: _studentId);
      if (!mounted) return;
      setState(() {
        _existingSubmission = saved;
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.parentCouldNotSubmitError(friendlyError(e))), backgroundColor: AppColors.error));
    }
  }

  Future<void> _viewSubmittedPdf() async {
    final path = _existingSubmission?['generated_pdf_path'] as String?;
    if (path == null) return;
    try {
      final url = await DocumentTemplateService.instance.getSubmissionSignedUrl(path);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentPreviewScreen(url: url, fileName: 'Acknowledgement Form.pdf')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.parentCouldNotOpenFormError(friendlyError(e))), backgroundColor: AppColors.error));
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
        title: Text(l10n.parentAcknowledgementTitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _loadError != null
              ? _buildError(_loadError!)
              : _existingSubmission != null
                  ? _buildSuccessScreen()
                  : _buildFillScreen(),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildFillScreen() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.infoBg,
          padding: const EdgeInsets.all(10),
          child: Text(
            'Parent or guardian: tap each box to fill it in, then tap the signature box and sign.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.primaryText),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (var pageIndex = 0; pageIndex < _pageImages.length; pageIndex++) ...[
                  if (pageIndex > 0) const SizedBox(height: 16),
                  AspectRatio(
                    aspectRatio: _pageAspectRatio,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = constraints.biggest;
                        return Stack(
                          children: [
                            Image.memory(_pageImages[pageIndex], width: size.width, height: size.height, fit: BoxFit.fill),
                            for (final f in _fields.where((f) => f.page == pageIndex)) _buildFieldOverlay(f, size),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSubmit && !_isSubmitting ? _submit : null,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: _isSubmitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(l10n.parentSignAndSubmitButton),
                  ),
                ),
                const SizedBox(height: 8),
                Text(l10n.parentSignatureTimestampNote,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textMuted), textAlign: TextAlign.center),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldOverlay(TemplateField f, Size size) {
    final rect = Rect.fromLTWH(f.x * size.width, f.y * size.height, f.width * size.width, f.height * size.height);
    Widget content;
    switch (f.type) {
      case 'auto':
        content = Container(
          alignment: Alignment.centerLeft,
          child: Text(_resolveAutoValue(f.key), style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
        );
        break;
      case 'text':
        content = TextField(
          controller: _textControllers[f.key],
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.black),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.6),
            hintText: f.label,
            hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 9, color: AppColors.textMuted),
          ),
        );
        break;
      case 'date':
        final selected = _dateValues[f.key];
        content = GestureDetector(
          onTap: () => _pickDate(f.key),
          child: Container(
            color: Colors.white.withValues(alpha: 0.6),
            alignment: Alignment.centerLeft,
            child: Text(
              selected != null ? _formatDate(selected) : f.label,
              style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: selected != null ? Colors.black : AppColors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
        break;
      case 'signature':
        final signature = _signatureValues[f.key];
        content = GestureDetector(
          onTap: () => _captureSignature(f.key),
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: AppColors.primary, width: 1), borderRadius: BorderRadius.circular(4)),
            alignment: Alignment.center,
            child: signature != null
                ? Image.memory(signature, fit: BoxFit.contain)
                : Text(f.label, style: TextStyle(fontFamily: 'Inter', fontSize: 9, color: AppColors.primaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        );
        break;
      default:
        content = const SizedBox.shrink();
    }
    return Positioned(left: rect.left, top: rect.top, width: rect.width, height: rect.height, child: content);
  }

  Widget _buildSuccessScreen() {
    final l10n = AppLocalizations.of(context)!;
    final submittedAt = DateTime.tryParse(_existingSubmission?['submitted_at'] as String? ?? '') ?? DateTime.now();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
              child: Icon(Icons.check_circle_outline, color: AppColors.success, size: 44),
            ),
            const SizedBox(height: 24),
            Text(l10n.parentFormSubmittedTitle, style: AppTextStyles.h2, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(l10n.parentFormSubmittedDescription, style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(l10n.parentSignedOnDate('${submittedAt.day}/${submittedAt.month}/${submittedAt.year}'),
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primaryText)),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _viewSubmittedPdf, icon: const Icon(Icons.picture_as_pdf_outlined, size: 18), label: Text(l10n.parentViewPdfButton))),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: Text(l10n.parentBackToHomeButton))),
          ],
        ),
      ),
    );
  }
}
