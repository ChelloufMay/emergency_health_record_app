import 'package:supabase_flutter/supabase_flutter.dart';

class CaregiverService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Map<String, dynamic> _asMap(dynamic row) {
    return Map<String, dynamic>.from(row as Map);
  }

  Future<Map<String, dynamic>?> fetchMyCaregiverProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    return fetchCaregiverProfileByAuthUserId(user.id);
  }

  Future<Map<String, dynamic>?> fetchCaregiverProfileByAuthUserId(
      String authUserId,
      ) async {
    final row = await _supabase
        .from('caregiver_profiles')
        .select()
        .eq('auth_user_id', authUserId)
        .maybeSingle();

    if (row == null) return null;
    return _asMap(row);
  }

  Future<List<Map<String, dynamic>>> fetchAllCaregiverProfiles() async {
    final rows = await _supabase
        .from('caregiver_profiles')
        .select()
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => _asMap(row))
        .toList();
  }

  Future<String> upsertCaregiverProfile({
    required String authUserId,
    String? fullName,
    String? phone,
    String? email,
    String? addressId,
    Map<String, dynamic>? extraFields,
  }) async {
    final payload = <String, dynamic>{
      'auth_user_id': authUserId,
      'full_name': ?fullName,
      'phone': ?phone,
      'email': ?email,
      'address_id': ?addressId,
      if (extraFields != null) ...extraFields,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final inserted = await _supabase
        .from('caregiver_profiles')
        .upsert(
      payload,
      onConflict: 'auth_user_id',
    )
        .select('id')
        .single();

    return inserted['id'].toString();
  }

  Future<void> updateCaregiverProfile({
    required String id,
    required Map<String, dynamic> changes,
  }) async {
    if (id.trim().isEmpty) {
      throw Exception('Missing caregiver profile id.');
    }

    final payload = <String, dynamic>{
      ...changes,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('caregiver_profiles').update(payload).eq('id', id);
  }

  Future<void> deleteCaregiverProfile(String id) async {
    if (id.trim().isEmpty) {
      throw Exception('Missing caregiver profile id.');
    }

    await _supabase.from('caregiver_profiles').delete().eq('id', id);
  }
}