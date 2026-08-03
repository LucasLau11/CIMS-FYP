import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

/// Real data access for the student screens — internships, applications,
/// reports, documents, messaging, and notifications. Mirrors the singleton
/// + "throw Exception with a user-facing message" style of [AuthService].
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

  // ---------------------------------------------------------------------
  // Internships / Applications
  // ---------------------------------------------------------------------

  /// All open postings. Small dataset — filtering (category/location/
  /// duration/allowance/search) happens client-side in the Search screen.
  Future<List<Map<String, dynamic>>> getOpenInternships() async {
    final rows = await _client
        .from('internships')
        .select('*, companies(status)')
        .eq('status', 'open')
        .order('posted_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// internship_id set the current student has already applied to.
  Future<Set<String>> getAppliedInternshipIds() async {
    final rows = await _client
        .from('applications')
        .select('internship_id')
        .eq('student_id', _userId);
    return List<Map<String, dynamic>>.from(rows)
        .map((r) => r['internship_id'] as String)
        .toSet();
  }

  Future<List<Map<String, dynamic>>> getMyApplications() async {
    final rows = await _client
        .from('applications')
        .select('*, internships(*)')
        .eq('student_id', _userId)
        .order('applied_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> applyToInternship({
    required String internshipId,
    required String coverLetter,
    required List<String> skills,
  }) async {
    try {
      await _client.from('applications').insert({
        'student_id': _userId,
        'internship_id': internshipId,
        'cover_letter': coverLetter,
        'skills': skills,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('You have already applied to this internship.');
      }
      if (e.code == '42501') {
        throw Exception('This company hasn\'t been verified yet, so applications aren\'t open.');
      }
      throw Exception('Could not submit application: ${e.message}');
    }
  }

  Future<void> withdrawApplication(String applicationId) async {
    await _client.from('applications').delete().eq('id', applicationId);
  }

  /// Company details for the "view company before applying" step. Looks up
  /// via the internship's company_id; falls back to null (caller shows the
  /// inline company_name/industry already on the internship row instead).
  Future<Map<String, dynamic>?> getCompanyDetails(String? companyId) async {
    if (companyId == null) return null;
    return await _client.from('companies').select().eq('id', companyId).maybeSingle();
  }

  // ---------------------------------------------------------------------
  // Company profile: postings, past interns, ratings & reviews
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getCompanyPostings(String companyId) async {
    final rows = await _client.from('internships').select().eq('company_id', companyId).order('posted_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Count only, not names — avoids exposing other students' identities to
  /// anyone browsing a company's profile.
  Future<int> getCompanyInternCount(String companyId) async {
    final rows = await _client
        .from('applications')
        .select('student_id, internships!inner(company_id)')
        .eq('internships.company_id', companyId)
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
    final rows = await _client.from('applications').select('id, internships!inner(company_id)').eq('internships.company_id', companyId).eq('student_id', _userId).limit(1);
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
    return List<Map<String, dynamic>>.from(rows);
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
    }).eq('id', id);
  }

  Future<void> deleteWorkExperience(String id) async {
    await _client.from('work_experiences').delete().eq('id', id);
  }

  // ---------------------------------------------------------------------
  // Reports
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getMyReports() async {
    final rows = await _client
        .from('reports')
        .select()
        .eq('student_id', _userId)
        .order('submitted_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> submitReport({
    required String type,
    required String periodLabel,
    String? notes,
    File? file,
    String? fileName,
    int? fileSizeBytes,
  }) async {
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

    if (file != null && fileName != null && fileSizeBytes != null) {
      final ext = _extensionOf(fileName);
      final storagePath = '$_userId/reports/${inserted['id']}.$ext';
      await _client.storage.from('student_files').upload(storagePath, file);
      await _client.from('reports').update({
        'storage_path': storagePath,
        'file_name': fileName,
        'file_size_bytes': fileSizeBytes,
      }).eq('id', inserted['id']);
    }

    await createSelfNotification(
      title: 'Report submitted',
      body: '$periodLabel has been submitted.',
      type: 'report',
      relatedId: inserted['id'] as String,
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
        .from('documents')
        .select()
        .eq('student_id', _userId)
        .order('uploaded_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
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
          .select('id, storage_path')
          .eq('student_id', _userId)
          .eq('category', category)
          .maybeSingle();
      if (existing != null) {
        await removeDocument(existing['id'] as String, existing['storage_path'] as String);
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

    final ext = _extensionOf(fileName);
    final storagePath = '$_userId/documents/${inserted['id']}.$ext';
    await _client.storage.from('student_files').upload(storagePath, file);
    await _client.from('documents').update({'storage_path': storagePath}).eq('id', inserted['id']);

    await createSelfNotification(
      title: 'Document uploaded',
      body: '$fileName has been uploaded.',
      type: 'document',
      relatedId: inserted['id'] as String,
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
    await _client.from('documents').delete().eq('id', documentId);
  }

  Future<String> getDocumentSignedUrl(String storagePath) async {
    return await _client.storage.from('student_files').createSignedUrl(storagePath, 300);
  }

  // ---------------------------------------------------------------------
  // Messaging
  // ---------------------------------------------------------------------

  /// Other real accounts available to start a conversation with — scoped
  /// by the caller's own role. Only admin/academic_supervisor/company_hr
  /// get a non-empty list; every other role gets [] (matches the
  /// conversations_insert_participant RLS policy, which blocks those
  /// roles from creating a new conversation at all regardless of what
  /// this method returns — this scoping is for a correct/uncluttered UI
  /// list, not the actual security boundary).
  Future<List<Map<String, dynamic>>> getDirectory() async {
    final profile = await _client.from('profiles').select('role, company_id').eq('id', _userId).single();
    final role = profile['role'] as String;

    switch (role) {
      case 'admin':
        final rows = await _client.from('profile_directory').select().neq('id', _userId).order('full_name', ascending: true);
        return List<Map<String, dynamic>>.from(rows);
      case 'academic_supervisor':
        final rows = await _client
            .from('profiles')
            .select('id, full_name, avatar_url, role')
            .eq('role', 'student')
            .eq('academic_supervisor_id', _userId)
            .order('full_name', ascending: true);
        return List<Map<String, dynamic>>.from(rows);
      case 'company_hr':
        final companyId = profile['company_id'] as String?;
        if (companyId == null) return [];
        final rows = await _client
            .from('profiles')
            .select('id, full_name, avatar_url, role')
            .eq('role', 'company_supervisor')
            .eq('company_id', companyId)
            .order('full_name', ascending: true);
        return List<Map<String, dynamic>>.from(rows);
      case 'parent':
        final links = await _client.from('parent_child_links').select('student_id').eq('parent_id', _userId).eq('status', 'approved');
        final childIds = List<Map<String, dynamic>>.from(links).map((l) => l['student_id'] as String).toList();
        if (childIds.isEmpty) return [];
        final rows = await _client.from('profile_directory').select().inFilter('id', childIds).order('full_name', ascending: true);
        return List<Map<String, dynamic>>.from(rows);
      default:
        return [];
    }
  }

  Future<List<Map<String, dynamic>>> getConversations({bool archived = false}) async {
    final me = _userId;
    final convos = await _client
        .from('conversations')
        .select()
        .or('participant_a.eq.$me,participant_b.eq.$me')
        .order('last_message_at', ascending: false);
    final convoList = List<Map<String, dynamic>>.from(convos).where((c) {
      final isArchived = c['participant_a'] == me ? c['archived_a'] as bool : c['archived_b'] as bool;
      return isArchived == archived;
    }).toList();
    if (convoList.isEmpty) return [];

    final otherIds = convoList
        .map((c) => c['participant_a'] == me ? c['participant_b'] : c['participant_a'])
        .toSet()
        .toList();
    final profiles = await _client.from('profile_directory').select().inFilter('id', otherIds);
    final profileById = {for (final p in List<Map<String, dynamic>>.from(profiles)) p['id'] as String: p};

    final convoIds = convoList.map((c) => c['id'] as String).toList();
    final messages = await _client
        .from('messages')
        .select()
        .inFilter('conversation_id', convoIds)
        .order('created_at', ascending: true);
    final messageList = List<Map<String, dynamic>>.from(messages);

    return convoList.map((c) {
      final otherId = c['participant_a'] == me ? c['participant_b'] : c['participant_a'];
      final theseMessages = messageList.where((m) => m['conversation_id'] == c['id']);
      final lastMessage = theseMessages.isEmpty ? null : theseMessages.last;
      final unreadCount =
          theseMessages.where((m) => m['sender_id'] != me && m['read_at'] == null).length;
      return {
        ...c,
        'other_profile': profileById[otherId],
        'last_message': lastMessage,
        'unread_count': unreadCount,
      };
    }).toList();
  }

  Future<Map<String, dynamic>> getOrCreateConversation(String otherUserId) async {
    final me = _userId;
    final a = me.compareTo(otherUserId) < 0 ? me : otherUserId;
    final b = me.compareTo(otherUserId) < 0 ? otherUserId : me;

    final existing = await _client
        .from('conversations')
        .select()
        .eq('participant_a', a)
        .eq('participant_b', b)
        .maybeSingle();
    if (existing != null) {
      // Starting a fresh conversation with someone you'd previously
      // archived should surface it again.
      final myArchiveColumn = a == me ? 'archived_a' : 'archived_b';
      if (existing[myArchiveColumn] == true) {
        await setConversationArchived(existing['id'] as String, false);
        existing[myArchiveColumn] = false;
      }
      return existing;
    }

    return await _client
        .from('conversations')
        .insert({'participant_a': a, 'participant_b': b})
        .select()
        .single();
  }

  /// Resolves a conversation id (as delivered in a push notification's data
  /// payload) into the shape ChatScreen needs — throws if the conversation
  /// doesn't exist or the signed-in user isn't one of its two participants.
  Future<Map<String, dynamic>> getConversationById(String conversationId) async {
    final me = _userId;
    final conversation = await _client.from('conversations').select().eq('id', conversationId).single();
    final participantA = conversation['participant_a'] as String;
    final participantB = conversation['participant_b'] as String;
    if (participantA != me && participantB != me) {
      throw Exception('Not a participant in this conversation.');
    }
    final otherId = participantA == me ? participantB : participantA;
    final otherProfile = await _client.from('profile_directory').select().eq('id', otherId).single();
    return {...conversation, 'other_profile': otherProfile};
  }

  Future<void> setConversationArchived(String conversationId, bool archived) async {
    final me = _userId;
    final convo = await _client
        .from('conversations')
        .select('participant_a')
        .eq('id', conversationId)
        .single();
    final myArchiveColumn = convo['participant_a'] == me ? 'archived_a' : 'archived_b';
    await _client.from('conversations').update({myArchiveColumn: archived}).eq('id', conversationId);
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
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> setConversationMuted(String conversationId, bool muted) async {
    final me = _userId;
    final convo = await _client.from('conversations').select('participant_a').eq('id', conversationId).single();
    final myMuteColumn = convo['participant_a'] == me ? 'muted_a' : 'muted_b';
    await _client.from('conversations').update({myMuteColumn: muted}).eq('id', conversationId);
  }

  Future<void> setConversationBlocked(String conversationId, bool blocked) async {
    final me = _userId;
    final convo = await _client.from('conversations').select('participant_a').eq('id', conversationId).single();
    final myBlockColumn = convo['participant_a'] == me ? 'blocked_by_a' : 'blocked_by_b';
    await _client.from('conversations').update({myBlockColumn: blocked}).eq('id', conversationId);
  }

  Future<void> deleteConversation(String conversationId) async {
    await _client.from('conversations').delete().eq('id', conversationId);
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final rows = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  Stream<List<Map<String, dynamic>>> messagesStream(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
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
      if (clientMessageId != null) 'id': clientMessageId,
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

  Future<void> deleteMessage(String messageId, {String? attachmentPath}) async {
    if (attachmentPath != null) {
      try {
        await _client.storage.from('chat_attachments').remove([attachmentPath]);
      } catch (_) {
        // Non-fatal — proceed to remove the message row regardless.
      }
    }
    await _client.from('messages').delete().eq('id', messageId);
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
    final rows = await _client
        .from('notifications')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<int> getUnreadNotificationCount() async {
    final rows = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', _userId)
        .eq('read', false);
    return List.from(rows).length;
  }

  Future<void> markNotificationRead(String id) async {
    await _client.from('notifications').update({'read': true}).eq('id', id);
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
  }) async {
    await _client.from('notifications').insert({
      'user_id': _userId,
      'title': title,
      'body': body,
      'type': type,
      'related_id': relatedId,
    });
  }

  /// Approves or rejects a pending parent-link request addressed to this
  /// student. [requestId] is the `parent_child_links.id`, which is also the
  /// notification's `related_id`.
  Future<void> respondToParentLinkRequest({required String requestId, required bool approve}) async {
    await _client
        .from('parent_child_links')
        .update({'status': approve ? 'approved' : 'rejected', 'responded_at': DateTime.now().toIso8601String()})
        .eq('id', requestId)
        .eq('status', 'pending');
  }

  // ---------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------

  Future<int> getUnreadMessageCount() async {
    final me = _userId;
    final convos = await _client
        .from('conversations')
        .select('id')
        .or('participant_a.eq.$me,participant_b.eq.$me');
    final convoIds = List<Map<String, dynamic>>.from(convos).map((c) => c['id'] as String).toList();
    if (convoIds.isEmpty) return 0;

    final unread = await _client
        .from('messages')
        .select('id')
        .inFilter('conversation_id', convoIds)
        .neq('sender_id', me)
        .isFilter('read_at', null);
    return List.from(unread).length;
  }

  Future<Map<String, int>> getDashboardCounts() async {
    final applications = await _client.from('applications').select('id, status').eq('student_id', _userId);
    final applicationList = List<Map<String, dynamic>>.from(applications);
    final reports = await _client.from('reports').select('id').eq('student_id', _userId);
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
