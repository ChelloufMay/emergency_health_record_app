import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medical_condition_model.dart';
import 'audit_service.dart';

class MedicalConditionService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();

  Future<List<MedicalConditionModel>> fetchConditions(String patientId) async {
    final rows = await _supabase
        .from('medical_conditions')
        .select('*')
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => MedicalConditionModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<String> saveCondition({
    required MedicalConditionModel condition,
    required String performedByUserId,
    String? existingId,
  }) async {
    if (existingId != null) {
      await _supabase
          .from('medical_conditions')
          .update(condition.toMap())
          .eq('id', existingId);

      await _audit.log(
        patientId: condition.patientId,
        performedByUserId: performedByUserId,
        action: 'update',
        entityType: 'medical_conditions',
        entityId: existingId,
        fieldName: 'condition_name',
        newValue: condition.conditionName,
      );

      return existingId;
    } else {
      final result = await _supabase
          .from('medical_conditions')
          .insert(condition.toMap())
          .select('id')
          .single();

      final newId = result['id'] as String;

      await _audit.log(
        patientId: condition.patientId,
        performedByUserId: performedByUserId,
        action: 'create',
        entityType: 'medical_conditions',
        entityId: newId,
        fieldName: 'condition_name',
        newValue: condition.conditionName,
      );

      return newId;
    }
  }

  Future<void> deleteCondition({
    required String id,
    required String patientId,
    required String performedByUserId,
    required String conditionName,
  }) async {
    await _supabase.from('medical_conditions').delete().eq('id', id);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'delete',
      entityType: 'medical_conditions',
      entityId: id,
      fieldName: 'condition_name',
      oldValue: conditionName,
    );
  }
}