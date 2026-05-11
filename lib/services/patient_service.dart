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

  /// Returns the current row in public.users for the logged-in auth account.
  Future<Map<String, dynamic>?> fetchCurrentAppUserRow() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;

    return _supabase
        .from('users')
        .select()
        .eq('auth_user_id', authUser.id)
        .maybeSingle();
  }

  /// Returns the current app user id, creating a fallback row only if needed.
  Future<String?> ensureAppUserId({
    String? fullName,
    String? phone,
  }) async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;

    final existing = await fetchCurrentAppUserRow();
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
      // The database trigger normally creates this row automatically.
      // This insert is only a fallback.
      final inserted = await _supabase.from('users').insert({
        'auth_user_id': authUser.id,
        'full_name': resolvedName.isEmpty ? 'User' : resolvedName,
        'email': authUser.email,
        if (resolvedPhone != null && resolvedPhone.isNotEmpty)
          'phone': resolvedPhone,
        'role': 'owner',
      }).select('id').single();

      return inserted['id'] as String;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        final retry = await fetchCurrentAppUserRow();
        return retry?['id'] as String?;
      }
      rethrow;
    }
  }

  Future<String?> getAppUserId() async {
    return ensureAppUserId();
  }

  Future<String?> getCurrentRole() async {
    final row = await fetchCurrentAppUserRow();
    return row?['role']?.toString();
  }

  /// A caregiver account is any signed-in user who either:
  /// - already has a caregiver profile row, or
  /// - already has at least one caregiver permission row.
  ///
  /// This is better than relying on public.users.role because the DB trigger
  /// currently creates new users as role = owner.
  Future<bool> isCaregiverAccount() async {
    final hasProfile = await hasCaregiverProfile();
    if (hasProfile) return true;

    return hasCaregiverPermissions();
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

  /// Returns true when the signed-in user has at least one active caregiver permission.
  /// Active means:
  /// - status = active
  /// - and expires_at is null or still in the future
  Future<bool> hasCaregiverPermissions() async {
    final appUserId = await ensureAppUserId();
    if (appUserId == null) return false;

    final rows = await _supabase
        .from('caregiver_permissions')
        .select('status, expires_at')
        .eq('caregiver_user_id', appUserId);

    final now = DateTime.now();

    for (final raw in rows as List) {
      final row = raw as Map<String, dynamic>;
      if (row['status']?.toString() != 'active') continue;

      final expiresRaw = row['expires_at'];
      if (expiresRaw == null) return true;

      final expiresAt = DateTime.tryParse(expiresRaw.toString());
      if (expiresAt == null || expiresAt.isAfter(now)) {
        return true;
      }
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

  Future<Map<String, dynamic>?> fetchPatientProfile(String patientId) async {
    return _supabase
        .from('patient_profiles')
        .select()
        .eq('id', patientId)
        .maybeSingle();
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
}