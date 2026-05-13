import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/caregiver_profile_model.dart';
import 'patient_service.dart';

class CaregiverProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PatientService _patientService = PatientService();

  Future<CaregiverProfileModel?> fetchMine() async {
    final appUserId = await _patientService.ensureAppUserId();
    if (appUserId == null) return null;

    final row = await _supabase.from('caregiver_profiles').select().eq('user_id', appUserId).maybeSingle();
    if (row == null) return null;
    return CaregiverProfileModel.fromMap(row);
  }

  Future<String> saveMine(CaregiverProfileModel model) async {
    final appUserId = await _patientService.ensureAppUserId();
    if (appUserId == null) throw Exception('Not authenticated');

    final payload = CaregiverProfileModel(
      id: model.id,
      userId: appUserId,
      fullName: model.fullName,
      relationshipToPatient: model.relationshipToPatient,
      phone: model.phone,
      addressId: model.addressId,
      proximity: model.proximity,
      attendance: model.attendance,
      canDrive: model.canDrive,
      mobility: model.mobility,
    ).toInsertMap();

    await _supabase.from('caregiver_profiles').upsert(payload, onConflict: 'user_id');
    final row = await _supabase.from('caregiver_profiles').select('id').eq('user_id', appUserId).single();
    return row['id'].toString();
  }

  Future<void> deleteMine() async {
    final appUserId = await _patientService.ensureAppUserId();
    if (appUserId == null) return;
    await _supabase.from('caregiver_profiles').delete().eq('user_id', appUserId);
  }
}