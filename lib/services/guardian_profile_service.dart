import 'package:supabase_flutter/supabase_flutter.dart';

class GuardianProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> fetchMyProfile(String userId) async {
    return _supabase
        .from('guardian_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>> saveMyProfile({
    required String userId,
    required String fullName,
    String? relationshipToPatient,
    String? legalAuthorityNote,
    String? phone,
    String? addressId,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'user_id': userId,
      'full_name': fullName.trim(),
      'relationship_to_patient': relationshipToPatient?.trim().isEmpty == true
          ? null
          : relationshipToPatient?.trim(),
      'legal_authority_note': legalAuthorityNote?.trim().isEmpty == true
          ? null
          : legalAuthorityNote?.trim(),
      'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
      'address_id': addressId?.trim().isEmpty == true ? null : addressId?.trim(),
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
    };

    return _supabase
        .from('guardian_profiles')
        .upsert(payload, onConflict: 'user_id')
        .select()
        .single();
  }
}