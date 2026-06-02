import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/family_history_model.dart';
import 'service_exceptions.dart';

// Handles CRUD operations for a patient's family medical history records.
class FamilyHistoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetches all family history records for a specific patient.
  Future<List<FamilyHistoryModel>> fetchByPatient(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return [];

    final rows = await _supabase
        .from('family_history')
        .select()
        .eq('patient_id', pid)
        .order('created_at', ascending: false);

    return (rows as List)
        .map(
          (row) =>
              FamilyHistoryModel.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  // Saves/creates/updates a family history record.
  Future<String> save({
    required FamilyHistoryModel familyHistory,
    required String patientId,
  }) async {
    final pid = requireText(patientId, 'patientId');
    final conditionName = requireText(
      familyHistory.conditionName,
      'Condition name',
    );

    final payload = FamilyHistoryModel(
      id: familyHistory.id,
      patientId: pid,
      relation: trimToNull(familyHistory.relation),
      conditionName: conditionName,
      category: trimToNull(familyHistory.category),
      isGenetic: familyHistory.isGenetic,
      notes: trimToNull(familyHistory.notes),
    );

    try {
      if (payload.id == null || payload.id!.isEmpty) {
        final inserted = await _supabase
            .from('family_history')
            .insert(payload.toInsertMap())
            .select('id')
            .single();
        return inserted['id'].toString();
      }

      await _supabase
          .from('family_history')
          .update(payload.toUpdateMap())
          .eq('id', payload.id!);
      return payload.id!;
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Family history save'));
    }
  }

  // Deletes a family history record.
  Future<void> delete({required String patientId, required String id}) async {
    final pid = requireText(patientId, 'patientId');
    final rowId = requireText(id, 'id');

    try {
      await _supabase
          .from('family_history')
          .delete()
          .eq('id', rowId)
          .eq('patient_id', pid);
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Family history delete'));
    }
  }
}
