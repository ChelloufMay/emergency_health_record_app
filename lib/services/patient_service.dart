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

    final row = await _supabase
        .from('users')
        .select()
        .eq('auth_user_id', authUser.id)
        .maybeSingle();

    if (row == null) return null;
    return Map<String, dynamic>.from(row);
  }

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

  Future<bool> canAccessPatient(String patientId, String action) async {
    final result = await _supabase.rpc(
      'can_access_patient',
      params: {'_patient_id': patientId, '_action': action},
    );
    return result == true;
  }

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

  Future<bool> hasAnyAccessGrant(String patientId) async {
    final result = await _supabase.rpc(
      'has_any_access_for_patient',
      params: {'_patient_id': patientId},
    );
    return result == true;
  }

  Future<Map<String, dynamic>?> fetchPatientSummary(String patientId) async {
    final row = await _supabase
        .from('patient_profiles_enriched')
        .select(
          'id, user_id, legal_id, first_name, family_name, sex, age_years, blood_type, phone, address_country, address_governorate, address_city, emergency_contact_name, emergency_contact_phone, insurance_plan, covid_vaccine_type, family_doctor_id, created_at, updated_at',
        )
        .eq('id', patientId)
        .maybeSingle();

    if (row == null) return null;
    return Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>?> fetchEmergencySummary(String patientId) async {
    // patient_emergency_summary uses can_access_patient_section so
    // read/edit/emergency_only grantees can all read it.
    final row = await _supabase
        .from('patient_emergency_summary')
        .select()
        .eq('patient_id', patientId)
        .maybeSingle();
    if (row == null) return null;
    return Map<String, dynamic>.from(row);
  }

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
