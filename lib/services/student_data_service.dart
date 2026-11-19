import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'interview_service.dart';
import 'package:flutter/foundation.dart';
import '../utils/posting_dates.dart';

/// Real data access for the student screens — internships, applications,
/// reports, documents, messaging, and notifications. Mirrors the singleton
/// + "throw Exception with a user-facing message" style of [AuthService].
///
/// Normalized-schema notes (Task 14):
/// - `internships` is now `job_postings`, joined to `companies` (for
///   `company_name`/`company_industry`, which used to be denormalized flat
///   columns) and `categories` (for the plain `category` string).
/// - Interview fields come from the `interviews` table, embedded alongside
///   `applications` and exposed on the returned map as `interview`, an
///   [InterviewInfo] (or null when no interview was ever booked).
/// - Report/document review status comes from `v_report_with_reviews` /
///   `v_document_with_review` and is flattened back onto `status`/`feedback`/
///   `company_review_status` so screen code is unchanged.
/// - Conversation membership is `profile_conversations`, not
///   `participant_a`/`participant_b` columns on `conversations` (which no
///   longer exist). Archive/mute/block are now the caller's own
///   `profile_conversations` row, not `_a`/`_b`-suffixed columns.
/// - Every table's primary key is now `<table_singular>_id` instead of `id`.
///   Screens still read `['id']` off returned maps in a few places, so an
///   `id` alias is added back onto each row before returning it.
class StudentDataService {
  StudentDataService._();
  static final StudentDataService instance = StudentDataService._();

  final SupabaseClient _client = Supabase.instance.client;

  String get _userId {
    final id = AuthService.instance.currentUserId;
    if (id == null) throw Exception('You must be logged in.');
    return id;
  }

  String _extensionOf(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : 'dat';
  }

  /// Adds an `id` key mirroring [idColumn] onto every row — screens still
  /// read `['id']` in several places and this keeps that stable without
  /// forcing every call site below to rebuild each map by hand.
  List<Map<String, dynamic>> _withIdAlias(List rows, [String idColumn = 'profile_id']) {
    final list = List<Map<String, dynamic>>.from(rows);
    for (final r in list) {
      r['id'] = r[idColumn];
    }
    return list;
  }

  /// Flattens a `job_postings` row's `companies`/`categories` embeds back
  /// onto the flat `company_name`/`company_industry`/`category` keys the
  /// old denormalized `internships` table used to expose directly, plus an
  /// `id` alias for `job_posting_id`. Mutates and returns [row].
  Map<String, dynamic> _flattenInternship(Map<String, dynamic> row) {
    row['id'] = row['job_posting_id'];
    final company = row['companies'] as Map<String, dynamic>?;
    row['company_name'] = company?['name'];
    row['company_industry'] = company?['industry'];
    final category = row['categories'] as Map<String, dynamic>?;
    row['category'] = category?['category_name'];
    return row;
  }

  // ---------------------------------------------------------------------
  // Internships / Applications
  // ---------------------------------------------------------------------

