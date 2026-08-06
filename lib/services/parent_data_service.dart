import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

/// Real data access for the Parent screens. A parent sees only their linked
/// children (`parent_child_links`, approved rows) — most methods here are
/// read-only. The acknowledgement-form flow (`document_templates` /
/// `document_submissions`) is handled by `DocumentTemplateService`, not this
/// file — `parent_acknowledgement_screen.dart` calls that service directly.
/// Requesting a new parent-child link is this file's only write path besides
/// cancelling one.
class ParentDataService {
  ParentDataService._();
  static final ParentDataService instance = ParentDataService._();

  final SupabaseClient _client = Supabase.instance.client;

  String get _userId {
    final id = AuthService.instance.currentUserId;
    if (id == null) throw Exception('You must be logged in.');
    return id;
  }

  /// Flattens a `job_postings` row's `companies` embed back onto the flat
  /// `company_name` key the old denormalized `internships` table used to
  /// expose directly — `title`/`duration_months` are already native
  /// `job_postings` columns so `*` covers those. Mutates and returns [row].
  Map<String, dynamic> _flattenInternship(Map<String, dynamic> row) {
    final company = row['companies'] as Map<String, dynamic>?;
    row['company_name'] = company?['name'];
    return row;
  }

  /// All of this parent's approved children. Reads `v_student_profile`
  /// (profiles + students join) since programme/semester/faculty/
  /// student_reg_no live on `students` now, not on `profiles` directly.
  Future<List<Map<String, dynamic>>> getChildren() async {
    final links = await _client.from('parent_child_links').select('student_id').eq('parent_id', _userId).eq('status', 'approved');
    final childIds = List<Map<String, dynamic>>.from(links).map((l) => l['student_id'] as String).toList();
    if (childIds.isEmpty) return [];
    final rows = await _client
        .from('v_student_profile')
        .select('profile_id, full_name, programme, semester, faculty, student_reg_no')
        .inFilter('profile_id', childIds);
    final list = List<Map<String, dynamic>>.from(rows);
    for (final r in list) {
      r['id'] = r['profile_id'];
    }
    return list;
  }

  /// Looks up a student by their exact registered email, for linking. Only
  /// returns `{id, full_name, programme}` — `v_student_profile` only ever
  /// contains rows for `student`-role profiles, so this can't surface staff
  /// or parent accounts even though `profiles_select_authenticated` is a
  /// blanket `using (true)` policy.
  Future<Map<String, dynamic>?> searchStudentByEmail(String email) async {
    final rows = await _client.from('v_student_profile').select('profile_id, full_name, programme').eq('email', email.trim()).limit(1);
    final list = List<Map<String, dynamic>>.from(rows);
    if (list.isEmpty) return null;
    final row = list.first;
    row['id'] = row['profile_id'];
    return row;
  }

  /// Sends a link request to the given student; they must approve it before
  /// this parent can see any of their data.
  ///
  /// Also notifies the student (`notifications.type = 'parent_link'`,
  /// `related_id` = the new `pc_link_id`) so it shows up in their
  /// notifications with an approve/reject action
  /// (`student_notifications_screen.dart`'s `_respondToParentLink`) — without
  /// this insert the request row exists but the student has no way to
  /// discover it. RLS (`can_notify`'s `'parent_link'` branch) already allows
  /// this cross-user insert once the `parent_child_links` row exists, so no
  /// migration is needed here.
  Future<void> requestParentLink({required String studentId, required String relationship}) async {
    final link = await _client
        .from('parent_child_links')
        .insert({
          'parent_id': _userId,
          'student_id': studentId,
          'relationship': relationship,
        })
        .select('pc_link_id')
        .single();

    try {
      final parentName = await AuthService.instance.getCurrentProfile().then((p) => p?['full_name'] as String?);
      await _client.from('notifications').insert({
        'user_id': studentId,
        'title': 'Parent link request',
        'body': '${(parentName?.isNotEmpty == true) ? parentName : 'A parent'} wants to link as your $relationship.',
        'type': 'parent_link',
        'related_id': link['pc_link_id'],
      });
    } catch (_) {
      // Non-fatal — the link request itself already succeeded; the parent's
      // "My requests" list still shows it even if the notification failed.
    }
  }

  /// All of this parent's link requests (pending/approved/rejected), newest
  /// first, joined with the target student's name for display. The FK on
  /// `parent_child_links.student_id` points at `students`, not `profiles`
  /// directly, so the embed goes through `students` and then nests the
  /// `profiles` embed off `students.profile_id`; the result is re-flattened
  /// onto a `profiles` key so screens don't need to know about the detour.
  Future<List<Map<String, dynamic>>> getMyLinkRequests() async {
    final rows = await _client
        .from('parent_child_links')
        .select('*, students!parent_child_links_student_id_fkey(profiles!students_profile_id_fkey(full_name))')
        .eq('parent_id', _userId)
        .order('requested_at', ascending: false);
    final list = List<Map<String, dynamic>>.from(rows);
    for (final r in list) {
      r['id'] = r['pc_link_id'];
      final student = r['students'] as Map<String, dynamic>?;
      r['profiles'] = student?['profiles'];
    }
    return list;
  }

  /// Withdraws a still-pending request this parent sent.
  ///
  /// Deletes the caller's own still-pending link request (RLS:
  /// `parent_child_links_delete_own_pending`). Once a student has responded
  /// (approved/rejected), the row stands as the consent/audit trail and is
  /// no longer deletable by either side.
  Future<void> cancelLinkRequest(String requestId) async {
    await _client.from('parent_child_links').delete().eq('pc_link_id', requestId).eq('status', 'pending');
  }

  /// The child's most recent application regardless of status, so the
  /// parent can see pending/interview/rejected outcomes, not just an
  /// already-active internship.
  Future<Map<String, dynamic>?> getChildLatestApplication(String childId) async {
    final rows = await _client
        .from('applications')
        .select('*, internships:job_postings(*, companies(name, industry, status))')
        .eq('student_id', childId)
        .order('applied_at', ascending: false)
        .limit(1);
    final list = List<Map<String, dynamic>>.from(rows);
    if (list.isEmpty) return null;
    final application = list.first;
    final internship = application['internships'] as Map<String, dynamic>?;
    if (internship != null) _flattenInternship(internship);
    return application;
  }

  /// Report review status comes from `v_report_with_reviews` — a report has
  /// no status of its own until a supervisor reviews it, so a null
  /// `academic_status` defaults to 'submitted' (matches the old flat
  /// schema's default and `StudentDataService.getMyReports`'s convention).
  Future<List<Map<String, dynamic>>> getChildReports(String childId) async {
    final rows = await _client.from('v_report_with_reviews').select().eq('student_id', childId).order('submitted_at', ascending: false);
    final list = List<Map<String, dynamic>>.from(rows);
    for (final r in list) {
      r['status'] = r['academic_status'] ?? 'submitted';
    }
    return list;
  }

  Future<List<Map<String, dynamic>>> getChildDocuments(String childId) async {
    final rows = await _client.from('documents').select().eq('student_id', childId).order('uploaded_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Evaluation summaries only (average score, no per-criterion breakdown
  /// or written comments) — supervisor feedback text stays private between
  /// the supervisor and the student. `evaluations_select_involved` RLS
  /// already lets an approved parent read the full row (including `scores`/
  /// `comments`), so the restriction here is enforced by only selecting the
  /// summary columns, not by RLS.
  Future<List<Map<String, dynamic>>> getChildEvaluationSummary(String childId) async {
    final rows = await _client
        .from('evaluations')
        .select('evaluation_id, type, average_score, created_at')
        .eq('student_id', childId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }
}
