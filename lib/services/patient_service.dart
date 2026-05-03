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

  Future<String?> getAppUserId() async {
    final authId = _supabase.auth.currentUser?.id;
    if (authId == null) return null;

    final row = await _supabase
        .from('users')
        .select('id')
        .eq('auth_user_id', authId)
        .maybeSingle();

    if (row == null) return null;
    return row['id'] as String;
  }

  Future<String?> getPatientId() async {
    final identity = await resolveIdentity();
    return identity?.patientId;
  }

  Future<PatientIdentity?> resolveIdentity() async {
    final authId = _supabase.auth.currentUser?.id;
    if (authId == null) return null;

    final userRow = await _supabase
        .from('users')
        .select('id')
        .eq('auth_user_id', authId)
        .maybeSingle();

    if (userRow == null) return null;

    final appUserId = userRow['id'] as String;

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
    final row = await _supabase
        .from('patient_profiles')
        .select()
        .eq('id', patientId)
        .maybeSingle();

    return row;
  }
}