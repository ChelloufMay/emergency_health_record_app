import 'package:supabase_flutter/supabase_flutter.dart';

class PatientIdentity {
  final String appUserId;
  final String patientId;
  final String? sex;

  const PatientIdentity({
    required this.appUserId,
    required this.patientId,
    this.sex,
  });
}

class PatientService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> ensureAppUserId({
    String? fullName,
    String? phone,
  }) async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;

    final existing = await _supabase
        .from('users')
        .select('id')
        .eq('auth_user_id', authUser.id)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    final resolvedName = (fullName ??
        authUser.userMetadata?['full_name']?.toString() ??
        authUser.userMetadata?['name']?.toString() ??
        authUser.email?.split('@').first ??
        'User')
        .trim();

    final resolvedPhone = phone?.trim();

    try {
      final inserted = await _supabase.from('users').insert({
        'auth_user_id': authUser.id,
        'full_name': resolvedName.isEmpty ? 'User' : resolvedName,
        'email': authUser.email,
        if (resolvedPhone != null && resolvedPhone.isNotEmpty) 'phone': resolvedPhone,
        'role': 'owner',
      }).select('id').single();

      return inserted['id'] as String;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        final retry = await _supabase
            .from('users')
            .select('id')
            .eq('auth_user_id', authUser.id)
            .maybeSingle();
        return retry?['id'] as String?;
      }
      rethrow;
    }
  }

  Future<String?> getAppUserId() async {
    return ensureAppUserId();
  }

  Future<PatientIdentity?> resolveIdentity() async {
    final appUserId = await ensureAppUserId();
    if (appUserId == null) return null;

    final profileRow = await _supabase
        .from('patient_profiles')
        .select('id, sex')
        .eq('user_id', appUserId)
        .maybeSingle();

    if (profileRow == null) return null;

    return PatientIdentity(
      appUserId: appUserId,
      patientId: profileRow['id'] as String,
      sex: profileRow['sex'] as String?,
    );
  }

  Future<Map<String, dynamic>?> fetchPatientProfile(String patientId) async {
    return _supabase
        .from('patient_profiles')
        .select()
        .eq('id', patientId)
        .maybeSingle();
  }
}