import 'dart:io';
import 'dart:typed_data';
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
        .select('*, job_postings!inner(job_posting_id, title, company_id, companies(name)), interviews(scheduled_at, mode, location)')
        .eq('job_postings.company_id', companyId)
        .order('applied_at', ascending: false);
    final apps = List<Map<String, dynamic>>.from(rows);
    if (apps.isEmpty) return [];

    final studentIds = apps.map((a) => a['student_id'] as String).toSet().toList();
    // `profiles!students_profile_id_fkey` disambiguates the embed: `students`
    // has two FKs into `profiles` (profile_id and academic_supervisor_id), so
    // an unqualified `profiles(...)` embed is rejected by PostgREST with
    // "more than one relationship was found" and this whole query throws.
    final studentRows = await _client
        .from('students')
        .select('profile_id, programme, student_reg_no, resume_path, resume_filename, profiles!students_profile_id_fkey(full_name)')
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
      result['student_reg_no'] = student?['student_reg_no'];
      result['resume_path'] = student?['resume_path'];
      result['resume_filename'] = student?['resume_filename'];

      final jobPosting = result.remove('job_postings') as Map<String, dynamic>?;
      result['internship_title'] = jobPosting?['title'];
      result['company_name'] = (jobPosting?['companies'] as Map?)?['name'];

      // `interviews.application_id` has a UNIQUE constraint, so PostgREST
      // treats applications->interviews as a to-one embed and returns a
      // single object (or null) here, not a list — casting it `as List?`
      // threw for every applicant who actually had an interview scheduled,
      // silently emptying this whole screen (and the dashboard's upcoming-
      // interviews section, which reuses this method) via the caller's
      // try/catch.
      final interview = result.remove('interviews') as Map<String, dynamic>?;
      if (interview != null) {
        result['interview_at'] = interview['scheduled_at'];
        result['interview_mode'] = interview['mode'];
        result['interview_location'] = interview['location'];
      }
      return result;
    }).toList();
  }

  // ---------------------------------------------------------------------
  // Offer letter + company acceptance letter — both only valid once the
  // applicant's status is 'active'; see migrations
  // offer_letter_and_company_document_visibility and
  // company_acceptance_letter_filled_by_hr for the documents/storage RLS
  // that enforces this server-side too. The offer letter is a plain
  // upload; the acceptance letter is filled + signed in-app via
  // DocumentLetterFillScreen (see hr_applicants_screen.dart), which calls
  // [uploadGeneratedLetter] below instead of [uploadOfferLetter].
  // ---------------------------------------------------------------------

  Future<Map<String, dynamic>?> getLetterDocument(String studentId, String category) async {
    return await _client
        .from('documents')
        .select()
        .eq('student_id', studentId)
        .eq('category', category)
        .maybeSingle();
  }

  Future<Map<String, dynamic>?> getOfferLetterDocument(String studentId) => getLetterDocument(studentId, 'offer_letter');

  /// Uploads (or replaces) the offer letter for [studentId]. Written
  /// straight to 'approved' — offer letters aren't reviewed, just kept on
  /// file for the student/academic supervisor/admin/company supervisor to
  /// see (see documents_select_company / documents_select_involved).
  Future<void> uploadOfferLetter({
    required String studentId,
    required File file,
    required String fileName,
    required int fileSizeBytes,
  }) async {
    final existing = await getOfferLetterDocument(studentId);
    if (existing != null) {
      final oldPath = existing['storage_path'] as String;
      if (oldPath.isNotEmpty) {
        try {
          await _client.storage.from('student_files').remove([oldPath]);
        } catch (_) {
          // Non-fatal — proceed to replace the DB row regardless.
        }
      }
      await _client.from('documents').delete().eq('document_id', existing['document_id'] as String);
    }

    final inserted = await _client
        .from('documents')
        .insert({
          'student_id': studentId,
          'category': 'offer_letter',
          'status': 'approved',
          'storage_path': '',
          'file_name': fileName,
          'file_size_bytes': fileSizeBytes,
        })
        .select()
        .single();
    final documentId = inserted['document_id'] as String;

    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'dat';
    final storagePath = '$studentId/documents/$documentId.$ext';
    await _client.storage.from('student_files').upload(storagePath, file);
    await _client.from('documents').update({'storage_path': storagePath}).eq('document_id', documentId);

    try {
      await _client.from('notifications').insert({
        'user_id': studentId,
        'title': 'Offer letter uploaded',
        'body': '$fileName has been uploaded by your company.',
        'type': 'document',
        'related_id': documentId,
      });
    } catch (_) {
      // Non-fatal — the upload itself already succeeded.
    }
  }

  Future<String> getOfferLetterSignedUrl(String storagePath) async {
    return await _client.storage.from('student_files').createSignedUrl(storagePath, 300);
  }

  /// Records a filled+signed template PDF (see DocumentLetterFillScreen) as
  /// [studentId]'s `documents` row for [category] — the HR-side
  /// counterpart to StudentDataService.recordGeneratedDocument, used for
  /// the company acceptance letter, which HR fills on the student's
  /// behalf rather than the student filling it themselves. Same
  /// singleton-per-category replace + insert-then-upload-then-patch flow
  /// as [uploadOfferLetter].
  Future<void> uploadGeneratedLetter({
    required String studentId,
    required String category,
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    final existing = await getLetterDocument(studentId, category);
    if (existing != null) {
      final oldPath = existing['storage_path'] as String;
      if (oldPath.isNotEmpty) {
        try {
          await _client.storage.from('student_files').remove([oldPath]);
        } catch (_) {
          // Non-fatal — proceed to replace the DB row regardless.
        }
      }
      await _client.from('documents').delete().eq('document_id', existing['document_id'] as String);
    }

    final inserted = await _client
        .from('documents')
        .insert({
          'student_id': studentId,
          'category': category,
          'status': 'approved',
          'storage_path': '',
          'file_name': fileName,
          'file_size_bytes': pdfBytes.length,
        })
        .select()
        .single();
    final documentId = inserted['document_id'] as String;

    final storagePath = '$studentId/documents/$documentId.pdf';
    await _client.storage.from('student_files').uploadBinary(
          storagePath,
          pdfBytes,
          fileOptions: const FileOptions(contentType: 'application/pdf'),
        );
    await _client.from('documents').update({'storage_path': storagePath}).eq('document_id', documentId);

    try {
      await _client.from('notifications').insert({
        'user_id': studentId,
        'title': 'Document signed',
        'body': '$fileName has been signed by your company.',
        'type': 'document',
        'related_id': documentId,
      });
    } catch (_) {
      // Non-fatal — the upload itself already succeeded.
    }
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
        body = 'Congratulations! Your application for $roleLabel has been accepted. Please sign your Company Acceptance Letter in the Documents tab.';
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
