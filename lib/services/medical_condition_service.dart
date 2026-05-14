import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medical_condition_model.dart';
import 'audit_service.dart';

class MedicalConditionService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();

  Future<List<MedicalConditionModel>> fetchByPatient(String patientId) async {
    final rows = await _supabase
        .from('medical_conditions')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List).map((row) => MedicalConditionModel.fromMap(row as Map)).toList();
  }

  Future<String> save({
    required MedicalConditionModel condition,
    required String patientId,
    required String performedByUserId,
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
      final id = inserted['id'].toString();

      await _audit.log(
        patientId: patientId,
        performedByUserId: performedByUserId,
        action: 'create',
        entityType: 'medical_conditions',
        entityId: id,
        fieldName: 'condition_name',
        newValue: payload.conditionName,
      );

      return id;
    }

    await _supabase.from('medical_conditions').update(payload.toUpdateMap()).eq('id', payload.id!);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'update',
      entityType: 'medical_conditions',
      entityId: payload.id!,
      fieldName: 'condition_name',
      newValue: payload.conditionName,
    );

    return payload.id!;
  }

  Future<void> delete({
    required String patientId,
    required String id,
    required String performedByUserId,
  }) async {
    await _supabase.from('medical_conditions').delete().eq('id', id);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'delete',
      entityType: 'medical_conditions',
      entityId: id,
    );
  }
}