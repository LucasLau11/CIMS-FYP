import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'supervisor_data_service.dart';

/// Real data access for the admin screens. Same singleton style as the
/// other *_data_service classes. Reuses [SupervisorDataService] for
/// reviews/monitor (reports+documents approve/reject) rather than
/// duplicating it — admin's RLS grants the same cross-cutting visibility
/// supervisors have, so the exact same queries work unchanged.
///
/// Normalized-schema notes (Task 17):
/// - `companies` PK is now `company_id`, not `id` — every companies query
///   below aliases it back to `id` for the screens (which still read
///   `data['id']`), and every write keys off `company_id`.
/// - Students/supervisors cross-role listings now join `profiles` to the
///   matching subtype table (`students`/`academic_supervisors`) instead of
///   reading a single flat `profiles` row — `programme`/`semester`/
///   `faculty`/`academic_supervisor_id` all moved to `students`; supervisors
///   have no `faculty` column at all in the new schema (that concept never
///   existed for the `academic_supervisors` subtype — it only ever applied
///   to students), so `getSupervisors()` no longer selects it and the
///   screen's own `?? 'Faculty not set'` fallback covers the gap.
/// - **The known Task 15-flagged bug is fixed here:** `assignSupervisor()`
///   used to write `profiles.academic_supervisor_id`, a column that does
///   not exist on `profiles` at all in the new schema (only `students` has
///   it) — that write failed outright, which is why `students
///   .academic_supervisor_id` had 0 rows set platform-wide and every
///   academic supervisor saw an empty roster. Fixed to write
///   `students.academic_supervisor_id` instead, via
///   `students_update_own_or_staff` (already permits admin to update any
///   student row — no new policy needed for this specific fix).
/// - `promoteToAdmin()` now calls the `promote_to_admin(uuid)` RPC
///   (migration `00012_task17_subtype_delete_policies_and_promote_to_admin
///   .sql`) instead of a raw client-side `profiles.role` update. That RPC
///   also deletes the old `academic_supervisors` row and inserts the new
///   `administrators` row, all in one transaction — a raw role update alone
///   would violate the subtype role-consistency trigger and leave a stale
///   `academic_supervisors` row with no matching `profiles.role` behind.
/// - Every table's primary key is now `<table_singular>_id` instead of
///   `id`. Screens still read `['id']` off returned maps, so an `id` alias
///   is added back onto each row before returning it, matching the
///   established Task 13-16 convention.
class AdminDataService {
  AdminDataService._();
  static final AdminDataService instance = AdminDataService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// Accounts and companies on the platform and how they grew (migration 00039).
  Future<Map<String, dynamic>> getPlatformStats() async {
    final result = await _client.rpc('admin_platform_stats');
    return Map<String, dynamic>.from(result as Map);
  }

  // ---------------------------------------------------------------------
  // Companies
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getCompanies() async {
    final rows = await _client.from('companies').select().order('name');
    final list = List<Map<String, dynamic>>.from(rows);
    for (final c in list) {
      c['id'] = c['company_id'];
    }
    return list;
  }

  Future<void> addCompany({
    required String name,
    String? industry,
    String? location,
    String? hrContactName,
    String? hrContactEmail,
    String? hrContactPhone,
  }) async {
    await _client.from('companies').insert({
      'name': name,
      'industry': industry,
      'location': location,
      'hr_contact_name': hrContactName,
      'hr_contact_email': hrContactEmail,
      'hr_contact_phone': hrContactPhone,
    });
  }

  Future<void> updateCompany({
    required String id,
    required String name,
    String? industry,
    String? location,
    String? hrContactName,
    String? hrContactEmail,
    String? hrContactPhone,
  }) async {
    await _client.from('companies').update({
      'name': name,
      'industry': industry,
      'location': location,
      'hr_contact_name': hrContactName,
      'hr_contact_email': hrContactEmail,
      'hr_contact_phone': hrContactPhone,
    }).eq('company_id', id);
  }

