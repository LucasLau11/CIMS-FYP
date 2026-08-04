import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

/// Real data access for the academic supervisor screens. Same singleton +
/// "throw Exception with a user-facing message" style as [AuthService] and
/// [StudentDataService]. Messaging is intentionally NOT duplicated here —
/// conversations/messages are role-agnostic (keyed by the current user's
/// id, not their role), so supervisor screens call StudentDataService's
/// messaging methods directly instead of a second copy of the same logic.
///
/// Normalized-schema notes (Task 15):
/// - "My students" is now a real assignment: `students.academic_supervisor_id`
///   (previously this method ignored assignment entirely and returned every
///   student profile — that was written before the admin module's
///   assign-a-supervisor feature existed; that feature is live now via
///   `academic_supervisor_id`, just still on the admin side's old
///   `profiles.academic_supervisor_id` pending its own migration). Admin
///   callers (admin_monitor_screen) still need to see every student, so the
///   roster queries below are role-aware: admin gets everyone, an academic
///   supervisor gets only their assigned students.
/// - `internships` is now `job_postings`, joined to `companies` for
///   `company_name` (used to be a denormalized flat column).
/// - Report review status/feedback comes from `v_report_with_reviews`
///   (`academic_status`/`academic_feedback`/`company_status`/
///   `company_feedback`), not flat columns on `reports`. Writing a review
///   goes to `academic_report_reviews` (this supervisor's verdict) or
///   `company_report_reviews` (the company supervisor's first-stage
///   verdict) — never to `reports` itself, which has no supervisor-writable
///   column and only a student-only self-update policy.
/// - Document status is still a native column on `documents` (approve/
///   reject writes there, via `documents_update_supervisor`), but feedback
///   is split out to `document_reviews`. Reading merges both via
///   `v_document_with_review`; reviewing writes to both tables.
/// - Every table's primary key is now `<table_singular>_id` instead of
///   `id`. Screens still read `['id']` off returned maps, so an `id` alias
///   is added back onto each row before returning it.
class SupervisorDataService {
  SupervisorDataService._();
  static final SupervisorDataService instance = SupervisorDataService._();

  final SupabaseClient _client = Supabase.instance.client;

  String get _userId {
    final id = AuthService.instance.currentUserId;
    if (id == null) throw Exception('You must be logged in.');
    return id;
  }

  Future<String> _currentRole() async {
    final row = await _client.from('profiles').select('role').eq('profile_id', _userId).single();
    return row['role'] as String;
  }

  // ---------------------------------------------------------------------
  // Students
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getStudents() async {
    final role = await _currentRole();
    final query = _client.from('students').select('profile_id, programme, semester, faculty, profiles(full_name)');
    final students = role == 'admin' ? await query : await query.eq('academic_supervisor_id', _userId);
    final studentList = List<Map<String, dynamic>>.from(students);
    if (studentList.isEmpty) return [];
    final studentIds = studentList.map((s) => s['profile_id'] as String).toList();

    final applications = await _client
        .from('applications')
        .select('student_id, status, applied_at, job_postings(companies(name))')
        .inFilter('student_id', studentIds)
        .order('applied_at', ascending: false);
    final applicationList = List<Map<String, dynamic>>.from(applications);

    final reports = await _client
        .from('v_report_with_reviews')
        .select('student_id, academic_status, submitted_at')
        .inFilter('student_id', studentIds)
        .order('submitted_at', ascending: false);
    final reportList = List<Map<String, dynamic>>.from(reports);

    final documents = await _client
        .from('documents')
        .select('student_id, status')
        .inFilter('student_id', studentIds);
    final documentList = List<Map<String, dynamic>>.from(documents);

    final result = studentList.map((student) {
      final id = student['profile_id'] as String;
      final profile = student['profiles'] as Map<String, dynamic>?;
      final myApplications = applicationList.where((a) => a['student_id'] == id).toList();
      final activeApplications = myApplications.where((a) => a['status'] == 'active').toList();
      final hasActiveInternship = activeApplications.isNotEmpty;
      String? companyName;
      if (hasActiveInternship) {
        final jobPosting = activeApplications.first['job_postings'] as Map?;
        final company = jobPosting?['companies'] as Map?;
        companyName = company?['name'] as String?;
      }
      final myReports = reportList.where((r) => r['student_id'] == id).toList();
      // academic_status is null until a supervisor has ever reviewed this
      // report — treat that as still pending, same as the student-facing
      // getMyReports() default.
      final pendingReports = myReports.where((r) => (r['academic_status'] as String?) == null || r['academic_status'] == 'submitted').length;
      final pendingDocuments =
          documentList.where((d) => d['student_id'] == id && d['status'] == 'submitted').length;

      return {
        'id': id,
        'profile_id': id,
        'full_name': profile?['full_name'],
        'programme': student['programme'],
        'semester': student['semester'],
        'faculty': student['faculty'],
        'company_name': companyName,
        'has_active_internship': hasActiveInternship,
        'last_report_at': myReports.isEmpty ? null : myReports.first['submitted_at'],
        'pending_review_count': pendingReports + pendingDocuments,
        'report_count': myReports.length,
      };
    }).toList();

    result.sort((a, b) => ((a['full_name'] as String?) ?? '').compareTo((b['full_name'] as String?) ?? ''));
    return result;
  }

