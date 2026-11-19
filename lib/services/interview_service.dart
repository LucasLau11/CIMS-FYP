import 'package:supabase_flutter/supabase_flutter.dart';

/// One bookable interview time, as computed by the `interview_free_slots`
/// database function from an HR person's weekly availability.
class InterviewSlot {
  final DateTime start;
  final DateTime end;

  const InterviewSlot({required this.start, required this.end});

  int get minutes => end.difference(start).inMinutes;

  factory InterviewSlot.fromRow(Map<String, dynamic> row) => InterviewSlot(
        start: DateTime.parse(row['slot_start'] as String).toLocal(),
        end: DateTime.parse(row['slot_end'] as String).toLocal(),
      );
}

/// An interview's current state plus the reason behind its latest change,
/// flattened out of the `interviews(... interview_changes(...))` embed.
class InterviewInfo {
  final String id;
  final String? interviewerId;
  final DateTime start;
  final DateTime end;
  final String mode;
  final String? location;

  /// 'scheduled', 'cancelled' or 'completed'.
  final String status;

  /// Every booking, reschedule request and cancellation, oldest first.
  final List<InterviewChange> changes;

  /// Every reschedule request ever made for this interview, oldest first.
  final List<RescheduleRequest> requests;

  const InterviewInfo({
    required this.id,
    required this.interviewerId,
    required this.start,
    required this.end,
    required this.mode,
    required this.location,
    required this.status,
    required this.changes,
    this.requests = const [],
  });

  bool get isScheduled => status == 'scheduled';
  bool get isCancelled => status == 'cancelled';

  /// Interviews can only be changed until two hours before they start (the
  /// database enforces the same rule).
  bool get canBeChanged => isScheduled && start.difference(DateTime.now()) >= const Duration(hours: 2);

  /// The reschedule request waiting for the other side's answer, if any. The
  /// interview stays where it is until that request is accepted.
  RescheduleRequest? get pendingRequest {
    if (!isScheduled) return null;
    for (final r in requests.reversed) {
      if (r.isPending) return r;
    }
    return null;
  }

  /// The most recent reschedule or cancellation, which carries a reason.
  InterviewChange? get lastReasonedChange {
    for (final c in changes.reversed) {
      if (c.reason != null && c.reason!.isNotEmpty) return c;
    }
    return null;
  }

  /// Reads the embed PostgREST returns for `interviews(...)`. The column is
  /// UNIQUE per application, so it arrives as one object or null, not a list.
  static InterviewInfo? fromEmbed(dynamic raw) {
    if (raw is! Map) return null;
    final row = Map<String, dynamic>.from(raw);
    final changes = (row['interview_changes'] as List? ?? [])
        .map((c) => InterviewChange.fromRow(Map<String, dynamic>.from(c as Map)))
        .toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    return InterviewInfo(
      id: row['interview_id'] as String,
      interviewerId: row['interviewer_id'] as String?,
      start: DateTime.parse(row['scheduled_at'] as String).toLocal(),
      end: DateTime.parse(row['ends_at'] as String).toLocal(),
      mode: (row['mode'] as String?) ?? 'online',
      location: row['location'] as String?,
      status: (row['status'] as String?) ?? 'scheduled',
      changes: changes,
      requests: (row['interview_reschedule_requests'] as List? ?? [])
          .map((r) => RescheduleRequest.fromRow(Map<String, dynamic>.from(r as Map)))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
    );
  }

  /// Column list to put inside `interviews(...)` in a select.
  static const String embed =
      'interview_id, interviewer_id, scheduled_at, ends_at, mode, location, status, '
      'interview_changes(action, actor_role, reason, old_start, new_start, created_at), '
      'interview_reschedule_requests(request_id, requested_by, requested_role, proposed_start, proposed_end, reason, status, response_note, created_at)';
}

/// One request to move an interview. It only takes effect once the other side
/// accepts; until then the interview keeps its time.
class RescheduleRequest {
  const RescheduleRequest({
    required this.id,
    required this.requestedBy,
    required this.requestedRole,
    required this.proposedStart,
    required this.proposedEnd,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.responseNote,
  });

  final String id;
  final String requestedBy;

  /// 'student' or 'company_hr'.
  final String requestedRole;
  final DateTime proposedStart;
  final DateTime proposedEnd;
  final String reason;

  /// 'pending', 'accepted', 'declined', 'withdrawn' or 'expired'.
  final String status;
  final DateTime createdAt;
  final String? responseNote;

  bool get isPending => status == 'pending';
  bool get byStudent => requestedRole == 'student';

  factory RescheduleRequest.fromRow(Map<String, dynamic> row) => RescheduleRequest(
        id: row['request_id'] as String,
        requestedBy: row['requested_by'] as String,
        requestedRole: row['requested_role'] as String,
        proposedStart: DateTime.parse(row['proposed_start'] as String).toLocal(),
        proposedEnd: DateTime.parse(row['proposed_end'] as String).toLocal(),
        reason: (row['reason'] as String?) ?? '',
        status: (row['status'] as String?) ?? 'pending',
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
        responseNote: row['response_note'] as String?,
      );
}

class InterviewChange {
  /// 'booked', 'rescheduled', 'cancelled' or 'auto_cancelled'.
  final String action;
  final String? actorRole;
  final String? reason;
  final DateTime? oldStart;
  final DateTime? newStart;
  final DateTime at;

  const InterviewChange({
    required this.action,
    required this.actorRole,
    required this.reason,
    required this.oldStart,
    required this.newStart,
    required this.at,
  });

