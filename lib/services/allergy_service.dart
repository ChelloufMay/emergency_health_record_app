import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/allergy_model.dart';
import 'service_exceptions.dart';

class AllergyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<AllergyModel>> fetchByPatient(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return [];

    final rows = await _supabase
        .from('allergies')
        .select()
        .eq('patient_id', pid)
        .order('created_at', ascending: false);

    return (rows as List)
        .map(
          (row) => AllergyModel.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<String> save({
    required AllergyModel allergy,
    required String patientId,
  }) async {
    final pid = requireText(patientId, 'patientId');
    final allergen = requireText(allergy.allergenName, 'Allergen name');

    final payload = AllergyModel(
      id: allergy.id,
      patientId: pid,
      allergenName: allergen,
      allergyType: allergy.allergyType.trim().isEmpty
          ? 'other'
          : allergy.allergyType.trim(),
      reaction: trimToNull(allergy.reaction),
      severity: trimToNull(allergy.severity),
      source: allergy.source.trim().isEmpty ? 'user' : allergy.source.trim(),
    );

    try {
      if (payload.id == null || payload.id!.isEmpty) {
        final inserted = await _supabase
            .from('allergies')
            .insert(payload.toInsertMap())
            .select('id')
            .single();

        return inserted['id'].toString();
      }

      await _supabase
          .from('allergies')
          .update(payload.toUpdateMap())
          .eq('id', payload.id!);

      return payload.id!;
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Allergy save'));
    }
  }

  Future<void> delete({required String patientId, required String id}) async {
    final pid = requireText(patientId, 'patientId');
    final rowId = requireText(id, 'id');

    try {
      await _supabase
          .from('allergies')
          .delete()
          .eq('id', rowId)
          .eq('patient_id', pid);
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Allergy delete'));
    }
  }
}
