// shared ID resolver used by every screen
import 'package:supabase_flutter/supabase_flutter.dart';

// holds the two IDs every screen needs to operate
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

// call resolveIdentity() once in initState and store the result --> avoids repeating the same three-step lookup in every screen
class PatientService {
  final _supabase = Supabase.instance.client;

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
}