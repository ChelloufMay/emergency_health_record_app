import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/family_history_model.dart';
import 'audit_service.dart';

class FamilyHistoryService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();

  Future<List<FamilyHistoryModel>> fetchByPatient(String patientId) async {
    final rows = await _supabase
        .from('family_history')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List).map((row) => FamilyHistoryModel.fromMap(row as Map)).toList();
  }

  Future<String> save({
    required FamilyHistoryModel familyHistory,
    required String patientId,
    required String performedByUserId,
  }) async {
    final payload = FamilyHistoryModel(
      id: familyHistory.id,
      patientId: patientId,
      relation: familyHistory.relation,
      conditionName: familyHistory.conditionName,
      category: familyHistory.category,
      isGenetic: familyHistory.isGenetic,
      notes: familyHistory.notes,
    );

    if (payload.id == null || payload.id!.isEmpty) {
      final inserted = await _supabase.from('family_history').insert(payload.toInsertMap()).select('id').single();
      final id = inserted['id'].toString();

      await _audit.log(
        patientId: patientId,
        performedByUserId: performedByUserId,
        action: 'create',
        entityType: 'family_history',
        entityId: id,
        fieldName: 'condition_name',
        newValue: payload.conditionName,
      );

      return id;
    }

    await _supabase.from('family_history').update(payload.toUpdateMap()).eq('id', payload.id!);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'update',
      entityType: 'family_history',
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
    await _supabase.from('family_history').delete().eq('id', id);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'delete',
      entityType: 'family_history',
      entityId: id,
    );
  }
}