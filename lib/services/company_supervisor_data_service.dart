import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'supervisor_data_service.dart';

/// Real data access for the Company Supervisor screens. Reports/documents
/// review and evaluations reuse [SupervisorDataService] directly (same
/// tables, and RLS now grants company_supervisor the same visibility it
/// grants academic_supervisor — see `reports_select_supervisor` etc.) —
/// only "which students are mine" is different, so that's scoped here to
/// this supervisor's own company via `applications`/`internships`.
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
    final row = await _client.from('profiles').select('company_id').eq('id', _userId).single();
    return row['company_id'] as String?;
  }

  // ---------------------------------------------------------------------
  // Interns
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getInterns() async {
    final companyId = await _companyId;
    if (companyId == null) return [];

    final rows = await _client
        .from('applications')
        .select('student_id, applied_at, internships!inner(id, title, company_id)')
        .eq('internships.company_id', companyId)
        .eq('status', 'active');
    final apps = List<Map<String, dynamic>>.from(rows);
    if (apps.isEmpty) return [];

    final studentIds = apps.map((a) => a['student_id'] as String).toSet().toList();
    final profiles = await _client.from('profiles').select('id, full_name, programme, faculty').inFilter('id', studentIds);
    final profileMap = {for (final p in List<Map<String, dynamic>>.from(profiles)) p['id'] as String: p};

    final reports = await _client.from('reports').select('student_id, status').inFilter('student_id', studentIds);
    final reportList = List<Map<String, dynamic>>.from(reports);
    final documents = await _client.from('documents').select('student_id, status').inFilter('student_id', studentIds);
    final documentList = List<Map<String, dynamic>>.from(documents);

    return apps.map((a) {
      final id = a['student_id'] as String;
      final profile = profileMap[id];
      final pendingCount = reportList.where((r) => r['student_id'] == id && r['status'] == 'submitted').length +
          documentList.where((d) => d['student_id'] == id && d['status'] == 'submitted').length;
      return {
        'id': id,
        'full_name': (profile?['full_name'] as String?)?.isNotEmpty == true ? profile!['full_name'] as String : 'Unnamed student',
        'programme': profile?['programme'],
        'faculty': profile?['faculty'],
        'role_title': (a['internships'] as Map?)?['title'],
        'applied_at': a['applied_at'],
        'pending_review_count': pendingCount,
      };
    }).toList();
  }

  // ---------------------------------------------------------------------
  // Reviews — scoped down to this company's interns, reusing the shared
  // reports/documents review logic from SupervisorDataService.
  // ---------------------------------------------------------------------

  /// For reports, `status`/`feedback` here reflect the company supervisor's
  /// own (first-stage) review — company_review_status/company_feedback —
  /// remapped onto the same keys the shared review UI already reads, not
  /// the academic supervisor's final status. Documents pass through as-is
  /// (no two-stage flow for those).
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
