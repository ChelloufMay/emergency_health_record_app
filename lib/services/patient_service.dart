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

  Future<Map<String, dynamic>?> fetchCurrentAppUserRow() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;

    return _supabase
        .from('users')
        .select()
        .eq('auth_user_id', authUser.id)
        .maybeSingle();
  }

  Future<String?> ensureAppUserId({
    String? fullName,
    String? phone,
  }) async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;

    final existing = await fetchCurrentAppUserRow();
    if (existing != null) {
      return existing['id']?.toString();
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
        final retry = await fetchCurrentAppUserRow();
        return retry?['id']?.toString();
      }
      rethrow;
    }
  }

  Future<String?> getAppUserId() async => ensureAppUserId();

  Future<String?> getCurrentRole() async {
    final row = await fetchCurrentAppUserRow();
    return row?['role']?.toString();
  }

  Future<bool> hasPatientProfile() async {
    final appUserId = await ensureAppUserId();
    if (appUserId == null) return false;

    final row = await _supabase
        .from('patient_profiles')
        .select('id')
        .eq('user_id', appUserId)
        .maybeSingle();

    return row != null;
  }

  Future<bool> hasCaregiverProfile() async {
    final appUserId = await ensureAppUserId();
    if (appUserId == null) return false;

    final row = await _supabase
        .from('caregiver_profiles')
        .select('id')
        .eq('user_id', appUserId)
        .maybeSingle();

    return row != null;
  }

  Future<bool> hasGuardianProfile() async {
    final appUserId = await ensureAppUserId();
    if (appUserId == null) return false;

    final row = await _supabase
        .from('guardian_profiles')
        .select('id')
        .eq('user_id', appUserId)
        .maybeSingle();

    return row != null;
  }

  Future<bool> hasClinicianProfile() async {
    final appUserId = await ensureAppUserId();
    if (appUserId == null) return false;

    final row = await _supabase
        .from('clinician_profiles')
        .select('id')
        .eq('user_id', appUserId)
        .maybeSingle();

    return row != null;
  }

  Future<bool> hasAnyAccessGrant() async {
    final appUserId = await ensureAppUserId();
    if (appUserId == null) return false;

    final rows = await _supabase
        .from('access_grants')
        .select('status, expires_at, grantee_user_id')
        .eq('grantee_user_id', appUserId);

    final now = DateTime.now();
    for (final raw in rows as List) {
      final row = raw as Map;
      if (row['status']?.toString() != 'active') continue;
      final expiresRaw = row['expires_at'];
      if (expiresRaw == null) return true;
      final expiresAt = DateTime.tryParse(expiresRaw.toString());
      if (expiresAt == null || expiresAt.isAfter(now)) return true;
    }
    return false;
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
    return _supabase.from('patient_profiles').select().eq('id', patientId).maybeSingle();
  }

  Future<Map<String, dynamic>?> fetchPatientSummary(String patientId) async {
    return _supabase
        .from('patient_profiles_enriched')
        .select(
      'id, first_name, family_name, sex, age_years, blood_type, '
          'address_country, address_governorate, address_city, '
          'emergency_contact_name, emergency_contact_phone',
    )
        .eq('id', patientId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>?> fetchEmergencySummary(String patientId) async {
    return _supabase
        .from('patient_emergency_summary')
        .select()
        .eq('patient_id', patientId)
        .maybeSingle();
  }
}