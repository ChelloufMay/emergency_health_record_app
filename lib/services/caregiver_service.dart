import 'package:supabase_flutter/supabase_flutter.dart';

// Handles CRUD operations for caregiver profiles.
class CaregiverService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Internal helper to cast a dynamic row to a Map.
  Map<String, dynamic> _asMap(dynamic row) {
    return Map<String, dynamic>.from(row as Map);
  }

  // Fetches the caregiver profile of the currently authenticated user.
  Future<Map<String, dynamic>?> fetchMyCaregiverProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    return fetchCaregiverProfileByAuthUserId(user.id);
  }

  // Fetches a caregiver profile by the user's auth ID.
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

  // Fetches all caregiver profiles in the system.
  Future<List<Map<String, dynamic>>> fetchAllCaregiverProfiles() async {
    final rows = await _supabase
        .from('caregiver_profiles')
        .select()
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => _asMap(row))
        .toList();
  }

  // Upserts/creates/updates a caregiver profile
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

  // Updates specific fields of an existing caregiver profile
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

  // Deletes a caregiver profile by its ID.
  Future<void> deleteCaregiverProfile(String id) async {
    if (id.trim().isEmpty) {
      throw Exception('Missing caregiver profile id.');
    }

    await _supabase.from('caregiver_profiles').delete().eq('id', id);
  }
}