import 'package:supabase_flutter/supabase_flutter.dart';

class ClinicianProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> fetchMyProfile(String userId) async {
    return _supabase
        .from('clinician_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>> saveMyProfile({
    required String userId,
    required String fullName,
    String? phone,
    String? addressId,
    String? licenseNumber,
    String? specialization,
    String? facilityName,
    String? workPhone,
    bool isVerified = false,
    String? verificationNote,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'user_id': userId,
      'full_name': fullName.trim(),
      'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
      'address_id': addressId?.trim().isEmpty == true ? null : addressId?.trim(),
      'license_number': licenseNumber?.trim().isEmpty == true ? null : licenseNumber?.trim(),
      'specialization': specialization?.trim().isEmpty == true ? null : specialization?.trim(),
      'facility_name': facilityName?.trim().isEmpty == true ? null : facilityName?.trim(),
      'work_phone': workPhone?.trim().isEmpty == true ? null : workPhone?.trim(),
      'is_verified': isVerified,
      'verification_note': verificationNote?.trim().isEmpty == true ? null : verificationNote?.trim(),
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
    };

    return _supabase
        .from('clinician_profiles')
        .upsert(payload, onConflict: 'user_id')
        .select()
        .single();
  }
}