  /// All open postings. Small dataset — filtering (category/location/
  /// duration/allowance/search) happens client-side in the Search screen.
  Future<List<Map<String, dynamic>>> getOpenInternships() async {
    // Close what has passed its deadline first, so it never shows as open. The
    // posting is also hidden below in case that call cannot run.
    try {
      await _client.rpc('close_expired_postings');
    } catch (_) {}
    final rows = await _client
        .from('job_postings')
        .select('*, companies(name, industry, status), categories(category_name)')
        .eq('status', 'open')
        .order('posted_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows).where((r) => !_postingExpired(r)).map(_flattenInternship).toList();
  }

  static bool _postingExpired(Map<String, dynamic> posting) =>
      postingIsExpired(deadline: posting['application_deadline'] as String?, closesAt: posting['posting_closes_at'] as String?);

  /// Bumped whenever this student applies, withdraws or accepts an offer, so a
  /// screen that is kept alive in the background (Search) reloads which
  /// postings the student has applied to instead of showing stale "Applied".
  static final ValueNotifier<int> applicationsVersion = ValueNotifier<int>(0);

  /// job_posting_id set the current student has already applied to.
  Future<Set<String>> getAppliedInternshipIds() async {
    final rows = await _client
        .from('applications')
        .select('job_posting_id')
        .eq('student_id', _userId);
    return List<Map<String, dynamic>>.from(rows)
        .map((r) => r['job_posting_id'] as String)
        .toSet();
  }

  Future<List<Map<String, dynamic>>> getMyApplications() async {
    final rows = await _client
        .from('applications')
        .select(
            '*, internships:job_postings(*, companies(name, industry, status), categories(category_name)), interviews(${InterviewInfo.embed})')
        .eq('student_id', _userId)
        .order('applied_at', ascending: false);
    final list = List<Map<String, dynamic>>.from(rows);
    for (final r in list) {
      r['id'] = r['application_id'];
      final internship = r['internships'] as Map<String, dynamic>?;
      if (internship != null) _flattenInternship(internship);

      // `interviews.application_id` has a UNIQUE constraint, so PostgREST
      // treats applications->interviews as a to-one embed and returns a
      // single object (or null) here, not a list — casting it `as List?`
      // throws for every application that actually has an interview
      // scheduled, which silently emptied this whole screen via the
      // caller's try/catch. InterviewInfo.fromEmbed handles that shape.
      r['interview'] = InterviewInfo.fromEmbed(r.remove('interviews'));
    }
    return list;
  }

  Future<void> applyToInternship({
    required String internshipId,
    required String coverLetter,
    required List<String> skills,
  }) async {
    try {
      await _client.from('applications').insert({
        'student_id': _userId,
        'job_posting_id': internshipId,
        'cover_letter': coverLetter,
        'skills': skills,
      });
      applicationsVersion.value++;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('You have already applied to this internship.');
      }
      if (e.code == '42501') {
        throw Exception('This company hasn\'t been verified yet, so applications aren\'t open.');
      }
      // A deliberate rule from the database, written for people to read
      // (e.g. "You have already accepted an internship offer...").
      if (e.code == 'P0001') throw Exception(e.message);
      throw Exception('Could not submit application: ${e.message}');
    }
  }

  /// Accepts the internship offer on [applicationId]. The database does this
  /// atomically: the chosen application becomes `active` and every other open
  /// application of this student becomes `unavailable`.
  /// A short-lived link to the offer letter that came with an offer (read allowed by the student's own
  /// folder in the private bucket).
  Future<String> getOfferLetterUrl(String storagePath) => _client.storage.from('student_files').createSignedUrl(storagePath, 300);

  Future<void> acceptOffer(String applicationId) async {
    await _client.rpc('accept_offer', params: {'p_application_id': applicationId});
    applicationsVersion.value++;
  }

  /// A student may only withdraw an application that is still `pending`; the
  /// `applications_guard` trigger rejects deleting any other status.
  Future<void> withdrawApplication(String applicationId) async {
    // Ask for the deleted rows back: a delete that matches nothing (not allowed,
    // or already gone) must not look like a successful withdrawal.
    final deleted = await _client.from('applications').delete().eq('application_id', applicationId).select('application_id');
    if (List.from(deleted).isEmpty) {
      throw Exception('This application could not be withdrawn. It may already have moved on.');
    }
    applicationsVersion.value++;
  }

  /// Company details for the "view company before applying" step. Looks up
  /// via the internship's company_id; falls back to null (caller shows the
  /// inline company_name/industry already on the internship row instead).
  Future<Map<String, dynamic>?> getCompanyDetails(String? companyId) async {
    if (companyId == null) return null;
    return await _client.from('companies').select().eq('company_id', companyId).maybeSingle();
  }

