import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'pdf_template_service.dart';

/// Generic "upload a PDF, mark fillable spots on it, let users fill it in
/// through the app" system. A [purpose] (e.g. 'parent_acknowledgement')
/// identifies which flow a template belongs to; only one template per
/// purpose is active at a time.
class DocumentTemplateService {
  DocumentTemplateService._();
  static final DocumentTemplateService instance = DocumentTemplateService._();

  final SupabaseClient _client = Supabase.instance.client;

  String get _userId {
    final id = AuthService.instance.currentUserId;
    if (id == null) throw Exception('You must be logged in.');
    return id;
  }

  Future<List<Map<String, dynamic>>> listTemplates() async {
    final rows = await _client.from('document_templates').select().order('created_at', ascending: false);
    final list = List<Map<String, dynamic>>.from(rows);
    // document_templates' PK is template_id, not id -- alias it back so
    // screens can keep reading row['id'].
    for (final r in list) {
      r['id'] = r['template_id'];
    }
    return list;
  }

  Future<Map<String, dynamic>?> getActiveTemplate(String purpose) async {
    final rows = await _client.from('document_templates').select().eq('purpose', purpose).eq('is_active', true).limit(1);
    final list = List<Map<String, dynamic>>.from(rows);
    if (list.isEmpty) return null;
    final row = list.first;
    row['id'] = row['template_id'];
    return row;
  }

  /// Uploads a blank PDF as a new, inactive, fieldless template. Call
  /// [saveTemplateFields] afterward to place fields and activate it.
  Future<String> uploadTemplate({required Uint8List pdfBytes, required String purpose, required String name}) async {
    final pageSize = PdfTemplateService.instance.getPageSize(pdfBytes);
    final inserted = await _client
        .from('document_templates')
        .insert({
          'purpose': purpose,
          'name': name,
          'storage_path': '',
          'page_width': pageSize.width,
          'page_height': pageSize.height,
          'fields': <Map<String, dynamic>>[],
          'created_by': _userId,
        })
        .select()
        .single();
    final templateId = inserted['template_id'] as String;
    final storagePath = 'templates/$templateId.pdf';
    await _client.storage.from('document_templates').uploadBinary(
          storagePath,
          pdfBytes,
          fileOptions: const FileOptions(contentType: 'application/pdf'),
        );
    await _client.from('document_templates').update({'storage_path': storagePath}).eq('template_id', templateId);
    return templateId;
  }

  Future<Uint8List> downloadTemplatePdf(String storagePath) async {
    return await _client.storage.from('document_templates').download(storagePath);
  }

  /// Embeds real fillable fields at [fields]' positions into the template's
  /// PDF, saves it back over the original, then activates this template
  /// (deactivating any previously-active template for the same purpose).
  Future<void> saveTemplateFields({required String templateId, required List<TemplateField> fields}) async {
    final row = await _client.from('document_templates').select().eq('template_id', templateId).single();
    final storagePath = row['storage_path'] as String;
    final originalBytes = await downloadTemplatePdf(storagePath);
    final preparedBytes = PdfTemplateService.instance.embedFields(originalBytes, fields);
    await _client.storage.from('document_templates').uploadBinary(
          storagePath,
          preparedBytes,
          fileOptions: const FileOptions(contentType: 'application/pdf', upsert: true),
        );

    final purpose = row['purpose'] as String;
    await _client.from('document_templates').update({'is_active': false}).eq('purpose', purpose).eq('is_active', true);
    await _client.from('document_templates').update({
      'fields': fields.map((f) => f.toJson()).toList(),
      'is_active': true,
    }).eq('template_id', templateId);
  }

  Future<Map<String, dynamic>?> getSubmission({required String templateId, required String studentId}) async {
    final rows = await _client.from('document_submissions').select().eq('template_id', templateId).eq('student_id', studentId).limit(1);
    final list = List<Map<String, dynamic>>.from(rows);
    return list.isEmpty ? null : list.first;
  }

  /// Uploads the generated (filled + flattened) PDF and records the
  /// submission. [textValues] holds only the typed/auto text values (for
  /// audit/display) — never the signature image bytes.
  Future<void> submitDocument({
    required String templateId,
    required String studentId,
    required Map<String, dynamic> textValues,
    required Uint8List generatedPdfBytes,
  }) async {
    final storagePath = '$_userId/$studentId/$templateId.pdf';
    await _client.storage.from('document_submissions').uploadBinary(
          storagePath,
          generatedPdfBytes,
          fileOptions: const FileOptions(contentType: 'application/pdf'),
        );
    await _client.from('document_submissions').insert({
      'template_id': templateId,
      'student_id': studentId,
      'submitted_by': _userId,
      'values': textValues,
      'generated_pdf_path': storagePath,
    });
  }

  Future<String> getSubmissionSignedUrl(String storagePath) async {
    return await _client.storage.from('document_submissions').createSignedUrl(storagePath, 300);
  }
}
