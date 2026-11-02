import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'supervisor_data_service.dart';

/// Real data access for the Company Supervisor screens.
///
/// Normalized-schema notes (Task 18):
/// - Company affiliation is now `company_supervisors.company_id`
///   (`profile_id` PK), not a flat `profiles.company_id` column — same
///   pattern as `HrDataService._companyId` but keyed off `company_supervisors`
///   instead of `company_hr`.
/// - "My interns" is `applications` (status `active`) joined to
///   `job_postings` (was `internships`) filtered to this supervisor's
///   company; student display fields (`full_name`/`programme`/`faculty`)
///   come from `students` joined to `profiles`, not a flat `profiles` row.
/// - `reports` no longer has a `status` column — pending-ness for the
///   intern list is read from `v_report_with_reviews.company_status`
///   (null or 'pending' = not yet reviewed by this company supervisor),
///   matching the semantics [getReviewItems] already uses.
/// - Report review submission delegates to
///   [SupervisorDataService.reviewReportAsCompanySupervisor], which writes
///   `company_report_reviews` (this role's first-stage verdict) — never
///   `academic_report_reviews`.
/// - Document review still delegates to [SupervisorDataService.reviewDocument]
///   for backward compatibility with the reviews screen's UI, but per that
///   method's own doc comment, `document_reviews`/`documents_update_supervisor`
///   RLS deliberately does not recognize `company_supervisor` — a
///   company_supervisor calling this now gets a clean thrown `Exception`
///   from the compensating-revert logic added in Task 15, not a silent
///   no-op. See this task's report for a live-tested confirmation. This is
///   an intentional, documented product boundary (see migration
///   00004_documents_and_reviews.sql's header comment) — not something to
///   route around in this file.
/// - Every table's primary key is now `<table_singular>_id` instead of
///   `id`; returned maps re-key onto `id` where screens still read it.
class CompanySupervisorDataService {
  CompanySupervisorDataService._();
  static final CompanySupervisorDataService instance = CompanySupervisorDataService._();

  final SupabaseClient _client = Supabase.instance.client;

  String get _userId {
    final id = AuthService.instance.currentUserId;
    if (id == null) throw Exception('You must be logged in.');
    return id;
  }

  Future<String?> get _companyId async {
    final row = await _client.from('company_supervisors').select('company_id').eq('profile_id', _userId).maybeSingle();
    return row?['company_id'] as String?;
  }

  // ---------------------------------------------------------------------
  // Interns
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getInterns() async {
    final companyId = await _companyId;
    if (companyId == null) return [];

    final rows = await _client
        .from('applications')
        .select('student_id, applied_at, job_postings!inner(job_posting_id, title, company_id)')
        .eq('job_postings.company_id', companyId)
        .eq('status', 'active');
    final apps = List<Map<String, dynamic>>.from(rows);
    if (apps.isEmpty) return [];

    final studentIds = apps.map((a) => a['student_id'] as String).toSet().toList();
    // `profiles!students_profile_id_fkey` disambiguates the embed: `students`
    // has two FKs into `profiles` (profile_id and academic_supervisor_id), so
    // an unqualified `profiles(...)` embed is rejected by PostgREST with
    // "more than one relationship was found" and this whole query throws.
    final students = await _client
        .from('students')
        .select('profile_id, programme, faculty, profiles!students_profile_id_fkey(full_name)')
        .inFilter('profile_id', studentIds);
    final studentMap = {for (final s in List<Map<String, dynamic>>.from(students)) s['profile_id'] as String: s};

    // `reports` has no `status` column in the normalized schema — pending-ness
    // for this company supervisor is whether their own (company_report_reviews)
    // verdict is still null/'pending', same as getReviewItems() below.
    final reports = await _client
        .from('v_report_with_reviews')
        .select('student_id, company_status')
        .inFilter('student_id', studentIds);
    final reportList = List<Map<String, dynamic>>.from(reports);
    final documents = await _client.from('documents').select('student_id, status').inFilter('student_id', studentIds);
    final documentList = List<Map<String, dynamic>>.from(documents);

    // Drives whether the "Evaluate" action is available — see migration
    // 00022_intakes_and_evaluation_gating.sql: evaluations are only
    // insertable once student_internship_status() = 'completed', so the UI
    // gates on the same value here rather than letting a supervisor tap
    // Evaluate and hit an RLS error.
    final internshipStatuses = await _client.from('v_student_internship_status').select('student_id, status').inFilter('student_id', studentIds);
    final statusById = {
      for (final r in List<Map<String, dynamic>>.from(internshipStatuses)) r['student_id'] as String: r['status'] as String,
    };

    return apps.map((a) {
      final id = a['student_id'] as String;
      final student = studentMap[id];
      final profile = student?['profiles'] as Map<String, dynamic>?;
      final fullName = profile?['full_name'] as String?;
      final pendingCount = reportList.where((r) {
            if (r['student_id'] != id) return false;
            final companyStatus = r['company_status'] as String?;
            return companyStatus == null || companyStatus == 'pending';
          }).length +
          documentList.where((d) => d['student_id'] == id && d['status'] == 'submitted').length;
      final jobPosting = a['job_postings'] as Map?;
      return {
        'id': id,
        'full_name': fullName?.isNotEmpty == true ? fullName! : 'Unnamed student',
        'programme': student?['programme'],
        'faculty': student?['faculty'],
        'role_title': jobPosting?['title'],
        'applied_at': a['applied_at'],
        'pending_review_count': pendingCount,
        'internship_status': statusById[id] ?? 'unassigned',
        'can_evaluate': statusById[id] == 'completed',
      };
    }).toList();
  }