  // ---------------------------------------------------------------------
  // Company profile: postings, past interns, ratings & reviews
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getCompanyPostings(String companyId) async {
    final rows = await _client.from('job_postings').select().eq('company_id', companyId).order('posted_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Count only, not names — avoids exposing other students' identities to
  /// anyone browsing a company's profile.
  ///
  /// NOTE: under the normalized schema's `applications_select_involved` RLS
  /// policy, an ordinary browsing student can only see their OWN
  /// application rows (not admin/supervisor/company-staff), so this
  /// count now silently undercounts for anyone who isn't already
  /// involved — see Task 14 report for detail and a suggested fix (a
  /// dedicated count-only RPC).
  Future<int> getCompanyInternCount(String companyId) async {
    final rows = await _client
        .from('applications')
        .select('student_id, job_postings!inner(company_id)')
        .eq('job_postings.company_id', companyId)
        .eq('status', 'active');
    return List<Map<String, dynamic>>.from(rows).map((r) => r['student_id']).toSet().length;
  }

  /// Rating + review text only — student_id is deliberately never selected
  /// here so reviews render anonymously even though each row is attributed
  /// internally (for the one-review-per-student uniqueness constraint).
  Future<List<Map<String, dynamic>>> getCompanyReviews(String companyId) async {
    final rows = await _client.from('company_reviews').select('rating, review, created_at').eq('company_id', companyId).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Whether the current student has ever applied to this company (the
  /// review-eligibility gate — matches company_reviews_insert_own's RLS).
  Future<bool> canReviewCompany(String companyId) async {
    final rows = await _client
        .from('applications')
        .select('application_id, job_postings!inner(company_id)')
        .eq('job_postings.company_id', companyId)
        .eq('student_id', _userId)
        .limit(1);
    return List.from(rows).isNotEmpty;
  }

  Future<Map<String, dynamic>?> getMyCompanyReview(String companyId) async {
    return await _client.from('company_reviews').select().eq('company_id', companyId).eq('student_id', _userId).maybeSingle();
  }

  Future<void> submitCompanyReview({required String companyId, required int rating, String? review}) async {
    await _client.from('company_reviews').upsert({
      'company_id': companyId,
      'student_id': _userId,
      'rating': rating,
      'review': review?.trim().isEmpty == true ? null : review?.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'company_id,student_id');
  }

  // ---------------------------------------------------------------------
  // Work experience
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getWorkExperience() async {
    final rows = await _client
        .from('work_experiences')
        .select()
        .eq('student_id', _userId)
        .order('start_year', ascending: false);
    return _withIdAlias(rows, 'work_experience_id');
  }

  Future<void> addWorkExperience({
    required String companyName,
    required String position,
    String? description,
    int? startYear,
    int? endYear,
    bool isCurrent = false,
  }) async {
    await _client.from('work_experiences').insert({
      'student_id': _userId,
      'company_name': companyName.trim(),
      'position': position.trim(),
      'description': description?.trim().isEmpty == true ? null : description?.trim(),
      'start_year': startYear,
      'end_year': isCurrent ? null : endYear,
      'is_current': isCurrent,
    });
  }

  Future<void> updateWorkExperience({
    required String id,
    required String companyName,
    required String position,
    String? description,
    int? startYear,
    int? endYear,
    bool isCurrent = false,
  }) async {
    await _client.from('work_experiences').update({
      'company_name': companyName.trim(),
      'position': position.trim(),
      'description': description?.trim().isEmpty == true ? null : description?.trim(),
      'start_year': startYear,
      'end_year': isCurrent ? null : endYear,
      'is_current': isCurrent,
    }).eq('work_experience_id', id);
  }

  Future<void> deleteWorkExperience(String id) async {
    await _client.from('work_experiences').delete().eq('work_experience_id', id);
  }

  // ---------------------------------------------------------------------
  // Reports
  // ---------------------------------------------------------------------

  /// Whether this student has been accepted into an internship
  /// (`applications.status = 'active'`) — the gate for submitting
  /// monthly/final reports.
  Future<bool> hasActiveInternship() async {
    final rows = await _client.from('applications').select('application_id').eq('student_id', _userId).eq('status', 'active').limit(1);
    return List.from(rows).isNotEmpty;
  }

  /// How many monthly reports this student's intake needs (its length in months) and how many are in. `required` is
  /// null when the student has no intake yet. (Migration 00054.)
  Future<Map<String, dynamic>> getReportRequirements() async {
    final result = await _client.rpc('my_report_requirements');
    return Map<String, dynamic>.from(result as Map);
  }

  Future<List<Map<String, dynamic>>> getMyReports() async {
    final rows = await _client
        .from('v_report_with_reviews')
        .select()
        .eq('student_id', _userId)
        .order('submitted_at', ascending: false);
    final list = List<Map<String, dynamic>>.from(rows);
    for (final r in list) {
      r['id'] = r['report_id'];
      // academic_status is null until a supervisor has ever touched the
      // review row for this report — default to 'submitted' to match the
      // old flat schema's default and keep the badge/accent logic unchanged.
      r['status'] = r['academic_status'] ?? 'submitted';
      r['feedback'] = r['academic_feedback'];
      r['company_review_status'] = r['company_status'];
    }
    return list;
  }

  Future<void> submitReport({
    required String type,
    required String periodLabel,
    String? notes,
    File? file,
    String? fileName,
    int? fileSizeBytes,
  }) async {
    // Defense in depth: the reports screen already hides/disables the
    // submit action for students without an active internship, but there's
    // no RLS check for this (reports_insert_own only checks student_id), so
    // re-check here too rather than relying on the UI gate alone.
    if (!await hasActiveInternship()) {
      throw Exception('You can only submit reports once you have been accepted into an internship.');
    }
    final inserted = await _client
        .from('reports')
        .insert({
          'student_id': _userId,
          'type': type,
          'period_label': periodLabel,
          'notes': notes,
        })
        .select()
        .single();
    final reportId = inserted['report_id'] as String;

    if (file != null && fileName != null && fileSizeBytes != null) {
      final ext = _extensionOf(fileName);
      final storagePath = '$_userId/reports/$reportId.$ext';
      await _client.storage.from('student_files').upload(storagePath, file);
      // NOTE: `reports` has no UPDATE RLS policy in the normalized schema —
      // see Task 14 report. This call succeeds (no exception) but silently
      // updates 0 rows, so the uploaded file above is orphaned in storage:
      // the report row's storage_path/file_name/file_size_bytes never
      // actually get linked to it, and the report will render as if no
      // attachment was uploaded.
      await _client.from('reports').update({
        'storage_path': storagePath,
        'file_name': fileName,
        'file_size_bytes': fileSizeBytes,
      }).eq('report_id', reportId);
    }

    await createSelfNotification(
      title: 'Report submitted',
      body: '$periodLabel has been submitted.',
      type: 'report',
      relatedId: reportId,
      msgKey: 'report_submitted',
      msgArgs: {'period': periodLabel},
    );
  }

  Future<String> getReportSignedUrl(String storagePath) async {
    return await _client.storage.from('student_files').createSignedUrl(storagePath, 300);
  }

  // ---------------------------------------------------------------------
  // Documents
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getMyDocuments() async {
    final rows = await _client
        .from('v_document_with_review')
        .select()
        .eq('student_id', _userId)
        .order('uploaded_at', ascending: false);
    return _withIdAlias(rows, 'document_id');
  }

  /// Uploads a document for [category]. Categories other than 'other' are
  /// singleton per student — an existing upload for that category is
  /// replaced (old storage object removed) rather than duplicated.
  Future<void> uploadDocument({
    required String category,
    String? title,
    required File file,
    required String fileName,
    required int fileSizeBytes,
  }) async {
    if (category != 'other') {
      final existing = await _client
          .from('documents')
          .select('document_id, storage_path')
          .eq('student_id', _userId)
          .eq('category', category)
          .maybeSingle();
      if (existing != null) {
        await removeDocument(existing['document_id'] as String, existing['storage_path'] as String);
      }
    }

    final inserted = await _client
        .from('documents')
        .insert({
          'student_id': _userId,
          'category': category,
          'title': title,
          'storage_path': '',
          'file_name': fileName,
          'file_size_bytes': fileSizeBytes,
        })
        .select()
        .single();
    final documentId = inserted['document_id'] as String;

    final ext = _extensionOf(fileName);
    final storagePath = '$_userId/documents/$documentId.$ext';
    await _client.storage.from('student_files').upload(storagePath, file);
    await _client.from('documents').update({'storage_path': storagePath}).eq('document_id', documentId);

    await createSelfNotification(
      title: 'Document uploaded',
      body: '$fileName has been uploaded.',
      type: 'document',
      relatedId: documentId,
      msgKey: 'document_uploaded',
      msgArgs: {'file': fileName},
    );
  }

  Future<void> removeDocument(String documentId, String storagePath) async {
    if (storagePath.isNotEmpty) {
      try {
        await _client.storage.from('student_files').remove([storagePath]);
      } catch (_) {
        // Non-fatal — proceed to clear the DB row regardless.
      }
    }
    // NOTE: `documents` has no DELETE RLS policy in the normalized schema —
    // see Task 14 report. This call succeeds (no exception) but silently
    // deletes 0 rows, so the document row survives even though its storage
    // object (above) was removed.
    await _client.from('documents').delete().eq('document_id', documentId);
  }

  Future<String> getDocumentSignedUrl(String storagePath) async {
    return await _client.storage.from('student_files').createSignedUrl(storagePath, 300);
  }

  /// Company name + job title for the student's current active (accepted)
  /// application — feeds the 'auto' fields on the company acceptance
  /// letter template. Returns null if the student has no active
  /// application (the acceptance letter isn't offered until they do).
  /// Everything a letter can fill in by itself, from this student's profile and accepted internship (migration 00055).
  Future<Map<String, dynamic>> getLetterContext() async {
    final result = await _client.rpc('letter_context');
    return Map<String, dynamic>.from(result as Map);
  }

  /// The IC number the student chose to keep on their profile (kept apart from the general student record).
  Future<String?> getMyIcNumber() async {
    final row = await _client.from('student_identity').select('ic_number').eq('profile_id', _userId).maybeSingle();
    final ic = (row?['ic_number'] as String?)?.trim();
    return (ic == null || ic.isEmpty) ? null : ic;
  }

  Future<void> saveMyIcNumber(String? ic) async {
    final value = (ic == null || ic.trim().isEmpty) ? null : ic.trim();
    await _client.from('student_identity').upsert({
      'profile_id': _userId,
      'ic_number': value,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'profile_id');
  }

  Future<Map<String, dynamic>?> getActiveApplicationSummary() async {
    final rows = await _client
        .from('applications')
        .select('application_id, job_postings(title, companies(name))')
        .eq('student_id', _userId)
        .eq('status', 'active')
        .limit(1);
    final list = List<Map<String, dynamic>>.from(rows);
    if (list.isEmpty) return null;
    final posting = list.first['job_postings'] as Map<String, dynamic>?;
    final company = posting?['companies'] as Map<String, dynamic>?;
    return {
      'job_title': posting?['title'] as String?,
      'company_name': company?['name'] as String?,
    };
  }

  /// Records a template-generated (filled + signed) PDF as this student's
  /// `documents` row for [category] — same singleton-per-category replace
  /// and insert-then-upload-then-patch flow as [uploadDocument] (the
  /// storage path embeds the generated `document_id`, so it can't be
  /// known before the row exists), but written straight to 'approved':
  /// these letters are never manually reviewed, so there's no 'submitted'
  /// state to pass through (see the offer_letter/indemnity_letter/
  /// company_acceptance_letter categories' design — sign or upload once,
  /// then always shown as on file, not pending action).
  Future<void> recordGeneratedDocument({
    required String category,
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    final existing = await _client
        .from('documents')
        .select('document_id, storage_path')
        .eq('student_id', _userId)
        .eq('category', category)
        .maybeSingle();
    if (existing != null) {
      await removeDocument(existing['document_id'] as String, existing['storage_path'] as String);
    }

    final inserted = await _client
        .from('documents')
        .insert({
          'student_id': _userId,
          'category': category,
          'status': 'approved',
          'storage_path': '',
          'file_name': fileName,
          'file_size_bytes': pdfBytes.length,
        })
        .select()
        .single();
    final documentId = inserted['document_id'] as String;

    final storagePath = '$_userId/documents/$documentId.pdf';
    await _client.storage.from('student_files').uploadBinary(
          storagePath,
          pdfBytes,
          fileOptions: const FileOptions(contentType: 'application/pdf'),
        );
    await _client.from('documents').update({'storage_path': storagePath}).eq('document_id', documentId);

    await createSelfNotification(
      title: 'Document signed',
      body: '$fileName has been signed and saved.',
      type: 'document',
      msgKey: 'document_signed_self',
      msgArgs: {'file': fileName},
    );
  }

  // ---------------------------------------------------------------------
  // Messaging
  // ---------------------------------------------------------------------

  /// The people the signed-in user may START a chat with. The rule lives in
  /// the database (`can_message`, migration 00038), so this list and what the
  /// database accepts can never disagree.
  Future<List<Map<String, dynamic>>> getDirectory() async {
    final ids = List<dynamic>.from(await _client.rpc('messageable_profile_ids') as List).map((e) => e.toString()).toList();
    if (ids.isEmpty) return [];
    final rows = await _client.from('profile_directory').select().inFilter('profile_id', ids).order('full_name', ascending: true);
    return _withIdAlias(rows);
  }

  /// One person as the chat screen needs them (name, avatar, role).
  Future<Map<String, dynamic>> getDirectoryProfile(String profileId) async {
    final row = await _client.from('profile_directory').select().eq('profile_id', profileId).single();
    return _withIdAlias([row]).first;
  }

  Future<List<Map<String, dynamic>>> getConversations({bool archived = false}) async {
    final me = _userId;

    // profile_conversations is the caller's own membership row — RLS
    // (`is_conversation_member`) already restricts every other query below
    // to conversations the caller belongs to, but starting from this table
    // also gives us the archived/muted/blocked flags server-side instead of
    // the old client-side `participant_a == me ? archived_a : archived_b`.
    final myLinks = await _client
        .from('profile_conversations')
        .select('conversation_id, archived, muted, blocked_by')
        .eq('profile_id', me)
        .eq('archived', archived);
    final myLinkList = List<Map<String, dynamic>>.from(myLinks);
    if (myLinkList.isEmpty) return [];
    final convoIds = myLinkList.map((l) => l['conversation_id'] as String).toList();

    final convos = await _client
        .from('conversations')
        .select()
        .inFilter('conversation_id', convoIds)
        .order('last_message_at', ascending: false);
    final convoList = List<Map<String, dynamic>>.from(convos);
    if (convoList.isEmpty) return [];

    final allMembers = await _client
        .from('profile_conversations')
        .select('conversation_id, profile_id')
        .inFilter('conversation_id', convoIds);
    final allMemberList = List<Map<String, dynamic>>.from(allMembers);
    final otherIdByConvo = <String, String?>{};
    for (final c in convoList) {
      final cid = c['conversation_id'] as String;
      final others = allMemberList.where((m) => m['conversation_id'] == cid && m['profile_id'] != me);
      otherIdByConvo[cid] = others.isEmpty ? null : others.first['profile_id'] as String;
    }
    final otherIds = otherIdByConvo.values.whereType<String>().toSet().toList();
    // People whose account was deleted are not shown in the chat list.
    if (otherIds.isNotEmpty) {
      final deleted = List<dynamic>.from(await _client.rpc('deleted_profiles', params: {'p_ids': otherIds}) as List).map((e) => e.toString()).toSet();
      if (deleted.isNotEmpty) {
        otherIdByConvo.updateAll((cid, other) => other != null && deleted.contains(other) ? null : other);
        otherIds.removeWhere(deleted.contains);
      }
    }
    final profiles = otherIds.isEmpty ? <Map<String, dynamic>>[] : _withIdAlias(await _client.from('profile_directory').select().inFilter('profile_id', otherIds));
    final profileById = {for (final p in profiles) p['profile_id'] as String: p};

    final convoIdsForMessages = convoList.map((c) => c['conversation_id'] as String).toList();
    final messages = await _client
        .from('messages')
        .select()
        .inFilter('conversation_id', convoIdsForMessages)
        .order('created_at', ascending: true);
    final messageList = _withIdAlias(messages, 'message_id');

    // Conversations with no resolvable other participant are "ghost" rows —
    // see getOrCreateConversation()'s catch block for how these get created
    // (profile_conversations/conversations have no DELETE policy, so they
    // can never be cleaned up once created). Screens force-cast
    // `other_profile` to a non-nullable Map, so these must never be
    // returned rather than returned with `other_profile: null`.
    return convoList
        .where((c) => otherIdByConvo[c['conversation_id'] as String] != null)
        .map((c) {
      final cid = c['conversation_id'] as String;
      final otherId = otherIdByConvo[cid]!;
      final theseMessages = messageList.where((m) => m['conversation_id'] == cid);
      final lastMessage = theseMessages.isEmpty ? null : theseMessages.last;
      final unreadCount = theseMessages.where((m) => m['sender_id'] != me && m['read_at'] == null).length;
      return {
        ...c,
        'id': cid,
        'other_profile': profileById[otherId],
        'last_message': lastMessage,
        'unread_count': unreadCount,
      };
    }).toList();
  }

  /// Opens the conversation with [otherUserId]. An existing one is always
  /// returned; a new one is only created when the database allows this person
  /// to start it (`start_conversation`, migration 00038) - otherwise this
  /// throws with the database's explanation.
  Future<Map<String, dynamic>> getOrCreateConversation(String otherUserId) async {
    final conversationId = (await _client.rpc('start_conversation', params: {'p_other': otherUserId})).toString();

    // A conversation you had archived comes back to your list when you open it again.
    final mine = await _client
        .from('profile_conversations')
        .select('archived')
        .eq('conversation_id', conversationId)
        .eq('profile_id', _userId)
        .maybeSingle();
    if (mine?['archived'] == true) {
      await setConversationArchived(conversationId, false);
    }

    final conversation = await _client.from('conversations').select().eq('conversation_id', conversationId).single();
    conversation['id'] = conversationId;
    return conversation;
  }

  /// Resolves a conversation id (as delivered in a push notification's data
  /// payload) into the shape ChatScreen needs — throws if the conversation
  /// doesn't exist or the signed-in user isn't one of its members (RLS
  /// already restricts the initial select to conversations the caller
  /// belongs to, so `.single()` throwing covers "not a participant" too).
  Future<Map<String, dynamic>> getConversationById(String conversationId) async {
    final me = _userId;
    final conversation = await _client.from('conversations').select().eq('conversation_id', conversationId).single();
    conversation['id'] = conversationId;

    final members = await _client.from('profile_conversations').select('profile_id').eq('conversation_id', conversationId);
    final otherIds = List<Map<String, dynamic>>.from(members).map((m) => m['profile_id'] as String).where((id) => id != me);
    if (otherIds.isEmpty) {
      throw Exception('Not a participant in this conversation.');
    }
    final otherProfile = await _client.from('profile_directory').select().eq('profile_id', otherIds.first).single();
    otherProfile['id'] = otherProfile['profile_id'];
    return {...conversation, 'other_profile': otherProfile};
  }

  Future<void> setConversationArchived(String conversationId, bool archived) async {
    await _client
        .from('profile_conversations')
        .update({'archived': archived})
        .eq('conversation_id', conversationId)
        .eq('profile_id', _userId);
  }

  Future<Map<String, dynamic>?> getChatContactInfo(String otherUserId) async {
    try {
      final rows = await _client.rpc('get_chat_contact_info', params: {'other_user_id': otherUserId});
      final list = List<Map<String, dynamic>>.from(rows as List);
      return list.isEmpty ? null : list.first;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getSharedMedia(String conversationId) async {
    final rows = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .not('attachment_path', 'is', null)
        .order('created_at', ascending: false);
    return _withIdAlias(rows, 'message_id');
  }

  Future<void> setConversationMuted(String conversationId, bool muted) async {
    await _client
        .from('profile_conversations')
        .update({'muted': muted})
        .eq('conversation_id', conversationId)
        .eq('profile_id', _userId);
  }

  Future<void> setConversationBlocked(String conversationId, bool blocked) async {
    await _client
        .from('profile_conversations')
        .update({'blocked_by': blocked})
        .eq('conversation_id', conversationId)
        .eq('profile_id', _userId);
  }

  /// NOTE: `conversations` has no DELETE (or UPDATE) RLS policy in the
  /// normalized schema — see Task 14 report. This call succeeds (no
  /// exception) but silently deletes 0 rows, so "delete conversation"
  /// currently does nothing observable to the database.
  Future<void> deleteConversation(String conversationId) async {
    await _client.from('conversations').delete().eq('conversation_id', conversationId);
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final rows = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
    return _withIdAlias(rows, 'message_id');
  }

  Stream<List<Map<String, dynamic>>> messagesStream(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['message_id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((rows) => rows.map((r) => {...r, 'id': r['message_id']}).toList());
  }

  Future<void> sendMessage({
    required String conversationId,
    String? body,
    String? attachmentPath,
    String? attachmentFileName,
    int? attachmentSizeBytes,
    String? clientMessageId,
  }) async {
    await _client.from('messages').insert({
      if (clientMessageId != null) 'message_id': clientMessageId,
      'conversation_id': conversationId,
      'sender_id': _userId,
      'body': (body == null || body.trim().isEmpty) ? null : body.trim(),
      'attachment_path': attachmentPath,
      'attachment_file_name': attachmentFileName,
      'attachment_size_bytes': attachmentSizeBytes,
    });
  }

  Future<void> editMessage(String messageId, String newBody) async {
    await _client.rpc('edit_message', params: {
      'p_message_id': messageId,
      'p_new_body': newBody.trim(),
    });
  }

  Future<void> deleteMessageForMe(String messageId) async {
    await _client.rpc('delete_message_for_me', params: {'p_message_id': messageId});
  }

  /// NOTE: `messages` has no DELETE RLS policy in the normalized schema —
  /// see Task 14 report. This call succeeds (no exception) but silently
  /// deletes 0 rows, so "delete for everyone" currently only removes the
  /// storage attachment (if any), not the message row itself.
  Future<void> deleteMessage(String messageId, {String? attachmentPath}) async {
    if (attachmentPath != null) {
      try {
        await _client.storage.from('chat_attachments').remove([attachmentPath]);
      } catch (_) {
        // Non-fatal — proceed to remove the message row regardless.
      }
    }
    await _client.from('messages').delete().eq('message_id', messageId);
  }

  /// Uploads a chat attachment and returns its storage path. The message
  /// row referencing it is inserted separately via [sendMessage].
  Future<String> uploadChatAttachment({
    required String conversationId,
    required File file,
    required String fileName,
  }) async {
    final ext = _extensionOf(fileName);
    final storagePath =
        '$conversationId/${DateTime.now().microsecondsSinceEpoch}_${_userId.substring(0, 8)}.$ext';
    await _client.storage.from('chat_attachments').upload(storagePath, file);
    return storagePath;
  }

  Future<String> getChatAttachmentSignedUrl(String storagePath) async {
    return await _client.storage.from('chat_attachments').createSignedUrl(storagePath, 300);
  }

  Future<void> markConversationRead(String conversationId) async {
    await _client
        .from('messages')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('conversation_id', conversationId)
        .neq('sender_id', _userId)
        .isFilter('read_at', null);
  }

  // ---------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getNotifications() async {
    // v_notifications (migration 00041) writes each notification in the language the person uses
    // now, so changing the language also changes the notifications already in the list.
    final rows = await _client
        .from('v_notifications')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return _withIdAlias(rows, 'notification_id');
  }

  Future<int> getUnreadNotificationCount() async {
    final rows = await _client
        .from('notifications')
        .select('notification_id')
        .eq('user_id', _userId)
        .eq('read', false);
    return List.from(rows).length;
  }

  Future<void> markNotificationRead(String id) async {
    await _client.from('notifications').update({'read': true}).eq('notification_id', id);
  }

  Future<void> markAllNotificationsRead() async {
    await _client
        .from('notifications')
        .update({'read': true})
        .eq('user_id', _userId)
        .eq('read', false);
  }

  Future<void> createSelfNotification({
    required String title,
    String? body,
    required String type,
    String? relatedId,
    String? msgKey,
    Map<String, String>? msgArgs,
  }) async {
    await _client.from('notifications').insert({
      'user_id': _userId,
      'title': title,
      'body': body,
      'type': type,
      'related_id': relatedId,
      if (msgKey != null) 'msg_key': msgKey,
      if (msgKey != null) 'msg_args': msgArgs ?? <String, String>{},
    });
  }

  // ---------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------

  Future<int> getUnreadMessageCount() async {
    final me = _userId;
    final convos = await _client
        .from('profile_conversations')
        .select('conversation_id')
        .eq('profile_id', me);
    final convoIds = List<Map<String, dynamic>>.from(convos).map((c) => c['conversation_id'] as String).toList();
    if (convoIds.isEmpty) return 0;

    final unread = await _client
        .from('messages')
        .select('message_id')
        .inFilter('conversation_id', convoIds)
        .neq('sender_id', me)
        .isFilter('read_at', null);
    return List.from(unread).length;
  }

  Future<Map<String, int>> getDashboardCounts() async {
    final applications = await _client.from('applications').select('status').eq('student_id', _userId);
    final applicationList = List<Map<String, dynamic>>.from(applications);
    final reports = await _client.from('reports').select('report_id').eq('student_id', _userId);
    final unreadNotifications = await getUnreadNotificationCount();
    final unreadMessages = await getUnreadMessageCount();

    return {
      'applications': applicationList.length,
      'interviews': applicationList.where((a) => a['status'] == 'interview').length,
      'reports': List.from(reports).length,
      'unreadNotifications': unreadNotifications,
      'unreadMessages': unreadMessages,
    };
  }
}
