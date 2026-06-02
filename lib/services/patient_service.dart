import 'package:supabase_flutter/supabase_flutter.dart';

// A model representing the resolved identities and roles of a user.
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

  // Whether the user has a patient profile.
  bool get hasPatientProfile => patientProfileId != null;

  // Whether the user has a caregiver profile.
  bool get hasCaregiverProfile => caregiverProfileId != null;

  // Whether the user has a guardian profile.
  bool get hasGuardianProfile => guardianProfileId != null;

  // Whether the user has a clinician profile.
  bool get hasClinicianProfile => clinicianProfileId != null;
}

// A service that manages user identity resolution and patient related data access. >:(
class PatientService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetches the public.users row for the currently authenticated user
  Future<Map<String, dynamic>?> fetchCurrentAppUserRow() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;

    final row = await _supabase
        .from('users')
        .select()
        .eq('auth_user_id', authUser.id)
        .maybeSingle();

    if (row == null) return null;
    return Map<String, dynamic>.from(row);
  }

  // Ensures an app specific user row exists for the current auth user and returns its ID.
  Future<String?> ensureAppUserId({String? fullName, String? phone}) async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;

    final existing = await fetchCurrentAppUserRow();
    if (existing != null) return existing['id']?.toString();

    final resolvedName =
        (fullName ??
                authUser.userMetadata?['full_name']?.toString() ??
                authUser.userMetadata?['name']?.toString() ??
                authUser.email?.split('@').first ??
                'User')
            .trim();
    final resolvedPhone = phone?.trim();

    try {
      final inserted = await _supabase
          .from('users')
          .insert({
            'auth_user_id': authUser.id,
            'full_name': resolvedName.isEmpty ? 'User' : resolvedName,
            'email': authUser.email,
            if (resolvedPhone != null && resolvedPhone.isNotEmpty)
              'phone': resolvedPhone,
            'role': 'owner',
          })
          .select('id')
          .single();

      return inserted['id']?.toString();
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        final retry = await fetchCurrentAppUserRow();
        return retry?['id']?.toString();
      }
      rethrow;
    }
  }

  // Resolves all profiles (patient, caregiver ...) associated with the current user.
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

  // Checks if the current user has a patient profile.
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

  // Checks if the current user has a caregiver profile.
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

  // Checks if the current user has a guardian profile.
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

  // Checks if the current user has a clinician profile.
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

  // Checks if the user can perform a specific action on a patient's data.
  Future<bool> canAccessPatient(String patientId, String action) async {
    final result = await _supabase.rpc(
      'can_access_patient',
      params: {'_patient_id': patientId, '_action': action},
    );
    return result == true;
  }

  // Checks if the user can perform a specific action on a patient's data section.
  Future<bool> canAccessPatientSection(
    String patientId,
    String section,
    String action,
  ) async {
    final result = await _supabase.rpc(
      'can_access_patient_section',
      params: {
        '_patient_id': patientId,
        '_section': section,
        '_action': action,
      },
    );
    return result == true;
  }

  // Checks if the user has any type of access grant for a patient.
  Future<bool> hasAnyAccessGrant(String patientId) async {
    final result = await _supabase.rpc(
      'has_any_access_for_patient',
      params: {'_patient_id': patientId},
    );
    return result == true;
  }

  // Fetches an enriched summary of patient profile data.
  Future<Map<String, dynamic>?> fetchPatientSummary(String patientId) async {
    final row = await _supabase
        .from('patient_profiles_enriched')
        .select(
          'id, user_id, first_name, family_name, sex, age_years, blood_type, phone, address_country, address_governorate, address_city, emergency_contact_name, emergency_contact_phone, insurance_plan, covid_vaccine_type, family_doctor_id, created_at, updated_at',
        )
        .eq('id', patientId)
        .maybeSingle();

    if (row == null) return null;
    return Map<String, dynamic>.from(row);
  }

  // Fetches a specialized emergency summary for a patient.
  Future<Map<String, dynamic>?> fetchEmergencySummary(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return null;
    try {
      final row = await _supabase
          .from('patient_emergency_summary')
          .select()
          .eq('patient_id', pid)
          .maybeSingle();
      if (row == null) return null;
      return Map<String, dynamic>.from(row);
    } catch (_) {
      return null;
    }
  }

  // Fetches a patient profile if the current user is a valid grantee.
  Future<Map<String, dynamic>?> fetchPatientProfileForGrantee(String patientId) async {
    
    // patient_profiles RLS uses can_access_patient which covers grantees.
    final row = await _supabase
        .from('patient_profiles')
        .select(
      'id, first_name, family_name, sex, date_of_birth, blood_type, '
          'phone, emergency_contact_name, emergency_contact_phone, '
          'insurance_plan, covid_vaccine_type',
    )
        .eq('id', patientId)
        .maybeSingle();
    if (row == null) return null;
    return Map<String, dynamic>.from(row);
  }

  // Resolves a one-time emergency access token
  Future<Map<String, dynamic>?> resolveEmergencyAccessToken(
    String token,
  ) async {
    final result = await _supabase.rpc(
      'resolve_emergency_access_token',
      params: {'_token': token},
    );

    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    if (result is List && result.isNotEmpty && result.first is Map) {
      return Map<String, dynamic>.from(result.first as Map);
    }
    return null;
  }
}
