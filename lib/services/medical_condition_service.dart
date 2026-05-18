import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medical_condition_model.dart';
import 'service_exceptions.dart';

class MedicalConditionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<MedicalConditionModel>> fetchByPatient(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return [];

    final rows = await _supabase
        .from('medical_conditions')
        .select()
        .eq('patient_id', pid)
        .order('created_at', ascending: false);

    return (rows as List)
        .map(
          (row) => MedicalConditionModel.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<String> save({
    required MedicalConditionModel condition,
    required String patientId,
  }) async {
    final pid = requireText(patientId, 'patientId');
    final conditionName = requireText(
      condition.conditionName,
      'Condition name',
    );

    final payload = MedicalConditionModel(
      id: condition.id,
      patientId: pid,
      conditionName: conditionName,
      type: condition.type.trim().isEmpty ? 'chronic' : condition.type.trim(),
      diagnosisDate: condition.diagnosisDate,
      diagnosisPlace: trimToNull(condition.diagnosisPlace),
      followUpDoctor: trimToNull(condition.followUpDoctor),
      treatment: trimToNull(condition.treatment),
      notes: trimToNull(condition.notes),
    );

    try {
      if (payload.id == null || payload.id!.isEmpty) {
        final inserted = await _supabase
            .from('medical_conditions')
            .insert(payload.toInsertMap())
            .select('id')
            .single();
        return inserted['id'].toString();
      }

      await _supabase
          .from('medical_conditions')
          .update(payload.toUpdateMap())
          .eq('id', payload.id!);
      return payload.id!;
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Condition save'));
    }
  }

  Future<void> delete({required String patientId, required String id}) async {
    final pid = requireText(patientId, 'patientId');
    final rowId = requireText(id, 'id');

    try {
      await _supabase
          .from('medical_conditions')
          .delete()
          .eq('id', rowId)
          .eq('patient_id', pid);
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Condition delete'));
    }
  }
}
