import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

/// Real data access for the academic supervisor screens. Same singleton +
/// "throw Exception with a user-facing message" style as [AuthService] and
/// [StudentDataService]. Messaging is intentionally NOT duplicated here —
/// conversations/messages are role-agnostic (keyed by the current user's
/// id, not their role), so supervisor screens call StudentDataService's
/// messaging methods directly instead of a second copy of the same logic.
///
/// Student/supervisor assignment: there's no admin-driven assignment
/// relationship yet (that belongs to the admin module), so "my students"
/// here means all student profiles. Scope down to a real assignment once
/// that exists.
class SupervisorDataService {
  SupervisorDataService._();
  static final SupervisorDataService instance = SupervisorDataService._();

  final SupabaseClient _client = Supabase.instance.client;

  String get _userId {
    final id = AuthService.instance.currentUserId;
    if (id == null) throw Exception('You must be logged in.');
    return id;
  }

  // ---------------------------------------------------------------------
  // Students
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getStudents() async {
    final students = await _client
        .from('profiles')
        .select('id, full_name, programme, semester, faculty')
        .eq('role', 'student')
        .order('full_name');
    final studentList = List<Map<String, dynamic>>.from(students);
    if (studentList.isEmpty) return [];
    final studentIds = studentList.map((s) => s['id'] as String).toList();

    final applications = await _client
        .from('applications')
        .select('student_id, status, applied_at, internships(company_name)')
        .inFilter('student_id', studentIds)
        .order('applied_at', ascending: false);
    final applicationList = List<Map<String, dynamic>>.from(applications);

    final reports = await _client
        .from('reports')
        .select('student_id, status, submitted_at')
        .inFilter('student_id', studentIds)
        .order('submitted_at', ascending: false);
    final reportList = List<Map<String, dynamic>>.from(reports);

    final documents = await _client
        .from('documents')
        .select('student_id, status')
        .inFilter('student_id', studentIds);
    final documentList = List<Map<String, dynamic>>.from(documents);

    return studentList.map((student) {
      final id = student['id'] as String;
      final myApplications = applicationList.where((a) => a['student_id'] == id).toList();
      final activeApplications = myApplications.where((a) => a['status'] == 'active').toList();
      final hasActiveInternship = activeApplications.isNotEmpty;
      String? companyName;
      if (hasActiveInternship) {
        final internship = activeApplications.first['internships'] as Map?;
        companyName = internship?['company_name'] as String?;
      }
      final myReports = reportList.where((r) => r['student_id'] == id).toList();
      final pendingReports = myReports.where((r) => r['status'] == 'submitted').length;
      final pendingDocuments =
          documentList.where((d) => d['student_id'] == id && d['status'] == 'submitted').length;

      final result = Map<String, dynamic>.from(student);
      result['company_name'] = companyName;
      result['has_active_internship'] = hasActiveInternship;
      result['last_report_at'] = myReports.isEmpty ? null : myReports.first['submitted_at'];
      result['pending_review_count'] = pendingReports + pendingDocuments;
      result['report_count'] = myReports.length;
      return result;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getStudentReports(String studentId) async {
    final rows = await _client
        .from('reports')
        .select()
        .eq('student_id', studentId)
        .order('submitted_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> getStudentDocuments(String studentId) async {
    final rows = await _client
        .from('documents')
        .select()
        .eq('student_id', studentId)
        .order('uploaded_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> getStudentEvaluations(String studentId) async {
    final rows = await _client
        .from('evaluations')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  // ---------------------------------------------------------------------
  // Reviews (reports + documents merged into one feed)
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getAllReviewItems() async {
    final reports = await _client.from('reports').select().order('submitted_at', ascending: false);
    final documents = await _client.from('documents').select().order('uploaded_at', ascending: false);
    final reportList = List<Map<String, dynamic>>.from(reports);
    final documentList = List<Map<String, dynamic>>.from(documents);

    final studentIds = {...reportList.map((r) => r['student_id'] as String), ...documentList.map((d) => d['student_id'] as String)};
    final names = <String, String>{};
    if (studentIds.isNotEmpty) {
      final profiles = await _client.from('profile_directory').select().inFilter('id', studentIds.toList());
      for (final p in List<Map<String, dynamic>>.from(profiles)) {
        names[p['id'] as String] = (p['full_name'] as String?)?.isNotEmpty == true ? p['full_name'] as String : 'Unknown student';
      }
    }

    final reportItems = reportList.map((r) => {
          'kind': 'report',
          'id': r['id'],
          'student_id': r['student_id'],
          'student_name': names[r['student_id']] ?? 'Unknown student',
          'title': '${r['type'] == 'final' ? 'Final Report' : 'Monthly Report'} — ${r['period_label']}',
          'submitted_at': r['submitted_at'],
          'status': r['status'],
          'feedback': r['feedback'],
          'storage_path': r['storage_path'],
          'file_name': r['file_name'],
          // Two-stage approval: company supervisor reviews first, academic
          // supervisor/admin's Approve/Reject on `status` above is only
          // meaningful once this is 'approved'.
          'company_review_status': r['company_review_status'],
          'company_feedback': r['company_feedback'],
        });
    final documentItems = documentList.map((d) => {
          'kind': 'document',
          'id': d['id'],
          'student_id': d['student_id'],
          'student_name': names[d['student_id']] ?? 'Unknown student',
          'title': d['title'] ?? _categoryLabel(d['category'] as String),
          'submitted_at': d['uploaded_at'],
          'status': d['status'],
          'feedback': d['feedback'],
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
    await _client.from('reports').update({
      'status': status,
      'feedback': feedback,
      'reviewed_by': _userId,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', reportId);
  }

  /// The company supervisor's half of the two-stage report approval —
  /// separate from [reviewReport] (the academic supervisor/admin's final
  /// say) so the two reviewer roles never clobber each other's decision.
  Future<void> reviewReportAsCompanySupervisor({required String reportId, required String status, String? feedback}) async {
    await _client.from('reports').update({
      'company_review_status': status,
      'company_feedback': feedback,
      'company_reviewed_by': _userId,
      'company_reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', reportId);
  }

  Future<void> reviewDocument({required String documentId, required String status, String? feedback}) async {
    await _client.from('documents').update({
      'status': status,
      'feedback': feedback,
      'reviewed_by': _userId,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', documentId);
  }

  Future<String> getReviewFileSignedUrl(String storagePath) async {
    return await _client.storage.from('student_files').createSignedUrl(storagePath, 300);
  }

  // ---------------------------------------------------------------------
  // Evaluations
  // ---------------------------------------------------------------------

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
    final students = await _client.from('profiles').select('id').eq('role', 'student');
    final pendingReports = await _client.from('reports').select('id').eq('status', 'submitted');
    final pendingDocuments = await _client.from('documents').select('id').eq('status', 'submitted');

    final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1).toIso8601String();
    final approvedReports =
        await _client.from('reports').select('id').eq('status', 'approved').gte('reviewed_at', monthStart);
    final approvedDocuments =
        await _client.from('documents').select('id').eq('status', 'approved').gte('reviewed_at', monthStart);

    return {
      'students': List.from(students).length,
      'pendingReviews': List.from(pendingReports).length + List.from(pendingDocuments).length,
      'approvedThisMonth': List.from(approvedReports).length + List.from(approvedDocuments).length,
    };
  }
}
