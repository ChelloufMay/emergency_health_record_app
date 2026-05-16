import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medical_condition_model.dart';

class MedicalConditionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<MedicalConditionModel>> fetchByPatient(String patientId) async {
    final rows = await _supabase
        .from('medical_conditions')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => MedicalConditionModel.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<String> save({
    required MedicalConditionModel condition,
    required String patientId,
  }) async {
    final payload = MedicalConditionModel(
      id: condition.id,
      patientId: patientId,
      conditionName: condition.conditionName,
      type: condition.type,
      diagnosisDate: condition.diagnosisDate,
      diagnosisPlace: condition.diagnosisPlace,
      followUpDoctor: condition.followUpDoctor,
      treatment: condition.treatment,
      notes: condition.notes,
    );

    if (payload.id == null || payload.id!.isEmpty) {
      final inserted = await _supabase.from('medical_conditions').insert(payload.toInsertMap()).select('id').single();
      return inserted['id'].toString();
    }

    await _supabase.from('medical_conditions').update(payload.toUpdateMap()).eq('id', payload.id!);
    return payload.id!;
  }

  Future<void> delete({
    required String patientId,
    required String id,
  }) async {
    await _supabase.from('medical_conditions').delete().eq('id', id);
  }
}
