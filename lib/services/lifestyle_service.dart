import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lifestyle_model.dart';

class LifestyleService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<LifestyleModel?> fetchByPatient(String patientId) async {
    final row = await _supabase
        .from('lifestyle_factors')
        .select()
        .eq('patient_id', patientId)
        .maybeSingle();

    if (row == null) return null;
    return LifestyleModel.fromMap(Map<String, dynamic>.from(row));
  }

  Future<String> save({
    required LifestyleModel lifestyle,
    required String patientId,
  }) async {
    final payload = LifestyleModel(
      id: lifestyle.id,
      patientId: patientId,
      livesAlone: lifestyle.livesAlone,
      hasCaregiver: lifestyle.hasCaregiver,
      stairsInHome: lifestyle.stairsInHome,
      socioeconomicClass: lifestyle.socioeconomicClass,
      workStatus: lifestyle.workStatus,
      smoking: lifestyle.smoking,
      packsPerDay: lifestyle.packsPerDay,
      smokingYears: lifestyle.smokingYears,
      drugs: lifestyle.drugs,
      drugType: lifestyle.drugType,
      drugQuantity: lifestyle.drugQuantity,
      chicha: lifestyle.chicha,
      chichaYears: lifestyle.chichaYears,
      alcoholFrequency: lifestyle.alcoholFrequency,
      foodQuality: lifestyle.foodQuality,
      milkType: lifestyle.milkType,
      waterType: lifestyle.waterType,
    );

    final existing = await _supabase.from('lifestyle_factors').select('id').eq('patient_id', patientId).maybeSingle();

    if (existing == null) {
      final inserted = await _supabase.from('lifestyle_factors').insert(payload.toInsertMap()).select('id').single();
      return inserted['id'].toString();
    }

    final id = existing['id'].toString();
    await _supabase.from('lifestyle_factors').update(payload.toUpdateMap()).eq('patient_id', patientId);
    return id;
  }

  Future<void> delete({
    required String patientId,
  }) async {
    await _supabase.from('lifestyle_factors').delete().eq('patient_id', patientId);
  }
}