  Future<void> verifyCompany(String id) async {
    await _client.rpc('admin_set_company_status', params: {'p_company': id, 'p_status': 'verified'});
  }

  /// Turns a company down with a reason (100 to 500 characters) that its HR people are told.
  Future<void> rejectCompany(String id, String reason) async {
    await _client.rpc('admin_set_company_status', params: {'p_company': id, 'p_status': 'rejected', 'p_note': reason});
  }

  Future<void> deleteCompany(String id) async {
    await _client.from('companies').delete().eq('company_id', id);
  }

  // ---------------------------------------------------------------------
  // Students / Supervisors / assignment
  // ---------------------------------------------------------------------

  /// When each account last signed in (null = never has). Administrators only.
  Future<Map<String, DateTime?>> _lastSignIns() async {
    try {
      final rows = List<Map<String, dynamic>>.from(await _client.rpc('admin_account_activity') as List);
      return {
        for (final r in rows) r['profile_id'] as String: r['last_sign_in_at'] == null ? null : DateTime.parse(r['last_sign_in_at'] as String),
      };
    } catch (_) {
      return {};
    }
  }

  static bool _isDeleted(Map<String, dynamic>? profile) => ((profile?['email'] as String?) ?? '').endsWith('@deleted.invalid');

  Future<List<Map<String, dynamic>>> getStudents() async {
    final rows = await _client.from('students').select(
        'profile_id, programme, semester, faculty, academic_supervisor_id, '
        'own_profile:profiles!students_profile_id_fkey(full_name, email), '
        'supervisor_profile:profiles!students_academic_supervisor_id_fkey(full_name)');
    final activity = await _lastSignIns();
    // Accounts a person deleted themselves are not listed.
    final list = List<Map<String, dynamic>>.from(rows).where((s) => !_isDeleted(s['own_profile'] as Map<String, dynamic>?)).toList();

    final result = list.map((s) {
      final ownProfile = s['own_profile'] as Map<String, dynamic>?;
      final supervisorProfile = s['supervisor_profile'] as Map<String, dynamic>?;
      final supervisorId = s['academic_supervisor_id'] as String?;
      String? supervisorName;
      if (supervisorId != null) {
        final rawName = supervisorProfile?['full_name'] as String?;
        supervisorName = (rawName?.isNotEmpty == true) ? rawName : 'Unnamed';
      }
      return {
        'id': s['profile_id'],
        'full_name': ownProfile?['full_name'],
        'email': ownProfile?['email'],
        // false = the account exists but nobody has signed in to it yet
        'has_logged_in': activity.isEmpty ? true : activity[s['profile_id']] != null,
        'programme': s['programme'],
        'semester': s['semester'],
        'faculty': s['faculty'],
        'academic_supervisor_id': supervisorId,
        'supervisor_name': supervisorName,
      };
    }).toList();

    result.sort((a, b) => ((a['full_name'] as String?) ?? '').compareTo((b['full_name'] as String?) ?? ''));
    return result;
  }

  /// Academic supervisors. By default every account is listed (with `approval_status` and
  /// `has_logged_in`, so the admin also sees supervisors who are still waiting for approval or
  /// have never signed in); [approvedOnly] is for the "assign a supervisor" picker, because a
  /// pending account has no access yet (see the Approvals screen).
  Future<List<Map<String, dynamic>>> getSupervisors({bool approvedOnly = false}) async {
    final rows = await _client
        .from('academic_supervisors')
        .select('profile_id, profiles!academic_supervisors_profile_id_fkey(full_name, email, approval_status)');
    final activity = await _lastSignIns();
    final unconfirmed = await _unconfirmedIds();
    final list = List<Map<String, dynamic>>.from(rows).where((s) {
      final profile = s['profiles'] as Map<String, dynamic>?;
      if (profile == null || _isDeleted(profile) || unconfirmed.contains(s['profile_id'])) return false;
      return !approvedOnly || profile['approval_status'] == 'approved';
    }).toList();
    if (list.isEmpty) return [];

    final students = await _client.from('students').select('academic_supervisor_id').not('academic_supervisor_id', 'is', null);
    final studentList = List<Map<String, dynamic>>.from(students);

    final result = list.map((sup) {
      final profile = sup['profiles'] as Map<String, dynamic>?;
      final id = sup['profile_id'] as String;
      final count = studentList.where((s) => s['academic_supervisor_id'] == id).length;
      return {
        'id': id,
        'full_name': profile?['full_name'],
        'email': profile?['email'],
        'approval_status': profile?['approval_status'],
        'has_logged_in': activity.isEmpty ? true : activity[id] != null,
        'student_count': count,
      };
    }).toList();

    result.sort((a, b) => ((a['full_name'] as String?) ?? '').compareTo((b['full_name'] as String?) ?? ''));
    return result;
  }

