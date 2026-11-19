import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/services/pdf_template_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

/// Saving a template again used to leave the PDF as the previous save made it: the PDF library ignores a second
/// field with a name that is already there, so a field the admin MOVED stayed where it was, and a field the admin
/// REMOVED stayed in the file as a fillable box.
void main() {
  final service = PdfTemplateService.instance;

  Uint8List blankPdf() {
    final document = sf.PdfDocument();
    document.pages.add();
    final bytes = Uint8List.fromList(document.saveSync());
    document.dispose();
    return bytes;
  }

  TemplateField text(String key, double y) => TemplateField(key: key, type: 'text', label: key, x: 0.1, y: y, width: 0.3, height: 0.04);

  /// field name -> top edge (in points)
  Map<String, double> fieldsOf(Uint8List bytes) {
    final document = sf.PdfDocument(inputBytes: bytes);
    try {
      return {for (var i = 0; i < document.form.fields.count; i++) document.form.fields[i].name ?? '': document.form.fields[i].bounds.top};
    } finally {
      document.dispose();
    }
  }

  test('a first save puts every non-signature field into the PDF', () {
    final first = service.embedFields(blankPdf(), [
      text('a', 0.1),
      text('b', 0.2),
      const TemplateField(key: 'sig', type: 'signature', label: 'sig', x: 0.1, y: 0.5, width: 0.2, height: 0.08),
    ]);
    expect(fieldsOf(first).keys, unorderedEquals(['a', 'b']));
  });

  test('saving again removes a removed field and applies a moved one', () {
    final first = service.embedFields(blankPdf(), [text('company_name', 0.1), text('ic', 0.2), text('allowance', 0.3)]);
    final before = fieldsOf(first);
    expect(before.keys, unorderedEquals(['company_name', 'ic', 'allowance']));

    // the admin removes "ic", moves "allowance" down and adds "working_days"
    final second = service.embedFields(
      first,
      [text('company_name', 0.1), text('allowance', 0.5), text('working_days', 0.6)],
      replaceKeys: {'company_name', 'ic', 'allowance'},
    );
    final after = fieldsOf(second);
    expect(after.keys, unorderedEquals(['company_name', 'allowance', 'working_days']), reason: 'the removed field is gone');
    expect(after['allowance']!, greaterThan(before['allowance']! + 50), reason: 'the moved field is at its new place');
  });

  test('saving without any change keeps exactly one box per field', () {
    final first = service.embedFields(blankPdf(), [text('a', 0.1), text('b', 0.2)]);
    final again = service.embedFields(first, [text('a', 0.1), text('b', 0.2)], replaceKeys: {'a', 'b'});
    expect(fieldsOf(again).keys, unorderedEquals(['a', 'b']));
    final document = sf.PdfDocument(inputBytes: again);
    expect(document.form.fields.count, 2);
    document.dispose();
  });
}
