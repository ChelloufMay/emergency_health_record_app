import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/family_history_model.dart';
import 'audit_service.dart';

class FamilyHistoryService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();

  Future<List<FamilyHistoryModel>> fetchFamilyHistory(String patientId) async {
    final rows = await _supabase
        .from('family_history')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => FamilyHistoryModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<String> saveFamilyHistory({
    required FamilyHistoryModel item,
    required String performedByUserId,
    String? existingId,
  }) async {
    if (existingId != null) {
      await _supabase
          .from('family_history')
          .update(item.toMap())
          .eq('id', existingId);

      await _audit.log(
        patientId: item.patientId,
        performedByUserId: performedByUserId,
        action: 'update',
        entityType: 'family_history',
        entityId: existingId,
        fieldName: 'condition_name',
        newValue: item.conditionName,
      );

      return existingId;
    } else {
      final result = await _supabase
          .from('family_history')
          .insert(item.toMap())
          .select('id')
          .single();

      final newId = result['id'] as String;

      await _audit.log(
        patientId: item.patientId,
        performedByUserId: performedByUserId,
        action: 'create',
        entityType: 'family_history',
        entityId: newId,
        fieldName: 'condition_name',
        newValue: item.conditionName,
      );

      return newId;
    }
  }

  Future<void> deleteFamilyHistory({
    required String id,
    required String patientId,
    required String performedByUserId,
    required String conditionName,
  }) async {
    await _supabase.from('family_history').delete().eq('id', id);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'delete',
      entityType: 'family_history',
      entityId: id,
      fieldName: 'condition_name',
      oldValue: conditionName,
    );
  }
}