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
    await _client.from('companies').update({'status': 'verified'}).eq('company_id', id);
  }

  Future<void> deleteCompany(String id) async {
    await _client.from('companies').delete().eq('company_id', id);
  }

  // ---------------------------------------------------------------------
  // Students / Supervisors / assignment
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getStudents() async {
    final rows = await _client.from('students').select(
        'profile_id, programme, semester, faculty, academic_supervisor_id, '
        'own_profile:profiles!students_profile_id_fkey(full_name), '
        'supervisor_profile:profiles!students_academic_supervisor_id_fkey(full_name)');
    final list = List<Map<String, dynamic>>.from(rows);

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

  Future<List<Map<String, dynamic>>> getSupervisors() async {
    final rows = await _client
        .from('academic_supervisors')
        .select('profile_id, profiles!academic_supervisors_profile_id_fkey(full_name, email)');
    final list = List<Map<String, dynamic>>.from(rows);
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

  Future<void> assignSupervisor({required String studentId, required String? supervisorId}) async {
    await _client.from('students').update({'academic_supervisor_id': supervisorId}).eq('profile_id', studentId);
  }

  Future<void> promoteToAdmin(String userId) async {
    await _client.rpc('promote_to_admin', params: {'p_target_profile_id': userId});
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
  // Dashboard
  // ---------------------------------------------------------------------

  Future<Map<String, int>> getDashboardCounts() async {
    final students = await _client.from('students').select('profile_id, academic_supervisor_id');
    final studentList = List<Map<String, dynamic>>.from(students);
    final supervisors = await _client.from('academic_supervisors').select('profile_id');
    final companies = await _client.from('companies').select('company_id');
    final applications = await _client.from('applications').select('application_id').eq('status', 'active');
    final reviewCounts = await SupervisorDataService.instance.getDashboardCounts();

    return {
      'students': studentList.length,
      'unassignedStudents': studentList.where((s) => s['academic_supervisor_id'] == null).length,
      'supervisors': List.from(supervisors).length,
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
}
