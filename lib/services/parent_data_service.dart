import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

/// Real data access for the Parent screens. A parent sees only their linked
/// children (`parent_child_links`, approved rows) — most methods here are
/// read-only except submitting the acknowledgement form and requesting a
/// new parent-child link.
class ParentDataService {
  ParentDataService._();
  static final ParentDataService instance = ParentDataService._();

  final SupabaseClient _client = Supabase.instance.client;

  String get _userId {
    final id = AuthService.instance.currentUserId;
    if (id == null) throw Exception('You must be logged in.');
    return id;
  }

  /// All of this parent's approved children.
  Future<List<Map<String, dynamic>>> getChildren() async {
    final links = await _client.from('parent_child_links').select('student_id').eq('parent_id', _userId).eq('status', 'approved');
    final childIds = List<Map<String, dynamic>>.from(links).map((l) => l['student_id'] as String).toList();
    if (childIds.isEmpty) return [];
    final rows = await _client.from('profiles').select('id, full_name, programme, semester, faculty, student_reg_no').inFilter('id', childIds);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Looks up a student by their exact registered email, for linking. Only
  /// returns `{id, full_name, programme}` — never a general directory.
  Future<Map<String, dynamic>?> searchStudentByEmail(String email) async {
    final rows = await _client.rpc('find_student_for_parent_link', params: {'p_email': email.trim()});
    final list = List<Map<String, dynamic>>.from(rows as List);
    return list.isEmpty ? null : list.first;
  }

  /// Sends a link request to the given student; they must approve it before
  /// this parent can see any of their data.
  Future<void> requestParentLink({required String studentId, required String relationship}) async {
    await _client.from('parent_child_links').insert({
      'parent_id': _userId,
      'student_id': studentId,
      'relationship': relationship,
    });
  }

  /// All of this parent's link requests (pending/approved/rejected), newest
  /// first, joined with the target student's name for display.
  Future<List<Map<String, dynamic>>> getMyLinkRequests() async {
    final rows = await _client
        .from('parent_child_links')
        .select('*, profiles!parent_child_links_student_id_fkey(full_name)')
        .eq('parent_id', _userId)
        .order('requested_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Withdraws a still-pending request this parent sent.
  Future<void> cancelLinkRequest(String requestId) async {
    await _client.from('parent_child_links').delete().eq('id', requestId).eq('status', 'pending');
  }

  /// The child's most recent application regardless of status, so the
  /// parent can see pending/interview/rejected outcomes, not just an
  /// already-active internship.
  Future<Map<String, dynamic>?> getChildLatestApplication(String childId) async {
    final rows = await _client
        .from('applications')
        .select('*, internships(company_name, title, duration_months)')
        .eq('student_id', childId)
        .order('applied_at', ascending: false)
        .limit(1);
    final list = List<Map<String, dynamic>>.from(rows);
    return list.isEmpty ? null : list.first;
  }

  Future<List<Map<String, dynamic>>> getChildReports(String childId) async {
    final rows = await _client.from('reports').select().eq('student_id', childId).order('submitted_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> getChildDocuments(String childId) async {
    final rows = await _client.from('documents').select().eq('student_id', childId).order('uploaded_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Evaluation summaries only (average score, no per-criterion breakdown
  /// or written comments) via a restricted RPC — supervisor feedback text
  /// stays private between the supervisor and the student.
  Future<List<Map<String, dynamic>>> getChildEvaluationSummary(String childId) async {
    final rows = await _client.rpc('get_child_evaluation_summary', params: {'p_student_id': childId});
    return List<Map<String, dynamic>>.from(rows as List);
  }

}
