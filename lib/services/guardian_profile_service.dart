import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/guardian_profile_model.dart';
import 'patient_service.dart';

// Managing guardian profiles.
class GuardianProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PatientService _patientService = PatientService();

  // Fetches the guardian profile of the currently authenticated user.
  Future<GuardianProfileModel?> fetchMine() async {
    final appUserId = await _patientService.ensureAppUserId();
    if (appUserId == null) return null;

    final row = await _supabase
        .from('guardian_profiles')
        .select()
        .eq('user_id', appUserId)
        .maybeSingle();

    if (row == null) return null;
    return GuardianProfileModel.fromMap(Map<String, dynamic>.from(row));
  }

  // Saves or updates the guardian profile for the currently authenticated user.
  Future<String> saveMine(GuardianProfileModel model) async {
    final appUserId = await _patientService.ensureAppUserId();
    if (appUserId == null) {
      throw Exception('Not authenticated');
    }

    // The row is keyed by user_id and the database keeps it unique.
    await _supabase.from('guardian_profiles').upsert({
      ...model.toInsertMap(),
      'user_id': appUserId,
    }, onConflict: 'user_id');

    final row = await _supabase
        .from('guardian_profiles')
        .select('id')
        .eq('user_id', appUserId)
        .single();

    return row['id'].toString();
  }

  // Deletes the guardian profile of the currently authenticated user.
  Future<void> deleteMine() async {
    final appUserId = await _patientService.ensureAppUserId();
    if (appUserId == null) return;

    await _supabase.from('guardian_profiles').delete().eq('user_id', appUserId);
  }
}