  factory InterviewChange.fromRow(Map<String, dynamic> row) => InterviewChange(
        action: row['action'] as String,
        actorRole: row['actor_role'] as String?,
        reason: row['reason'] as String?,
        oldStart: row['old_start'] == null ? null : DateTime.parse(row['old_start'] as String).toLocal(),
        newStart: row['new_start'] == null ? null : DateTime.parse(row['new_start'] as String).toLocal(),
        at: DateTime.parse(row['created_at'] as String).toLocal(),
      );

  String get actorLabel => actorRole == 'student' ? 'The student' : (actorRole == null ? 'The system' : 'The company');

  /// "Asked to move", "Declined moving" ... for the history list.
  String get verb {
    switch (action) {
      case 'reschedule_requested':
        return 'asked to move the interview';
      case 'reschedule_declined':
        return 'declined moving the interview';
      case 'rescheduled':
        return 'moved the interview';
      case 'auto_cancelled':
        return 'cancelled the interview automatically';
      case 'cancelled':
        return 'cancelled the interview';
      default:
        return 'booked the interview';
    }
  }
}

/// Interview scheduling calls shared by the HR and student screens. Every
/// write goes through a database function (`book_interview`,
/// `reschedule_interview`, `cancel_interview`) that checks who may act,
/// enforces the reason and the 2-hour cutoff, prevents double booking and
/// notifies the other side.
class InterviewService {
  InterviewService._();
  static final InterviewService instance = InterviewService._();

  final SupabaseClient _client = Supabase.instance.client;

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// The current state of one interview, including its change history and
  /// reschedule requests. Screens call this when they open so they never act
  /// on a copy that was loaded before the other side answered a request.
  Future<InterviewInfo?> fetch(String interviewId) async {
    final row = await _client.from('interviews').select(InterviewInfo.embed).eq('interview_id', interviewId).maybeSingle();
    return InterviewInfo.fromEmbed(row);
  }

  /// Free slots of [interviewerId] from [from] to [to] (at most 60 days).
  Future<List<InterviewSlot>> freeSlots(String interviewerId, DateTime from, DateTime to) async {
    final rows = await _client.rpc('interview_free_slots', params: {
      'p_interviewer': interviewerId,
      'p_from': _date(from),
      'p_to': _date(to),
    });
    return List<Map<String, dynamic>>.from(rows as List).map(InterviewSlot.fromRow).toList();
  }

  Future<void> book({
    required String applicationId,
    required DateTime start,
    required String mode,
    required String location,
  }) async {
    await _client.rpc('book_interview', params: {
      'p_application_id': applicationId,
      'p_start': start.toUtc().toIso8601String(),
      'p_mode': mode,
      'p_location': location,
    });
  }

  /// Asks the other side to move the interview. Nothing moves until they accept.
  Future<void> requestReschedule({
    required String interviewId,
    required DateTime newStart,
    required String reason,
  }) async {
    await _client.rpc('request_reschedule', params: {
      'p_interview_id': interviewId,
      'p_new_start': newStart.toUtc().toIso8601String(),
      'p_reason': reason,
    });
  }

  /// Answers a request made by the other side: accepting moves the interview,
  /// declining (with a reason of at least 100 characters) leaves it as it is.
  Future<void> respondToReschedule({required String requestId, required bool accept, String? note}) async {
    await _client.rpc('respond_reschedule', params: {
      'p_request_id': requestId,
      'p_accept': accept,
      'p_note': note,
    });
  }

  Future<void> withdrawRescheduleRequest(String requestId) async {
    await _client.rpc('withdraw_reschedule_request', params: {'p_request_id': requestId});
  }

  Future<void> cancel({required String interviewId, required String reason}) async {
    await _client.rpc('cancel_interview', params: {
      'p_interview_id': interviewId,
      'p_reason': reason,
    });
  }

  // ---------------------------------------------------------------------
  // HR availability
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getAvailability(String hrId) async {
    final rows = await _client
        .from('hr_availability')
        .select()
        .eq('hr_id', hrId)
        .order('weekday')
        .order('start_time');
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Adds the same window on each of [weekdays] (1 = Monday ... 7 = Sunday).
  Future<void> addAvailability({
    required String hrId,
    required List<int> weekdays,
    required String startTime,
    required String endTime,
    required int slotMinutes,
  }) async {
    await _client.from('hr_availability').insert([
      for (final d in weekdays)
        {'hr_id': hrId, 'weekday': d, 'start_time': startTime, 'end_time': endTime, 'slot_minutes': slotMinutes},
    ]);
  }

  Future<void> deleteAvailability(String availabilityId) async {
    await _client.from('hr_availability').delete().eq('availability_id', availabilityId);
  }

  Future<List<Map<String, dynamic>>> getBlockedDates(String hrId) async {
    final rows = await _client
        .from('hr_unavailable_dates')
        .select()
        .eq('hr_id', hrId)
        .gte('blocked_on', _date(DateTime.now()))
        .order('blocked_on');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> addBlockedDate({required String hrId, required DateTime date, String? reason}) async {
    await _client.from('hr_unavailable_dates').upsert({
      'hr_id': hrId,
      'blocked_on': _date(date),
      'reason': (reason == null || reason.trim().isEmpty) ? null : reason.trim(),
    });
  }

  Future<void> removeBlockedDate({required String hrId, required String blockedOn}) async {
    await _client.from('hr_unavailable_dates').delete().eq('hr_id', hrId).eq('blocked_on', blockedOn);
  }
}
