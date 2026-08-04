import 'dart:typed_data';
import 'dart:ui';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

/// A single fillable spot on a template page. Coordinates are normalized
/// (0..1, relative to page width/height) so the same marker renders
/// correctly at any display resolution.
class TemplateField {
  final String key;
  final String type; // 'auto' | 'text' | 'date' | 'signature'
  final String label;
  final double x;
  final double y;
  final double width;
  final double height;

  const TemplateField({
    required this.key,
    required this.type,
    required this.label,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory TemplateField.fromJson(Map<String, dynamic> json) => TemplateField(
        key: json['key'] as String,
        type: json['type'] as String,
        label: json['label'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'type': type,
        'label': label,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };
}

/// Rasterizes PDF pages for on-screen preview (pdfx), and embeds/fills real
/// AcroForm fields on the actual PDF (syncfusion_flutter_pdf) so the saved
/// file is a genuinely fillable — and, once submitted, flattened — PDF.
class PdfTemplateService {
  PdfTemplateService._();
  static final PdfTemplateService instance = PdfTemplateService._();

  /// Page size in PDF points (72 dpi user-space units).
  Size getPageSize(Uint8List pdfBytes) {
    final document = sf.PdfDocument(inputBytes: pdfBytes);
    try {
      final size = document.pages[0].size;
      return Size(size.width, size.height);
    } finally {
      document.dispose();
    }
  }

  /// Rasterizes page 1 as a PNG for display (admin designer background,
  /// parent fill-in background). [scale] multiplies the page's point size
  /// to control output resolution.
  Future<Uint8List> renderPageImage(Uint8List pdfBytes, {double scale = 2}) async {
    final document = await pdfx.PdfDocument.openData(pdfBytes);
    try {
      final page = await document.getPage(1);
      try {
        final image = await page.render(
          width: page.width * scale,
          height: page.height * scale,
          format: pdfx.PdfPageImageFormat.png,
        );
        return image!.bytes;
      } finally {
        await page.close();
      }
    } finally {
      await document.close();
    }
  }

  /// Adds a real (empty) AcroForm text field to the PDF for every non-signature
  /// field — the 'signature' type isn't a form field, just a remembered spot
  /// to stamp a drawn signature image onto at submission time.
  Uint8List embedFields(Uint8List originalPdfBytes, List<TemplateField> fields) {
    final document = sf.PdfDocument(inputBytes: originalPdfBytes);
    try {
      final page = document.pages[0];
      final pageSize = page.size;
      final font = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 9);
      for (final field in fields) {
        if (field.type == 'signature') continue;
        final bounds = Rect.fromLTWH(
          field.x * pageSize.width,
          field.y * pageSize.height,
          field.width * pageSize.width,
          field.height * pageSize.height,
        );
        document.form.fields.add(sf.PdfTextBoxField(page, field.key, bounds, font: font));
      }
      return document.saveAsBytesSync();
    } finally {
      document.dispose();
    }
  }

  /// Fills in the prepared (already-fillable) template with [values] —
  /// field key -> typed text, or (for 'signature' fields) the drawn
  /// signature PNG bytes — then flattens the form so the result can no
  /// longer be edited, and stamps signature images directly onto the page.
  Uint8List fillAndFlatten({
    required Uint8List preparedPdfBytes,
    required List<TemplateField> fields,
    required Map<String, dynamic> values,
  }) {
    final document = sf.PdfDocument(inputBytes: preparedPdfBytes);
    try {
      final page = document.pages[0];
      final pageSize = page.size;

      for (final field in fields) {
        if (field.type != 'signature') continue;
        final signatureBytes = values[field.key] as Uint8List?;
        if (signatureBytes == null) continue;
        final bounds = Rect.fromLTWH(
          field.x * pageSize.width,
          field.y * pageSize.height,
          field.width * pageSize.width,
          field.height * pageSize.height,
        );
        page.graphics.drawImage(sf.PdfBitmap(signatureBytes), bounds);
      }

      final form = document.form;
      for (int i = 0; i < form.fields.count; i++) {
        final formField = form.fields[i];
        if (formField is sf.PdfTextBoxField) {
          final value = values[formField.name] as String?;
          if (value != null) formField.text = value;
        }
      }
      form.flattenAllFields();

      return document.saveAsBytesSync();
    } finally {
      document.dispose();
    }
  }
}