  Future<List<Map<String, dynamic>>> getStudentsForSupervisor(String supervisorId) async {
    final rows = await _client
        .from('students')
        .select('profile_id, programme, profiles!students_profile_id_fkey(full_name)')
        .eq('academic_supervisor_id', supervisorId);
    final list = List<Map<String, dynamic>>.from(rows);

    final result = list.map((s) {
      final profile = s['profiles'] as Map<String, dynamic>?;
      return {
        'id': s['profile_id'],
        'full_name': profile?['full_name'],
        'programme': s['programme'],
      };
    }).toList();

    result.sort((a, b) => ((a['full_name'] as String?) ?? '').compareTo((b['full_name'] as String?) ?? ''));
    return result;
  }

  /// The academic supervisor of one student: `{id, name}`, or null when none is assigned.
  Future<Map<String, String?>?> getStudentSupervisor(String studentId) async {
    final row = await _client
        .from('students')
        .select('academic_supervisor_id, supervisor_profile:profiles!students_academic_supervisor_id_fkey(full_name, email)')
        .eq('profile_id', studentId)
        .maybeSingle();
    final id = row?['academic_supervisor_id'] as String?;
    if (id == null) return null;
    final profile = row?['supervisor_profile'] as Map<String, dynamic>?;
    return {
      'id': id,
      'name': (profile?['full_name'] as String?)?.isNotEmpty == true ? profile!['full_name'] as String : profile?['email'] as String?,
    };
  }

  Future<void> assignSupervisor({required String studentId, required String? supervisorId}) async {
    await _client.from('students').update({'academic_supervisor_id': supervisorId}).eq('profile_id', studentId);
  }

  Future<void> promoteToAdmin(String userId) async {
    await _client.rpc('promote_to_admin', params: {'p_target_profile_id': userId});
  }

  // ---------------------------------------------------------------------
  // Account approvals — supervisors and company staff register themselves
  // but stay `pending` (and have no privileges) until an administrator
  // approves them. See migration 00023_security_hardening.sql.
  // ---------------------------------------------------------------------

