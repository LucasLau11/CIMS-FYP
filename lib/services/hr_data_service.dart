import '../utils/validators.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'interview_service.dart';
import '../utils/posting_dates.dart';

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

  /// Applications, interviews and offers for this company (migration 00039); the app writes the labels.
  Future<Map<String, dynamic>> getStats() async {
    final result = await _client.rpc('hr_stats');
    return Map<String, dynamic>.from(result as Map);
  }

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
    // Close postings whose deadline has passed before listing them.
    try {
      await _client.rpc('close_expired_postings');
    } catch (_) {}
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
      result['expired'] = postingIsExpired(deadline: p['application_deadline'] as String?, closesAt: p['posting_closes_at'] as String?);
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
    // A posting that closed because its dates passed comes back to life when
    // the dates are extended; one the HR closed by hand stays closed.
    final before = await _client.from('job_postings').select('status, application_deadline, posting_closes_at').eq('job_posting_id', id).maybeSingle();
    final wasExpired = before != null &&
        before['status'] == 'closed' &&
        postingIsExpired(deadline: before['application_deadline'] as String?, closesAt: before['posting_closes_at'] as String?);
    final newDeadline = applicationDeadline?.toIso8601String().split('T').first;
    final newCloses = postingClosesAt?.toIso8601String();
    final reopen = wasExpired && !postingIsExpired(deadline: newDeadline, closesAt: newCloses);
    await _client.from('job_postings').update({
      if (reopen) 'status': 'open',
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
        .select('*, job_postings!inner(job_posting_id, title, company_id, companies(name)), interviews(${InterviewInfo.embed})')
        .eq('job_postings.company_id', companyId)
        .order('applied_at', ascending: false);
    final apps = List<Map<String, dynamic>>.from(rows);
    if (apps.isEmpty) return [];

    // HR's private shortlist flag and note per application (HR of this company only).
    final noteRows = await _client
        .from('application_notes')
        .select('application_id, shortlisted, note')
        .inFilter('application_id', apps.map((a) => a['application_id'] as String).toList());
    final notes = {for (final n in List<Map<String, dynamic>>.from(noteRows)) n['application_id'] as String: n};

    final studentIds = apps.map((a) => a['student_id'] as String).toSet().toList();
    // `profiles!students_profile_id_fkey` disambiguates the embed: `students`
    // has two FKs into `profiles` (profile_id and academic_supervisor_id), so
    // an unqualified `profiles(...)` embed is rejected by PostgREST with
    // "more than one relationship was found" and this whole query throws.
    final studentRows = await _client
        .from('students')
        .select('profile_id, programme, faculty, semester, cgpa, skills, student_reg_no, resume_path, resume_filename, profiles!students_profile_id_fkey(full_name, avatar_url, email, phone)')
        .inFilter('profile_id', studentIds);
    final studentMap = {for (final s in List<Map<String, dynamic>>.from(studentRows)) s['profile_id'] as String: s};

    return apps.map((a) {
      final result = Map<String, dynamic>.from(a);
      result['id'] = a['application_id'];
      result['shortlisted'] = notes[a['application_id']]?['shortlisted'] == true;
      result['hr_note'] = notes[a['application_id']]?['note'];

      final student = studentMap[a['student_id']];
      final profile = student?['profiles'] as Map<String, dynamic>?;
      final fullName = profile?['full_name'] as String?;
      result['student_name'] = fullName?.isNotEmpty == true ? fullName! : 'Unnamed student';
      result['avatar_url'] = profile?['avatar_url'];
      result['email'] = profile?['email'];
      result['phone'] = profile?['phone'];
      result['faculty'] = student?['faculty'];
      result['semester'] = student?['semester'];
      result['cgpa'] = student?['cgpa'];
      result['skills'] = student?['skills'];
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
      // try/catch. InterviewInfo.fromEmbed handles that shape.
      result['interview'] = InterviewInfo.fromEmbed(result.remove('interviews'));
      return result;
    }).toList();
  }

  /// Stars or un-stars an applicant. The flag and the note are private to HR.
  Future<void> setShortlisted(String applicationId, bool shortlisted) async {
    await _client.from('application_notes').upsert({'application_id': applicationId, 'shortlisted': shortlisted});
  }

  /// Saves HR's private note on an application (empty text clears it).
  Future<void> saveApplicantNote(String applicationId, String note) async {
    final trimmed = note.trim();
    await _client.from('application_notes').upsert({'application_id': applicationId, 'note': trimmed.isEmpty ? null : trimmed});
  }

  /// The full profile of one student who applied to this company: photo,
  /// contact details, studies, skills and resume. The database only lets HR
  /// read students who applied to their own company.
  Future<Map<String, dynamic>> getStudentProfile(String studentId) async {
    final row = await _client
        .from('students')
        .select('profile_id, programme, faculty, semester, cgpa, skills, student_reg_no, resume_path, resume_filename, '
            'profiles!students_profile_id_fkey(full_name, avatar_url, email, phone)')
        .eq('profile_id', studentId)
        .maybeSingle();
    if (row == null) throw Exception('This student profile is not available.');
    final result = Map<String, dynamic>.from(row);
    final profile = result.remove('profiles') as Map<String, dynamic>?;
    result['full_name'] = profile?['full_name'];
    result['avatar_url'] = profile?['avatar_url'];
    final email = profile?['email'] as String?;
    result['email'] = (email != null && email.endsWith('@deleted.invalid')) ? null : email;
    result['phone'] = profile?['phone'];
    return result;
  }

  Future<List<Map<String, dynamic>>> getStudentExperience(String studentId) async {
    final rows = await _client.from('work_experiences').select().eq('student_id', studentId).order('start_year', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
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
    final saved = await _client.from('documents').update({'storage_path': storagePath}).eq('document_id', documentId).select('document_id');
    if (List.from(saved).isEmpty) {
      throw Exception('The letter was uploaded but could not be saved on file. Please try again.');
    }

    try {
      await _client.from('notifications').insert({
        'user_id': studentId,
        'title': 'Offer letter uploaded',
        'body': '$fileName has been uploaded by your company.',
        'type': 'document',
        'related_id': documentId,
        'msg_key': 'offer_letter_uploaded',
        'msg_args': {'file': fileName},
      });
    } catch (_) {
      // Non-fatal — the upload itself already succeeded.
    }
  }

  /// Uploads an offer letter for ONE application (several companies can offer the same student, so the
  /// letter belongs to the application, not to the student). Returns the storage path; the caller saves it
  /// on the application together with the offer ([updateApplicationStatus]) or with [setApplicationOfferLetter].
  Future<String> uploadApplicationOfferLetter({
    required String applicationId,
    required String studentId,
    required File file,
    required String fileName,
  }) async {
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'dat';
    final path = '$studentId/offers/$applicationId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _client.storage.from('student_files').upload(path, file);
    return path;
  }

  /// Removes an uploaded letter that ended up unused (a failed offer, or the letter that was replaced).
  Future<void> removeStoredFile(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      await _client.storage.from('student_files').remove([path]);
    } catch (_) {
      // Not fatal: an orphaned file only takes up space.
    }
  }

  /// Attaches (or replaces) the letter of an offer that was already sent, before the student accepts.
  Future<void> setApplicationOfferLetter({
    required String applicationId,
    required String path,
    required String fileName,
    required int fileSizeBytes,
  }) async {
    await _client.from('applications').update({
      'offer_letter_path': path,
      'offer_letter_name': fileName,
      'offer_letter_size': fileSizeBytes,
    }).eq('application_id', applicationId);
  }

  /// Everything a letter can fill in by itself for an intern who accepted an offer from this company (migration 00055).
  Future<Map<String, dynamic>> getLetterContext(String applicationId) async {
    final result = await _client.rpc('letter_context', params: {'p_application': applicationId});
    return Map<String, dynamic>.from(result as Map);
  }

  /// The approved company supervisors of this HR's company (with how many interns each has), for assigning interns.
  Future<List<Map<String, dynamic>>> getCompanySupervisors() async {
    final rows = await _client.rpc('hr_company_supervisors');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// Assigns an intern (an accepted application) to a company supervisor of this company. Allowed until the intern
  /// has been evaluated; the database checks all of it.
  Future<void> assignCompanySupervisor({required String applicationId, required String supervisorId}) async {
    await _client.rpc('hr_assign_company_supervisor', params: {'p_application': applicationId, 'p_supervisor': supervisorId});
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
    final saved = await _client.from('documents').update({'storage_path': storagePath}).eq('document_id', documentId).select('document_id');
    if (List.from(saved).isEmpty) {
      throw Exception('The letter was uploaded but could not be saved on file. Please try again.');
    }

    try {
      await _client.from('notifications').insert({
        'user_id': studentId,
        'title': 'Document signed',
        'body': '$fileName has been signed by your company.',
        'type': 'document',
        'related_id': documentId,
        'msg_key': 'document_signed_company',
        'msg_args': {'file': fileName},
      });
    } catch (_) {
      // Non-fatal — the upload itself already succeeded.
    }
  }

  Future<void> updateApplicationStatus({
    required String applicationId,
    required String studentId,
    required String status,
    String? internshipTitle,
    String? rejectionReason,
    String? offerLetterPath,
    String? offerLetterName,
    int? offerLetterSize,
  }) async {
    // The database refuses a rejection without a reason (applications_guard),
    // so this is a second line of defence, not the only one.
    if (status == 'rejected' && (rejectionReason == null || rejectionReason.trim().length < kMinReasonLength)) {
      throw Exception('Please give a reason of at least $kMinReasonLength characters when rejecting an application.');
    }
    // An offer carries its offer letter (the database refuses an offer without one).
    if (status == 'offered' && (offerLetterPath == null || offerLetterPath.isEmpty)) {
      throw Exception('Upload the offer letter before making the offer.');
    }
    await _client.from('applications').update({
      'status': status,
      if (status == 'rejected') 'rejection_reason': rejectionReason!.trim(),
      if (status == 'offered') ...{
        'offer_letter_path': offerLetterPath,
        'offer_letter_name': offerLetterName,
        'offer_letter_size': offerLetterSize,
      },
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('application_id', applicationId);

    // Interviews are booked, moved and cancelled through InterviewService
    // (database functions), never by writing the interviews table directly.

    final roleLabel = internshipTitle ?? 'your application';
    String title;
    String body;
    String msgKey;
    final msgArgs = <String, String>{'role': roleLabel};
    switch (status) {
      case 'offered':
        msgKey = 'offer_received';
        title = 'You have an internship offer';
        body = 'Congratulations! You have been offered $roleLabel. Open My Applications to accept it. '
            'You can hold several offers, but once you accept one the others are closed.';
        break;
      case 'rejected':
        msgKey = 'application_rejected';
        msgArgs['reason'] = rejectionReason!.trim();
        title = 'Application update';
        body = 'Your application for $roleLabel was not successful this time. Reason: ${rejectionReason.trim()}';
        break;
      default:
        msgKey = 'application_update';
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
        'msg_key': msgKey,
        'msg_args': msgArgs,
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
  /// callers, not an error. A matched-but-not-applied student's `students`
  /// row is not readable by HR (profile visibility, migration 00023), so the
  /// path comes from the `get_candidate_resume` RPC (00025), which applies the
  /// same `can_view_resume` rule as the storage layer and returns nothing else.
  Future<Map<String, String>?> getCandidateResume(String candidateId) async {
    final rows = await _client.rpc('get_candidate_resume', params: {'p_student_id': candidateId});
    final list = List<Map<String, dynamic>>.from(rows as List);
    final row = list.isEmpty ? null : list.first;
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
