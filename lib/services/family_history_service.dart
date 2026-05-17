import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/family_history_model.dart';

class FamilyHistoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<FamilyHistoryModel>> fetchByPatient(String patientId) async {
    final rows = await _supabase
        .from('family_history')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => FamilyHistoryModel.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<String> save({
    required FamilyHistoryModel familyHistory,
    required String patientId,
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
      return inserted['id'].toString();
    }

    await _supabase.from('family_history').update(payload.toUpdateMap()).eq('id', payload.id!);
    return payload.id!;
  }

  Future<void> delete({
    required String patientId,
    required String id,
  }) async {
    await _supabase.from('family_history').delete().eq('id', id).eq('patient_id', patientId);
  }
}
