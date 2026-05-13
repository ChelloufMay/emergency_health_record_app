import 'package:supabase_flutter/supabase_flutter.dart';

class ResolvedIdentity {
  final String appUserId;
  final String? role;
  final String? patientProfileId;
  final String? caregiverProfileId;
  final String? guardianProfileId;
  final String? clinicianProfileId;
  final String? sex;

  const ResolvedIdentity({
    required this.appUserId,
    this.role,
    this.patientProfileId,
    this.caregiverProfileId,
    this.guardianProfileId,
    this.clinicianProfileId,
    this.sex,
  });

  bool get hasPatientProfile => patientProfileId != null;
  bool get hasCaregiverProfile => caregiverProfileId != null;
  bool get hasGuardianProfile => guardianProfileId != null;
  bool get hasClinicianProfile => clinicianProfileId != null;
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

  Future<String?> ensureAppUserId({String? fullName, String? phone}) async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;

    final existing = await fetchCurrentAppUserRow();
    if (existing != null) return existing['id']?.toString();

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

      return inserted['id']?.toString();
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        final retry = await fetchCurrentAppUserRow();
        return retry?['id']?.toString();
      }
      rethrow;
    }
  }

  Future<ResolvedIdentity?> resolveIdentity() async {
    final appUserId = await ensureAppUserId();
    if (appUserId == null) return null;

    final userRow = await fetchCurrentAppUserRow();
    final patientRow = await _supabase
        .from('patient_profiles')
        .select('id, sex')
        .eq('user_id', appUserId)
        .maybeSingle();

    final caregiverRow = await _supabase
        .from('caregiver_profiles')
        .select('id')
        .eq('user_id', appUserId)
        .maybeSingle();

    final guardianRow = await _supabase
        .from('guardian_profiles')
        .select('id')
        .eq('user_id', appUserId)
        .maybeSingle();

    final clinicianRow = await _supabase
        .from('clinician_profiles')
        .select('id')
        .eq('user_id', appUserId)
        .maybeSingle();

    return ResolvedIdentity(
      appUserId: appUserId,
      role: userRow?['role']?.toString(),
      patientProfileId: patientRow?['id']?.toString(),
      caregiverProfileId: caregiverRow?['id']?.toString(),
      guardianProfileId: guardianRow?['id']?.toString(),
      clinicianProfileId: clinicianRow?['id']?.toString(),
      sex: patientRow?['sex']?.toString(),
    );
  }

  Future<bool> hasPatientProfile() async {
    final appUserId = await ensureAppUserId();
    if (appUserId == null) return false;
    final row = await _supabase.from('patient_profiles').select('id').eq('user_id', appUserId).maybeSingle();
    return row != null;
  }

  Future<bool> hasCaregiverProfile() async {
    final appUserId = await ensureAppUserId();
    if (appUserId == null) return false;
    final row = await _supabase.from('caregiver_profiles').select('id').eq('user_id', appUserId).maybeSingle();
    return row != null;
  }

  Future<bool> hasGuardianProfile() async {
    final appUserId = await ensureAppUserId();
    if (appUserId == null) return false;
    final row = await _supabase.from('guardian_profiles').select('id').eq('user_id', appUserId).maybeSingle();
    return row != null;
  }

  Future<bool> hasClinicianProfile() async {
    final appUserId = await ensureAppUserId();
    if (appUserId == null) return false;
    final row = await _supabase.from('clinician_profiles').select('id').eq('user_id', appUserId).maybeSingle();
    return row != null;
  }

  Future<bool> hasAnyAccessGrant(String patientId) async {
    final appUserId = await ensureAppUserId();
    if (appUserId == null) return false;

    final rows = await _supabase
        .from('access_grants')
        .select('id, status, expires_at, grantee_user_id')
        .eq('patient_id', patientId)
        .eq('grantee_user_id', appUserId);

    final now = DateTime.now();
    for (final raw in rows as List) {
      final row = raw as Map;
      if (row['status']?.toString() != 'active') continue;
      final expires = DateTime.tryParse(row['expires_at']?.toString() ?? '');
      if (expires == null || expires.isAfter(now)) return true;
    }
    return false;
  }

  Future<Map<String, dynamic>?> fetchPatientSummary(String patientId) async {
    return _supabase
        .from('patient_profiles_enriched')
        .select('id, user_id, legal_id, first_name, family_name, sex, age_years, blood_type, phone, address_country, address_governorate, address_city, emergency_contact_name, emergency_contact_phone, insurance_plan, covid_vaccine_type, family_doctor_id, created_at, updated_at')
        .eq('id', patientId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>?> fetchEmergencySummary(String patientId) async {
    return _supabase
        .from('patient_emergency_summary')
        .select('*')
        .eq('patient_id', patientId)
        .maybeSingle();
  }
}