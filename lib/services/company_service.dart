import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

/// Self-service company linkage for HR / company_supervisor accounts. Both
/// roles need `profiles.company_id` set before postings/interns/reviews
/// mean anything — this lets a new account either join an existing company
/// (the same `companies` table admin manages) or register a new one via
/// `companies_insert_hr_or_company_supervisor`.
class CompanyService {
  CompanyService._();
  static final CompanyService instance = CompanyService._();

  final SupabaseClient _client = Supabase.instance.client;

  String get _userId {
    final id = AuthService.instance.currentUserId;
    if (id == null) throw Exception('You must be logged in.');
    return id;
  }

  Future<List<Map<String, dynamic>>> getCompanies() async {
    final rows = await _client.from('companies').select().order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>?> getMyCompany() async {
    final profile = await _client.from('profiles').select('company_id').eq('id', _userId).single();
    final companyId = profile['company_id'] as String?;
    if (companyId == null) return null;
    return await _client.from('companies').select().eq('id', companyId).single();
  }

  Future<void> joinCompany(String companyId) async {
    await _client.from('profiles').update({'company_id': companyId}).eq('id', _userId);
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
    await joinCompany(row['id'] as String);
  }
}
