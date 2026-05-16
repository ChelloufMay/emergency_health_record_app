import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/allergy_model.dart';

class AllergyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<AllergyModel>> fetchByPatient(String patientId) async {
    final rows = await _supabase
        .from('allergies')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => AllergyModel.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<String> save({
    required AllergyModel allergy,
    required String patientId,
  }) async {
    final payload = AllergyModel(
      id: allergy.id,
      patientId: patientId,
      allergenName: allergy.allergenName,
      allergyType: allergy.allergyType,
      reaction: allergy.reaction,
      severity: allergy.severity,
      source: allergy.source,
    );

    if (payload.id == null || payload.id!.isEmpty) {
      final inserted = await _supabase.from('allergies').insert(payload.toInsertMap()).select('id').single();
      return inserted['id'].toString();
    }

    await _supabase.from('allergies').update(payload.toUpdateMap()).eq('id', payload.id!);
    return payload.id!;
  }

  Future<void> delete({
    required String patientId,
    required String id,
  }) async {
    await _supabase.from('allergies').delete().eq('id', id);
  }
}
