import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clinician_profile_model.dart';
import 'patient_service.dart';

// Managing clinician profiles.
class ClinicianProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PatientService _patientService = PatientService();

  // Fetches the clinician profile of the currently authenticated user.
  Future<ClinicianProfileModel?> fetchMine() async {
    final appUserId = await _patientService.ensureAppUserId();
    if (appUserId == null) return null;

    final row = await _supabase
        .from('clinician_profiles')
        .select()
        .eq('user_id', appUserId)
        .maybeSingle();

    if (row == null) return null;
    return ClinicianProfileModel.fromMap(Map<String, dynamic>.from(row));
  }

  Future<String> saveMine(ClinicianProfileModel model) async {
    final appUserId = await _patientService.ensureAppUserId();
    if (appUserId == null) {
      throw Exception('Not authenticated');
    }

    // The database enforces one clinician profile per user_id.
    await _supabase.from('clinician_profiles').upsert({
      ...model.toInsertMap(),
      'user_id': appUserId,
    }, onConflict: 'user_id');

    final row = await _supabase
        .from('clinician_profiles')
        .select('id')
        .eq('user_id', appUserId)
        .single();

    return row['id'].toString();
  }

  // Deletes the clinician profile of the currently authenticated user
  Future<void> deleteMine() async {
    final appUserId = await _patientService.ensureAppUserId();
    if (appUserId == null) return;

    await _supabase
        .from('clinician_profiles')
        .delete()
        .eq('user_id', appUserId);
  }
}