  /// Offer/indemnity/company-acceptance letters for [studentId] — visible
  /// to company staff via the documents_select_company RLS policy (see
  /// migration offer_letter_and_company_document_visibility), unlike the
  /// broader documents_select_involved policy which doesn't cover this
  /// role at all. Deliberately narrower than SupervisorDataService.
  /// getStudentDocuments — a company supervisor only ever sees these 3
  /// categories for their own accepted interns, never 'other' uploads.
  Future<List<Map<String, dynamic>>> getInternDocuments(String studentId) async {
    final rows = await _client.from('v_document_with_review').select().eq('student_id', studentId).order('uploaded_at', ascending: false);
    final list = List<Map<String, dynamic>>.from(rows);
    for (final r in list) {
      r['id'] = r['document_id'];
    }
    return list;
  }

  // ---------------------------------------------------------------------
  // Reviews — scoped down to this company's interns, reusing the shared
  // reports/documents review logic from SupervisorDataService.
  // ---------------------------------------------------------------------

  /// For reports, `status`/`feedback` here reflect the company supervisor's
  /// own (first-stage) review — company_review_status/company_feedback —
  /// remapped onto the same keys the shared review UI already reads, not
  /// the academic supervisor's final status. Documents pass through as-is
  /// if returned at all — but `documents_select_involved` RLS does not grant
  /// company_supervisor read access to `documents`/`document_reviews` in the
  /// first place, so `SupervisorDataService.getAllReviewItems()`'s document
  /// half is silently empty for this role in practice; see class doc.
  Future<List<Map<String, dynamic>>> getReviewItems() async {
    final interns = await getInterns();
    final internIds = interns.map((i) => i['id'] as String).toSet();
    if (internIds.isEmpty) return [];
    final all = await SupervisorDataService.instance.getAllReviewItems();
    return all.where((item) => internIds.contains(item['student_id'])).map((item) {
      if (item['kind'] != 'report') return item;
      final result = Map<String, dynamic>.from(item);
      final companyStatus = item['company_review_status'] as String? ?? 'pending';
      result['status'] = companyStatus == 'pending' ? 'submitted' : companyStatus;
      result['feedback'] = item['company_feedback'];
      return result;
    }).toList();
  }

  Future<void> reviewReport({required String reportId, required String status, String? feedback}) =>
      SupervisorDataService.instance.reviewReportAsCompanySupervisor(reportId: reportId, status: status, feedback: feedback);

  Future<void> reviewDocument({required String documentId, required String status, String? feedback}) =>
      SupervisorDataService.instance.reviewDocument(documentId: documentId, status: status, feedback: feedback);

  Future<String> getReviewFileSignedUrl(String storagePath) =>
      SupervisorDataService.instance.getReviewFileSignedUrl(storagePath);

  // ---------------------------------------------------------------------
  // Evaluations
  // ---------------------------------------------------------------------

  Future<void> submitEvaluation({
    required String studentId,
    required Map<String, double> scores,
    required double averageScore,
    String? comments,
  }) =>
      SupervisorDataService.instance.submitEvaluation(
        studentId: studentId,
        scores: scores,
        averageScore: averageScore,
        comments: comments,
        type: 'workplace',
      );

  // ---------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------

  Future<Map<String, int>> getDashboardCounts() async {
    final interns = await getInterns();
    final reviewItems = await getReviewItems();
    final pending = reviewItems.where((i) => i['status'] == 'submitted').length;
    final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final approvedThisMonth = reviewItems.where((i) {
      if (i['status'] != 'approved') return false;
      final submittedAt = DateTime.tryParse(i['submitted_at'] as String? ?? '');
      return submittedAt != null && submittedAt.isAfter(monthStart);
    }).length;

    return {
      'interns': interns.length,
      'pendingReviews': pending,
      'approvedThisMonth': approvedThisMonth,
    };
  }
}
