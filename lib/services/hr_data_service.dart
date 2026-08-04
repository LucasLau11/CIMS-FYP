import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

/// Real data access for the HR screens. Same singleton + "throw Exception
/// with a user-facing message" style as the other *_data_service classes.
/// Everything here is scoped to the caller's own `company_hr.company_id`
/// (enforced both client-side via the queries below and server-side by the
/// `job_postings_*_own_company` / `applications_*_involved` /
/// `interviews_*_company` RLS policies, keyed off the `is_my_company()`
/// helper).
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
    final row = await _client.from('company_hr').select('company_id').eq('profile_id', _userId).maybeSingle();
    return row?['company_id'] as String?;
  }

  // ---------------------------------------------------------------------
  // Postings
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getPostings() async {
    final companyId = await _companyId;
    if (companyId == null) return [];
    final rows = await _client
        .from('job_postings')
        .select('*, categories(category_name)')
        .eq('company_id', companyId)
        .order('posted_at', ascending: false);
    final postings = List<Map<String, dynamic>>.from(rows);
    if (postings.isEmpty) return [];

    final ids = postings.map((p) => p['job_posting_id'] as String).toList();
    final apps = await _client.from('applications').select('job_posting_id').inFilter('job_posting_id', ids);
    final appList = List<Map<String, dynamic>>.from(apps);

    return postings.map((p) {
      final result = Map<String, dynamic>.from(p);
      final categoryRow = result.remove('categories') as Map<String, dynamic>?;
      result['id'] = p['job_posting_id'];
      result['category'] = categoryRow?['category_name'];
      result['applicant_count'] = appList.where((a) => a['job_posting_id'] == p['job_posting_id']).length;
      return result;
    }).toList();
  }

  /// Categories for the posting-category dropdown, replacing the old
  /// hardcoded enum list. Not yet wired into `hr_postings_screen.dart`
  /// (out of this file's scope) — see the migration report for details on
  /// why the screen's current hardcoded/custom-text category flow doesn't
  /// map cleanly onto this normalized table.
  Future<List<Map<String, dynamic>>> getCategories() async {
    final rows = await _client.from('categories').select().order('category_name');
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Best-effort lookup of an existing `categories` row by (trimmed,
  /// case-insensitive) name. HR accounts cannot create new categories
  /// (`categories` write access is admin-only), so an unmatched name
  /// resolves to `null` rather than failing the whole posting write — see
  /// the migration report for the product-level implication of this.
  Future<String?> _resolveCategoryId(String categoryName) async {
    final trimmed = categoryName.trim();
    if (trimmed.isEmpty) return null;
    final row = await _client.from('categories').select('category_id').ilike('category_name', trimmed).maybeSingle();
    return row?['category_id'] as String?;
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
    DateTime? postingClosesAt,
  }) async {
    final companyId = await _companyId;
    if (companyId == null) throw Exception('Join or register a company before posting.');
    final categoryId = await _resolveCategoryId(category);
    await _client.from('job_postings').insert({
      'company_id': companyId,
      'category_id': categoryId,
      'title': title.trim(),
      'description': description.trim(),
      'location': location.trim(),
      'duration_months': durationMonths,
      'allowance_month': allowanceMonth,
      'required_skills': requiredSkills,
      'job_type': jobType,
      'application_deadline': applicationDeadline?.toIso8601String().split('T').first,
      'posting_closes_at': postingClosesAt?.toIso8601String(),
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
    DateTime? postingClosesAt,
  }) async {
    final categoryId = await _resolveCategoryId(category);
    await _client.from('job_postings').update({
      'category_id': categoryId,
      'title': title.trim(),
      'description': description.trim(),
      'location': location.trim(),
      'duration_months': durationMonths,
      'allowance_month': allowanceMonth,
      'required_skills': requiredSkills,
      'job_type': jobType,
      'application_deadline': applicationDeadline?.toIso8601String().split('T').first,
      'posting_closes_at': postingClosesAt?.toIso8601String(),
    }).eq('job_posting_id', id);
  }

  Future<void> setPostingStatus({required String id, required String status}) async {
    await _client.from('job_postings').update({'status': status}).eq('job_posting_id', id);
  }

  Future<void> deletePosting(String id) async {
    await _client.from('job_postings').delete().eq('job_posting_id', id);
  }

  // ---------------------------------------------------------------------
  // Applicants
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getApplicants() async {
    final companyId = await _companyId;
    if (companyId == null) return [];

    final rows = await _client
        .from('applications')
        .select('*, job_postings!inner(job_posting_id, title, company_id), interviews(scheduled_at, mode, location)')
        .eq('job_postings.company_id', companyId)
        .order('applied_at', ascending: false);
    final apps = List<Map<String, dynamic>>.from(rows);
    if (apps.isEmpty) return [];

    final studentIds = apps.map((a) => a['student_id'] as String).toSet().toList();
    final studentRows = await _client
        .from('students')
        .select('profile_id, programme, resume_path, resume_filename, profiles(full_name)')
        .inFilter('profile_id', studentIds);
    final studentMap = {for (final s in List<Map<String, dynamic>>.from(studentRows)) s['profile_id'] as String: s};

    return apps.map((a) {
      final result = Map<String, dynamic>.from(a);
      result['id'] = a['application_id'];

      final student = studentMap[a['student_id']];
      final profile = student?['profiles'] as Map<String, dynamic>?;
      final fullName = profile?['full_name'] as String?;
      result['student_name'] = fullName?.isNotEmpty == true ? fullName! : 'Unnamed student';
      result['programme'] = student?['programme'];
      result['resume_path'] = student?['resume_path'];
      result['resume_filename'] = student?['resume_filename'];

      final jobPosting = result.remove('job_postings') as Map<String, dynamic>?;
      result['internship_title'] = jobPosting?['title'];

      final interviewList = List<Map<String, dynamic>>.from(result.remove('interviews') as List? ?? []);
      if (interviewList.isNotEmpty) {
        result['interview_at'] = interviewList.first['scheduled_at'];
        result['interview_mode'] = interviewList.first['mode'];
        result['interview_location'] = interviewList.first['location'];
      }
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
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('application_id', applicationId);

    // Interview scheduling now lives on its own table, not on `applications`.
    // `interviews.application_id` has a unique constraint (migration 00011),
    // so a single upsert handles both first-time scheduling and rescheduling
    // atomically -- no read-then-branch race between concurrent callers.
    if (interviewAt != null) {
      final payload = {
        'application_id': applicationId,
        'scheduled_at': interviewAt.toIso8601String(),
        'mode': interviewMode,
        'location': interviewLocation,
      };
      await _client.from('interviews').upsert(payload, onConflict: 'application_id');
    }

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
      await _client.from('notifications').insert({
        'user_id': studentId,
        'title': title,
        'body': body,
        'type': 'application',
        'related_id': applicationId,
      });
    } catch (_) {
      // Non-fatal — the status update itself already succeeded.
    }
  }

  Future<String> getResumeSignedUrl(String storagePath) async {
    return await _client.storage.from('resumes').createSignedUrl(storagePath, 300);
  }

  /// Resume for a matched-but-not-applied candidate. Only returns data if
  /// the RLS policy on `storage.objects` grants access (the student's
  /// skills currently overlap an open posting at this HR's company, via
  /// `can_view_resume`) — returns null otherwise, treated as "no resume" by
  /// callers, not an error. `students_select_authenticated` is permissive
  /// (`true`), so the `students` row lookup itself always succeeds; the
  /// real gate is at the storage layer when the signed URL is used.
  Future<Map<String, String>?> getCandidateResume(String candidateId) async {
    final row = await _client
        .from('students')
        .select('resume_path, resume_filename')
        .eq('profile_id', candidateId)
        .maybeSingle();
    final path = row?['resume_path'] as String?;
    if (path == null) return null;
    final url = await _client.storage.from('resumes').createSignedUrl(path, 300);
    return {'url': url, 'filename': (row?['resume_filename'] as String?) ?? path.split('/').last};
  }

  // ---------------------------------------------------------------------
  // Candidate recommendations
  // ---------------------------------------------------------------------

  /// Students whose `profile_directory.skills` overlap [requiredSkills].
  /// Sourced from `profile_directory` (not `students`) so this works for
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
      result['id'] = c['profile_id'];
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

    final postings = await _client.from('job_postings').select('job_posting_id, status').eq('company_id', companyId);
    final postingList = List<Map<String, dynamic>>.from(postings);
    final postingIds = postingList.map((p) => p['job_posting_id'] as String).toList();

    if (postingIds.isEmpty) {
      return {'postings': 0, 'activePostings': 0, 'newApplicants': 0, 'interviews': 0, 'interns': 0};
    }

    final apps = await _client.from('applications').select('status').inFilter('job_posting_id', postingIds);
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
