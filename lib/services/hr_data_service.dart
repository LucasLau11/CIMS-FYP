import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

/// Real data access for the HR screens. Same singleton + "throw Exception
/// with a user-facing message" style as the other *_data_service classes.
/// Everything here is scoped to the caller's own `profiles.company_id`
/// (enforced both client-side via the queries below and server-side by the
/// `internships_*_hr` / `applications_*_hr` RLS policies).
class HrDataService {
  HrDataService._();
  static final HrDataService instance = HrDataService._();

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
  // Postings
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getPostings() async {
    final companyId = await _companyId;
    if (companyId == null) return [];
    final rows = await _client.from('internships').select().eq('company_id', companyId).order('posted_at', ascending: false);
    final postings = List<Map<String, dynamic>>.from(rows);
    if (postings.isEmpty) return [];

    final ids = postings.map((p) => p['id'] as String).toList();
    final apps = await _client.from('applications').select('internship_id').inFilter('internship_id', ids);
    final appList = List<Map<String, dynamic>>.from(apps);

    return postings.map((p) {
      final result = Map<String, dynamic>.from(p);
      result['applicant_count'] = appList.where((a) => a['internship_id'] == p['id']).length;
      return result;
    }).toList();
  }

  Future<void> createPosting({
    required String title,
    required String description,
    required String category,
    required String location,
    required int durationMonths,
    double? allowanceMonth,
    required List<String> requiredSkills,
    String? jobType,
    DateTime? applicationDeadline,
  }) async {
    final companyId = await _companyId;
    if (companyId == null) throw Exception('Join or register a company before posting.');
    final company = await _client.from('companies').select('name, industry').eq('id', companyId).single();
    await _client.from('internships').insert({
      'company_id': companyId,
      'company_name': company['name'],
      'company_industry': company['industry'],
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'location': location.trim(),
      'duration_months': durationMonths,
      'allowance_month': allowanceMonth,
      'required_skills': requiredSkills,
      'job_type': jobType,
      'application_deadline': applicationDeadline?.toIso8601String().split('T').first,
      'status': 'open',
      'posted_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updatePosting({
    required String id,
    required String title,
    required String description,
    required String category,
    required String location,
    required int durationMonths,
    double? allowanceMonth,
    required List<String> requiredSkills,
    String? jobType,
    DateTime? applicationDeadline,
  }) async {
    await _client.from('internships').update({
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'location': location.trim(),
      'duration_months': durationMonths,
      'allowance_month': allowanceMonth,
      'required_skills': requiredSkills,
      'job_type': jobType,
      'application_deadline': applicationDeadline?.toIso8601String().split('T').first,
    }).eq('id', id);
  }

  Future<void> setPostingStatus({required String id, required String status}) async {
    await _client.from('internships').update({'status': status}).eq('id', id);
  }

  Future<void> deletePosting(String id) async {
    await _client.from('internships').delete().eq('id', id);
  }

  // ---------------------------------------------------------------------
  // Applicants
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getApplicants() async {
    final companyId = await _companyId;
    if (companyId == null) return [];

    final rows = await _client
        .from('applications')
        .select('*, internships!inner(id, title, company_id)')
        .eq('internships.company_id', companyId)
        .order('applied_at', ascending: false);
    final apps = List<Map<String, dynamic>>.from(rows);
    if (apps.isEmpty) return [];

    final studentIds = apps.map((a) => a['student_id'] as String).toSet().toList();
    final profiles = await _client
        .from('profiles')
        .select('id, full_name, programme, resume_path, resume_filename')
        .inFilter('id', studentIds);
    final profileMap = {for (final p in List<Map<String, dynamic>>.from(profiles)) p['id'] as String: p};

    return apps.map((a) {
      final result = Map<String, dynamic>.from(a);
      final profile = profileMap[a['student_id']];
      result['student_name'] = (profile?['full_name'] as String?)?.isNotEmpty == true ? profile!['full_name'] as String : 'Unnamed student';
      result['programme'] = profile?['programme'];
      result['resume_path'] = profile?['resume_path'];
      result['resume_filename'] = profile?['resume_filename'];
      result['internship_title'] = (a['internships'] as Map?)?['title'];
      return result;
    }).toList();
  }

  Future<void> updateApplicationStatus({
    required String applicationId,
    required String studentId,
    required String status,
    DateTime? interviewAt,
    String? interviewMode,
    String? interviewLocation,
    String? internshipTitle,
  }) async {
    await _client.from('applications').update({
      'status': status,
      if (interviewAt != null) 'interview_at': interviewAt.toIso8601String(),
      if (interviewMode != null) 'interview_mode': interviewMode,
      if (interviewLocation != null) 'interview_location': interviewLocation,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', applicationId);

    final roleLabel = internshipTitle ?? 'your application';
    String title;
    String body;
    switch (status) {
      case 'interview':
        title = 'Interview scheduled';
        body = 'You have an interview scheduled for $roleLabel.';
        break;
      case 'active':
        title = 'Application accepted';
        body = 'Congratulations! Your application for $roleLabel has been accepted.';
        break;
      case 'rejected':
        title = 'Application update';
        body = 'Your application for $roleLabel was not successful this time.';
        break;
      default:
        title = 'Application update';
        body = 'There is an update on $roleLabel.';
    }
    try {
      await _client.rpc('notify_student', params: {
        'p_student_id': studentId,
        'p_title': title,
        'p_body': body,
        'p_type': 'application',
        'p_related_id': applicationId,
      });
    } catch (_) {
      // Non-fatal — the status update itself already succeeded.
    }
  }

  Future<String> getResumeSignedUrl(String storagePath) async {
    return await _client.storage.from('resumes').createSignedUrl(storagePath, 300);
  }

  // ---------------------------------------------------------------------
  // Candidate recommendations
  // ---------------------------------------------------------------------

  /// Students whose `profile_directory.skills` overlap [requiredSkills].
  /// Sourced from `profile_directory` (not `profiles`) so this works for
  /// students who haven't applied to any of this company's postings yet —
  /// the same privacy-safe surface used for supervisor/company_supervisor
  /// lookups elsewhere in the app.
  Future<List<Map<String, dynamic>>> getRecommendedCandidates(List<String> requiredSkills) async {
    if (requiredSkills.isEmpty) return [];
    final rows = await _client.from('profile_directory').select().eq('role', 'student').overlaps('skills', requiredSkills);
    final candidates = List<Map<String, dynamic>>.from(rows);

    final results = candidates.map((c) {
      final skills = List<String>.from(c['skills'] as List? ?? []);
      final matched = skills.where((s) => requiredSkills.contains(s)).toList();
      final result = Map<String, dynamic>.from(c);
      result['matched_skills'] = matched;
      return result;
    }).where((c) => (c['matched_skills'] as List).isNotEmpty).toList();

    results.sort((a, b) => (b['matched_skills'] as List).length.compareTo((a['matched_skills'] as List).length));
    return results;
  }

  // ---------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------

  Future<Map<String, int>> getDashboardCounts() async {
    final companyId = await _companyId;
    if (companyId == null) {
      return {'postings': 0, 'activePostings': 0, 'newApplicants': 0, 'interviews': 0, 'interns': 0};
    }

    final postings = await _client.from('internships').select('id, status').eq('company_id', companyId);
    final postingList = List<Map<String, dynamic>>.from(postings);
    final postingIds = postingList.map((p) => p['id'] as String).toList();

    if (postingIds.isEmpty) {
      return {'postings': 0, 'activePostings': 0, 'newApplicants': 0, 'interviews': 0, 'interns': 0};
    }

    final apps = await _client.from('applications').select('status').inFilter('internship_id', postingIds);
    final appList = List<Map<String, dynamic>>.from(apps);

    return {
      'postings': postingList.length,
      'activePostings': postingList.where((p) => p['status'] == 'open').length,
      'newApplicants': appList.where((a) => a['status'] == 'pending').length,
      'interviews': appList.where((a) => a['status'] == 'interview').length,
      'interns': appList.where((a) => a['status'] == 'active').length,
    };
  }
}