  Future<List<Map<String, dynamic>>> getStudentReports(String studentId) async {
    final rows = await _client
        .from('v_report_with_reviews')
        .select()
        .eq('student_id', studentId)
        .order('submitted_at', ascending: false);
    final list = List<Map<String, dynamic>>.from(rows);
    for (final r in list) {
      r['id'] = r['report_id'];
      r['status'] = r['academic_status'] ?? 'submitted';
      r['feedback'] = r['academic_feedback'];
      r['company_review_status'] = r['company_status'];
    }
    return list;
  }

  Future<List<Map<String, dynamic>>> getStudentDocuments(String studentId) async {
    final rows = await _client
        .from('v_document_with_review')
        .select()
        .eq('student_id', studentId)
        .order('uploaded_at', ascending: false);
    final list = List<Map<String, dynamic>>.from(rows);
    for (final d in list) {
      d['id'] = d['document_id'];
      d['feedback'] = d['review_feedback'];
    }
    return list;
  }

  Future<List<Map<String, dynamic>>> getStudentEvaluations(String studentId) async {
    final rows = await _client
        .from('evaluations')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false);
    final list = List<Map<String, dynamic>>.from(rows);
    for (final e in list) {
      e['id'] = e['evaluation_id'];
    }
    return list;
  }

  // ---------------------------------------------------------------------
  // Reviews (reports + documents merged into one feed)
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getAllReviewItems() async {
    // RLS (reports_select_involved / documents_select_involved) already
    // scopes these to "admin sees everything" / "academic supervisor sees
    // only their assigned students' rows" — no explicit student-id filter
    // needed here.
    final reports = await _client.from('v_report_with_reviews').select().order('submitted_at', ascending: false);
    final documents = await _client.from('v_document_with_review').select().order('uploaded_at', ascending: false);
    final reportList = List<Map<String, dynamic>>.from(reports);
    final documentList = List<Map<String, dynamic>>.from(documents);

    final studentIds = {...reportList.map((r) => r['student_id'] as String), ...documentList.map((d) => d['student_id'] as String)};
    final names = <String, String>{};
    if (studentIds.isNotEmpty) {
      final profiles = await _client.from('profile_directory').select().inFilter('profile_id', studentIds.toList());
      for (final p in List<Map<String, dynamic>>.from(profiles)) {
        names[p['profile_id'] as String] = (p['full_name'] as String?)?.isNotEmpty == true ? p['full_name'] as String : 'Unknown student';
      }
    }

    final reportItems = reportList.map((r) => {
          'kind': 'report',
          'id': r['report_id'],
          'student_id': r['student_id'],
          'student_name': names[r['student_id']] ?? 'Unknown student',
          'title': '${r['type'] == 'final' ? 'Final Report' : 'Monthly Report'} — ${r['period_label']}',
          'submitted_at': r['submitted_at'],
          'status': r['academic_status'] ?? 'submitted',
          'feedback': r['academic_feedback'],
          'storage_path': r['storage_path'],
          'file_name': r['file_name'],
          // Two-stage approval: company supervisor reviews first, academic
          // supervisor/admin's Approve/Reject on `status` above is only
          // meaningful once this is 'approved'.
          'company_review_status': r['company_status'],
          'company_feedback': r['company_feedback'],
        });
    final documentItems = documentList.map((d) => {
          'kind': 'document',
          'id': d['document_id'],
          'student_id': d['student_id'],
          'student_name': names[d['student_id']] ?? 'Unknown student',
          'title': d['title'] ?? _categoryLabel(d['category'] as String),
          'submitted_at': d['uploaded_at'],
          'status': d['status'],
          'feedback': d['review_feedback'],
          'storage_path': d['storage_path'],
          'file_name': d['file_name'],
        });

    final all = [...reportItems, ...documentItems];
    all.sort((a, b) => (b['submitted_at'] as String).compareTo(a['submitted_at'] as String));
    return all;
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'offer_letter':
        return 'Offer Letter';
      case 'indemnity_letter':
        return 'Indemnity Letter';
      case 'company_acceptance_letter':
        return 'Company Acceptance Letter';
      case 'insurance_certificate':
        return 'Insurance Certificate';
      default:
        return 'Document';
    }
  }

  Future<void> reviewReport({required String reportId, required String status, String? feedback}) async {
    await _client.from('academic_report_reviews').upsert({
      'report_id': reportId,
      'status': status,
      'feedback': feedback,
      'reviewer_id': _userId,
      'reviewed_at': DateTime.now().toIso8601String(),
    }, onConflict: 'report_id');
  }

  /// The company supervisor's half of the two-stage report approval —
  /// separate from [reviewReport] (the academic supervisor/admin's final
  /// say) so the two reviewer roles never clobber each other's decision.
  /// Writes to `company_report_reviews`, not `academic_report_reviews`.
  Future<void> reviewReportAsCompanySupervisor({required String reportId, required String status, String? feedback}) async {
    await _client.from('company_report_reviews').upsert({
      'report_id': reportId,
      'status': status,
      'feedback': feedback,
      'reviewer_id': _userId,
      'reviewed_at': DateTime.now().toIso8601String(),
    }, onConflict: 'report_id');
  }

  /// Approve/reject writes `documents.status` directly (that column stayed
  /// on `documents` in the normalized schema, gated by
  /// `documents_update_supervisor`); the accompanying feedback/reviewer/
  /// timestamp goes to the separate `document_reviews` row (unique per
  /// document, upserted here so re-reviewing replaces rather than
  /// duplicates it).
  ///
  /// NOTE: `document_reviews`'s RLS (`can_manage_document_review`) and
  /// `documents_update_supervisor`'s USING clause only recognize
  /// admin/academic-supervisor — company_supervisor is not covered. A
  /// company supervisor calling this (via CompanySupervisorDataService,
  /// which forwards straight to this method) will see both writes silently
  /// affect 0 rows under RLS. See task-15 report for detail — that's an
  /// existing gap in company_supervisor_data_service.dart's own migration,
  /// out of this file's scope to fix.
  Future<void> reviewDocument({required String documentId, required String status, String? feedback}) async {
    final now = DateTime.now().toIso8601String();

    // These two writes aren't atomic (no single-statement path covers both
    // tables), so if the second one fails after the first succeeded, we'd be
    // left with a changed documents.status and no matching review row —
    // worse than the old single-UPDATE behavior. Read the prior status first
    // so a failed second write can be compensated for by reverting the
    // first, and always surface a clear exception rather than letting the
    // caller believe the review fully succeeded.
    String? previousStatus;
    try {
      final before = await _client.from('documents').select('status').eq('document_id', documentId).single();
      previousStatus = before['status'] as String?;
    } catch (_) {
      // Couldn't read the prior status (e.g. row already gone) — proceed
      // without a revert target rather than blocking the review on a read.
    }

    await _client.from('documents').update({'status': status}).eq('document_id', documentId);
    try {
      await _client.from('document_reviews').upsert({
        'document_id': documentId,
        'feedback': feedback,
        'reviewer_id': _userId,
        'reviewed_at': now,
      }, onConflict: 'document_id');
    } catch (e) {
      if (previousStatus != null) {
        try {
          await _client.from('documents').update({'status': previousStatus}).eq('document_id', documentId);
        } catch (_) {
          // Best-effort revert; if this also fails there's nothing more we
          // can safely do client-side.
        }
      }
      throw Exception('Could not save the review feedback (${e.toString()}); the document status change was reverted.');
    }
  }

  Future<String> getReviewFileSignedUrl(String storagePath) async {
    return await _client.storage.from('student_files').createSignedUrl(storagePath, 300);
  }

  // ---------------------------------------------------------------------
  // Evaluations
  // ---------------------------------------------------------------------

  /// `evaluations` is append-only by design in the normalized schema (no
  /// UPDATE/DELETE RLS policy) — a submitted evaluation can never be
  /// edited or retracted. There is no edit path calling this in the
  /// existing UI, so nothing needed to change there.
  Future<void> submitEvaluation({
    required String studentId,
    required Map<String, double> scores,
    required double averageScore,
    String? comments,
    String type = 'academic',
  }) async {
    await _client.from('evaluations').insert({
      'student_id': studentId,
      'supervisor_id': _userId,
      'scores': scores,
      'average_score': averageScore,
      'comments': comments,
      'type': type,
    });
  }

  // ---------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------

  Future<Map<String, int>> getDashboardCounts() async {
    final students = await getStudents();

    final pendingReports = await _client
        .from('v_report_with_reviews')
        .select('report_id')
        .or('academic_status.is.null,academic_status.eq.submitted');
    final pendingDocuments = await _client.from('documents').select('document_id').eq('status', 'submitted');

    final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1).toIso8601String();
    final approvedReports = await _client
        .from('v_report_with_reviews')
        .select('report_id')
        .eq('academic_status', 'approved')
        .gte('academic_reviewed_at', monthStart);
    final approvedDocuments = await _client
        .from('v_document_with_review')
        .select('document_id')
        .eq('status', 'approved')
        .gte('reviewed_at', monthStart);

    return {
      'students': students.length,
      'pendingReviews': List.from(pendingReports).length + List.from(pendingDocuments).length,
      'approvedThisMonth': List.from(approvedReports).length + List.from(approvedDocuments).length,
    };
  }
}
