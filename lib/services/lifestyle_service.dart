import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lifestyle_model.dart';
import 'service_exceptions.dart';

// Handles CRUD operations for patient lifestyle factor records.
class LifestyleService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetches the lifestyle factor record for a specific patient.
  Future<LifestyleModel?> fetchByPatient(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return null;

    final row = await _supabase
        .from('lifestyle_factors')
        .select()
        .eq('patient_id', pid)
        .maybeSingle();

    if (row == null) return null;
    return LifestyleModel.fromMap(Map<String, dynamic>.from(row));
  }

  // Saves/creates/updates the lifestyle factor
  Future<String> save({
    required LifestyleModel lifestyle,
    required String patientId,
  }) async {
    final pid = requireText(patientId, 'patientId');

    final payload = LifestyleModel(
      id: lifestyle.id,
      patientId: pid,
      livesAlone: lifestyle.livesAlone,
      hasCaregiver: lifestyle.hasCaregiver,
      stairsInHome: lifestyle.stairsInHome,
      socioeconomicClass: lifestyle.socioeconomicClass.trim().isEmpty
          ? 'unknown'
          : lifestyle.socioeconomicClass.trim(),
      workStatus: trimToNull(lifestyle.workStatus),
      smoking: lifestyle.smoking,
      packsPerDay: lifestyle.packsPerDay,
      smokingYears: lifestyle.smokingYears,
      drugs: lifestyle.drugs,
      drugType: trimToNull(lifestyle.drugType),
      drugQuantity: trimToNull(lifestyle.drugQuantity),
      chicha: lifestyle.chicha,
      chichaYears: lifestyle.chichaYears,
      alcoholFrequency: trimToNull(lifestyle.alcoholFrequency),
      foodQuality: trimToNull(lifestyle.foodQuality),
      milkType: trimToNull(lifestyle.milkType),
      waterType: trimToNull(lifestyle.waterType),
    );

    try {
      final existing = await _supabase
          .from('lifestyle_factors')
          .select('id')
          .eq('patient_id', pid)
          .maybeSingle();

      if (existing == null) {
        final inserted = await _supabase
            .from('lifestyle_factors')
            .insert(payload.toInsertMap())
            .select('id')
            .single();
        return inserted['id'].toString();
      }

      final id = existing['id'].toString();
      await _supabase
          .from('lifestyle_factors')
          .update(payload.toUpdateMap())
          .eq('patient_id', pid);
      return id;
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Lifestyle save'));
    }
  }

  // Deletes the lifestyle factor record
  Future<void> delete({required String patientId}) async {
    final pid = requireText(patientId, 'patientId');

    try {
      await _supabase.from('lifestyle_factors').delete().eq('patient_id', pid);
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Lifestyle delete'));
    }
  }
}
