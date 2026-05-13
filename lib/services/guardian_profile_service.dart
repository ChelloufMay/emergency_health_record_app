import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/guardian_profile_model.dart';
import 'patient_service.dart';

class GuardianProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PatientService _patientService = PatientService();

  Future<GuardianProfileModel?> fetchMine() async {
    final appUserId = await _patientService.ensureAppUserId();
    if (appUserId == null) return null;

    final row = await _supabase.from('guardian_profiles').select().eq('user_id', appUserId).maybeSingle();
    if (row == null) return null;
    return GuardianProfileModel.fromMap(row);
  }

  Future<String> saveMine(GuardianProfileModel model) async {
    final appUserId = await _patientService.ensureAppUserId();
    if (appUserId == null) throw Exception('Not authenticated');

    await _supabase.from('guardian_profiles').upsert({
      ...model.toInsertMap(),
      'user_id': appUserId,
    }, onConflict: 'user_id');

    final row = await _supabase.from('guardian_profiles').select('id').eq('user_id', appUserId).single();
    return row['id'].toString();
  }

  Future<void> deleteMine() async {
    final appUserId = await _patientService.ensureAppUserId();
    if (appUserId == null) return;
    await _supabase.from('guardian_profiles').delete().eq('user_id', appUserId);
  }
}