  /// Sign-ups whose email was never confirmed (the person gave up at the code step). They are not
  /// accounts, so the lists leave them out.
  Future<Set<String>> _unconfirmedIds() async {
    try {
      return List<dynamic>.from(await _client.rpc('admin_unconfirmed_profiles') as List).map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getPendingApprovals() async {
    final rows = await _client
        .from('profiles')
        .select('profile_id, role, email, full_name, created_at')
        .eq('approval_status', 'pending')
        .order('created_at');
    final unconfirmed = await _unconfirmedIds();
    return List<Map<String, dynamic>>.from(rows).where((r) => !unconfirmed.contains(r['profile_id'])).toList();
  }

  /// Suspends an approved account (it keeps its data but cannot sign in) or brings a suspended one
  /// back. Administrators only; migration 00042.
  Future<void> setAccountSuspended(String profileId, {required bool suspended}) async {
    await _client.rpc('admin_set_account_suspended', params: {'p_profile': profileId, 'p_suspend': suspended});
  }

  /// `approval_status` of one account ('approved', 'pending', 'rejected', 'suspended').
  Future<String?> getAccountStatus(String profileId) async {
    final row = await _client.from('profiles').select('approval_status').eq('profile_id', profileId).maybeSingle();
    return row?['approval_status'] as String?;
  }

  /// Removes an account for good (personal details wiped, login blocked, shown as "Deleted user").
  Future<void> removeAccount(String profileId) async {
    await _client.rpc('admin_remove_account', params: {'p_profile': profileId});
  }

  /// The HR people and company supervisors who belong to [companyId].
  Future<List<Map<String, dynamic>>> getCompanyStaff(String companyId) async {
    final rows = List<Map<String, dynamic>>.from(await _client.rpc('admin_company_staff', params: {'p_company': companyId}) as List);
    for (final r in rows) {
      r['id'] = r['profile_id'];
    }
    return rows;
  }

  /// [status] is 'approved' or 'rejected'.
  Future<void> setApprovalStatus(String profileId, String status) async {
    await _client.from('profiles').update({'approval_status': status}).eq('profile_id', profileId);
  }

  // ---------------------------------------------------------------------
  // Intakes — cohort start/end windows used to gate evaluations until a
  // student's internship has run its course. See migration
  // 00022_intakes_and_evaluation_gating.sql for the derivation rules
  // (student_internship_status()) and v_student_internship_status.
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getIntakes() async {
    final rows = await _client.from('intakes').select().order('start_date', ascending: false);
    final list = List<Map<String, dynamic>>.from(rows);
    for (final r in list) {
      r['id'] = r['intake_id'];
    }
    return list;
  }

  Future<String> createIntake({required String name, required DateTime startDate, required DateTime endDate}) async {
    final inserted = await _client
        .from('intakes')
        .insert({
          'name': name,
          'start_date': startDate.toIso8601String().substring(0, 10),
          'end_date': endDate.toIso8601String().substring(0, 10),
          'created_by': AuthService.instance.currentUserId,
        })
        .select('intake_id')
        .single();
    return inserted['intake_id'] as String;
  }

  Future<void> deleteIntake(String intakeId) async {
    await _client.from('intakes').delete().eq('intake_id', intakeId);
  }

  /// Every student, with their current intake assignment (if any) and
  /// derived internship status — the roster the intake-assignment screen
  /// picks from and displays.
  ///
  /// `v_student_internship_status` is a view, not a table with its own FK
  /// constraints, so PostgREST can't resolve a `profiles!<fkey>(...)` embed
  /// against it the way it can for `students` directly — fetched and
  /// merged separately instead, same pattern used everywhere else in this
  /// codebase for cross-table lookups.
  Future<List<Map<String, dynamic>>> getStudentsWithIntakeStatus() async {
    final rows = await _client.from('v_student_internship_status').select().order('student_id');
    final list = List<Map<String, dynamic>>.from(rows);
    if (list.isEmpty) return [];

    final studentIds = list.map((r) => r['student_id'] as String).toList();
    final profiles = await _client.from('profile_directory').select('profile_id, full_name').inFilter('profile_id', studentIds);
    final nameById = {for (final p in List<Map<String, dynamic>>.from(profiles)) p['profile_id'] as String: p['full_name'] as String?};

    for (final r in list) {
      r['id'] = r['student_id'];
      r['full_name'] = nameById[r['student_id']];
    }
    return list;
  }

  /// Bulk-assigns [studentIds] to [intakeId] (or unassigns them, when
  /// [intakeId] is null) in one request.
  Future<void> assignStudentsToIntake({required List<String> studentIds, required String? intakeId}) async {
    await _client.from('students').update({'intake_id': intakeId}).inFilter('profile_id', studentIds);
  }

  // ---------------------------------------------------------------------
  // Audit log + placement analytics (migrations 00036 and 00037)
  // ---------------------------------------------------------------------

  /// The newest audit entries first. [actionPrefixes] limits them to actions
  /// that start with one of the given prefixes (for example `account_`).
  Future<List<Map<String, dynamic>>> getAuditLog({List<String>? actionPrefixes, int limit = 100}) async {
    var query = _client
        .from('audit_log')
        .select('audit_id, actor_id, actor_role, action, summary, created_at, actor:profiles!audit_log_actor_id_fkey(full_name, email)');
    if (actionPrefixes != null && actionPrefixes.isNotEmpty) {
      query = query.or(actionPrefixes.map((p) => 'action.like.$p%').join(','));
    }
    final rows = await query.order('created_at', ascending: false).limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Placement numbers for the analytics screen.
  Future<Map<String, dynamic>> getPlacementReport() async {
    final result = await _client.rpc('admin_placement_report');
    return Map<String, dynamic>.from(result as Map);
  }

  // ---------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------

  Future<Map<String, int>> getDashboardCounts() async {
    final students = await _client.from('students').select('profile_id, academic_supervisor_id');
    final studentList = List<Map<String, dynamic>>.from(students);
    final supervisors = await getSupervisors();
    final companies = await _client.from('companies').select('company_id');
    final applications = await _client.from('applications').select('application_id').eq('status', 'active');
    final reviewCounts = await SupervisorDataService.instance.getDashboardCounts();

    return {
      'students': studentList.length,
      'unassignedStudents': studentList.where((s) => s['academic_supervisor_id'] == null).length,
      'supervisors': supervisors.length,
      'companies': List.from(companies).length,
      'activeInternships': List.from(applications).length,
      'pendingReviews': reviewCounts['pendingReviews'] ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getRecentStudents({int limit = 3}) async {
    final rows = await _client
        .from('profiles')
        .select('profile_id, full_name, created_at')
        .eq('role', 'student')
        .order('created_at', ascending: false)
        .limit(limit);
    final list = List<Map<String, dynamic>>.from(rows);
    for (final r in list) {
      r['id'] = r['profile_id'];
    }
    return list;
  }

  // ---------------------------------------------------------------------
  // Student accounts. Students do not sign themselves up: an administrator
  // creates the account, the `admin-create-students` Edge Function picks a
  // random password that meets the password rules and flags the account so the
  // student must choose their own password at the first login.
  // ---------------------------------------------------------------------

  /// Creates accounts for [students] (each `{email, full_name, student_reg_no?,
  /// programme?}`), at most 200 at a time. The returned results carry the
  /// temporary passwords; they are not stored anywhere, so the screen must show
  /// them to the admin now.
  Future<List<StudentAccountResult>> createStudentAccounts(List<Map<String, String>> students) => createAccounts('student', students);

  /// Creates accounts of [role] (`student` or `academic_supervisor`) the same way. A supervisor
  /// account is approved straight away; both kinds must change the password at first login.
  Future<List<StudentAccountResult>> createAccounts(String role, List<Map<String, String>> people) async {
    try {
      final response = await _client.functions.invoke('admin-create-students', body: {'students': people, 'role': role});
      final data = response.data;
      if (data is! Map || data['results'] is! List) {
        throw Exception('The server sent back something unexpected. Please try again.');
      }
      return (data['results'] as List).map((r) => StudentAccountResult.fromJson(Map<String, dynamic>.from(r as Map))).toList();
    } on FunctionException catch (e) {
      final details = e.details;
      final message = details is Map ? details['error'] as String? : null;
      if (e.status == 403) throw Exception('Only an administrator can create accounts.');
      throw Exception(message ?? 'Could not create the accounts. Please try again.');
    }
  }
}


/// What happened to one row of a student-creation request.
class StudentAccountResult {
  const StudentAccountResult({
    required this.email,
    required this.fullName,
    required this.status,
    this.password,
    this.message,
  });

  final String email;
  final String fullName;

  /// 'created', 'exists', 'invalid' or 'failed'.
  final String status;

  /// The temporary password, only for 'created' accounts.
  final String? password;
  final String? message;

  bool get created => status == 'created' && password != null;

  factory StudentAccountResult.fromJson(Map<String, dynamic> json) => StudentAccountResult(
        email: (json['email'] as String?) ?? '',
        fullName: (json['full_name'] as String?) ?? '',
        status: (json['status'] as String?) ?? 'failed',
        password: json['password'] as String?,
        message: json['message'] as String?,
      );
}
