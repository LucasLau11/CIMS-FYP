import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

/// Self-service company linkage for HR / company_supervisor accounts. Both
/// roles get a `company_hr`/`company_supervisors` subtype row (with
/// `company_id = null`) created at sign-up by `create_profile_with_subtype` —
/// this lets a new account fill that `company_id` in, either by joining an
/// existing company (the same `companies` table admin manages) or by
/// registering a new one (`companies_insert_self_service` policy, which
/// permits any authenticated company_hr/company_supervisor/admin to insert).
class CompanyService {
  CompanyService._();
  static final CompanyService instance = CompanyService._();

  final SupabaseClient _client = Supabase.instance.client;

  String get _userId {
    final id = AuthService.instance.currentUserId;
    if (id == null) throw Exception('You must be logged in.');
    return id;
  }

  /// Resolves the caller's subtype table (`company_hr` or
  /// `company_supervisors`) from their `profiles.role`, so the rest of this
  /// service can read/write the right table without the caller having to
  /// say which role it is.
  Future<String> _mySubtypeTable() async {
    final role = await _client
        .from('profiles')
        .select('role')
        .eq('profile_id', _userId)
        .single()
        .then((r) => r['role'] as String);
    if (role != 'company_hr' && role != 'company_supervisor') {
      throw Exception('Only company HR or company supervisor accounts can manage a company.');
    }
    return role == 'company_supervisor' ? 'company_supervisors' : 'company_hr';
  }

  Future<List<Map<String, dynamic>>> getCompanies() async {
    final rows = await _client.from('companies').select().order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>?> getMyCompany() async {
    final subtypeTable = await _mySubtypeTable();
    final subtype = await _client
        .from(subtypeTable)
        .select('company_id')
        .eq('profile_id', _userId)
        .maybeSingle();
    final companyId = subtype?['company_id'] as String?;
    if (companyId == null) return null;
    return await _client.from('companies').select().eq('company_id', companyId).maybeSingle();
  }

  Future<void> joinCompany(String companyId) async {
    final subtypeTable = await _mySubtypeTable();
    await _client.from(subtypeTable).update({'company_id': companyId}).eq('profile_id', _userId);
  }

  Future<void> createAndJoinCompany({
    required String name,
    String? industry,
    String? location,
  }) async {
    final row = await _client.from('companies').insert({
      'name': name.trim(),
      'industry': industry,
      'location': location,
    }).select().single();
    await joinCompany(row['company_id'] as String);
  }
}
