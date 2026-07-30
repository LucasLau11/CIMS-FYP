import 'package:supabase_flutter/supabase_flutter.dart';
import 'supervisor_data_service.dart';

/// Real data access for the admin screens. Same singleton style as the
/// other *_data_service classes. Reuses [SupervisorDataService] for
/// reviews/monitor (reports+documents approve/reject) rather than
/// duplicating it — admin's RLS grants the same cross-cutting visibility
/// supervisors have, so the exact same queries work unchanged.
class AdminDataService {
  AdminDataService._();
  static final AdminDataService instance = AdminDataService._();

  final SupabaseClient _client = Supabase.instance.client;

  // ---------------------------------------------------------------------
  // Companies
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getCompanies() async {
    final rows = await _client.from('companies').select().order('name');
    return List<Map<String, dynamic>>.from(rows);
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
    }).eq('id', id);
  }

  Future<void> verifyCompany(String id) async {
    await _client.from('companies').update({'status': 'verified'}).eq('id', id);
  }

  Future<void> deleteCompany(String id) async {
    await _client.from('companies').delete().eq('id', id);
  }

  // ---------------------------------------------------------------------
  // Students / Supervisors / assignment
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getStudents() async {
    final students = await _client
        .from('profiles')
        .select('id, full_name, programme, semester, faculty, academic_supervisor_id')
        .eq('role', 'student')
        .order('full_name');
    final studentList = List<Map<String, dynamic>>.from(students);
    if (studentList.isEmpty) return [];

    final supervisorIds = studentList.map((s) => s['academic_supervisor_id']).whereType<String>().toSet().toList();
    final supervisorNames = <String, String>{};
    if (supervisorIds.isNotEmpty) {
      final supervisors = await _client.from('profile_directory').select().inFilter('id', supervisorIds);
      for (final s in List<Map<String, dynamic>>.from(supervisors)) {
        supervisorNames[s['id'] as String] = (s['full_name'] as String?)?.isNotEmpty == true ? s['full_name'] as String : 'Unnamed';
      }
    }

    return studentList.map((s) {
      final result = Map<String, dynamic>.from(s);
      final supervisorId = s['academic_supervisor_id'] as String?;
      result['supervisor_name'] = supervisorId != null ? supervisorNames[supervisorId] : null;
      return result;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getSupervisors() async {
    final supervisors = await _client
        .from('profiles')
        .select('id, full_name, email, faculty')
        .eq('role', 'academic_supervisor')
        .order('full_name');
    final supervisorList = List<Map<String, dynamic>>.from(supervisors);
    if (supervisorList.isEmpty) return [];

    final students = await _client.from('profiles').select('academic_supervisor_id').eq('role', 'student');
    final studentList = List<Map<String, dynamic>>.from(students);

    return supervisorList.map((sup) {
      final count = studentList.where((s) => s['academic_supervisor_id'] == sup['id']).length;
      final result = Map<String, dynamic>.from(sup);
      result['student_count'] = count;
      return result;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getStudentsForSupervisor(String supervisorId) async {
    final rows = await _client
        .from('profiles')
        .select('id, full_name, programme')
        .eq('role', 'student')
        .eq('academic_supervisor_id', supervisorId)
        .order('full_name');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> assignSupervisor({required String studentId, required String? supervisorId}) async {
    await _client.from('profiles').update({'academic_supervisor_id': supervisorId}).eq('id', studentId);
  }

  Future<void> promoteToAdmin(String userId) async {
    await _client.from('profiles').update({'role': 'admin'}).eq('id', userId);
  }

  // ---------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------

  Future<Map<String, int>> getDashboardCounts() async {
    final students = await _client.from('profiles').select('id, academic_supervisor_id').eq('role', 'student');
    final studentList = List<Map<String, dynamic>>.from(students);
    final supervisors = await _client.from('profiles').select('id').eq('role', 'academic_supervisor');
    final companies = await _client.from('companies').select('id');
    final applications = await _client.from('applications').select('id').eq('status', 'active');
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
        .select('id, full_name, created_at')
        .eq('role', 'student')
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }
}
