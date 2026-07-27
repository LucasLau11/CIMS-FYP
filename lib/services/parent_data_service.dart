import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

/// Real data access for the Parent screens. A parent only ever sees their
/// own linked child (`profiles.child_student_id`, set by admin) — every
/// method here is read-only except submitting the acknowledgement form.
class ParentDataService {
  ParentDataService._();
  static final ParentDataService instance = ParentDataService._();

  final SupabaseClient _client = Supabase.instance.client;

  String get _userId {
    final id = AuthService.instance.currentUserId;
    if (id == null) throw Exception('You must be logged in.');
    return id;
  }

  Future<Map<String, dynamic>?> getChild() async {
    final me = await _client.from('profiles').select('child_student_id').eq('id', _userId).single();
    final childId = me['child_student_id'] as String?;
    if (childId == null) return null;
    return await _client.from('profiles').select('id, full_name, programme, semester, faculty').eq('id', childId).single();
  }

  Future<Map<String, dynamic>?> getChildActiveApplication(String childId) async {
    final rows = await _client
        .from('applications')
        .select('*, internships(company_name, title, duration_months)')
        .eq('student_id', childId)
        .eq('status', 'active')
        .order('applied_at', ascending: false)
        .limit(1);
    final list = List<Map<String, dynamic>>.from(rows);
    return list.isEmpty ? null : list.first;
  }

  Future<List<Map<String, dynamic>>> getChildReports(String childId) async {
    final rows = await _client.from('reports').select().eq('student_id', childId).order('submitted_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>?> getExistingAcknowledgement({required String childId, String? applicationId}) async {
    final rows = applicationId != null
        ? await _client
            .from('acknowledgements')
            .select()
            .eq('student_id', childId)
            .eq('application_id', applicationId)
            .order('signed_at', ascending: false)
            .limit(1)
        : await _client.from('acknowledgements').select().eq('student_id', childId).order('signed_at', ascending: false).limit(1);
    final list = List<Map<String, dynamic>>.from(rows);
    return list.isEmpty ? null : list.first;
  }

  Future<void> submitAcknowledgement({
    required String childId,
    String? applicationId,
    required String parentFullName,
    required String parentIc,
    required String relationship,
  }) async {
    await _client.from('acknowledgements').insert({
      'student_id': childId,
      'parent_id': _userId,
      'application_id': applicationId,
      'parent_full_name': parentFullName.trim(),
      'parent_ic': parentIc.trim(),
      'relationship': relationship,
      'signed_at': DateTime.now().toIso8601String(),
    });
  }
}
