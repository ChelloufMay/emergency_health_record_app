import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vaccination_model.dart';

class VaccinationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<VaccinationModel>> fetchByPatient(String patientId) async {
    final rows = await _supabase
        .from('vaccinations')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => VaccinationModel.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<String> save({
    required VaccinationModel vaccination,
    required String patientId,
  }) async {
    final payload = VaccinationModel(
      id: vaccination.id,
      patientId: patientId,
      vaccineName: vaccination.vaccineName,
      category: vaccination.category,
      doseNumber: vaccination.doseNumber,
      dateAdministered: vaccination.dateAdministered,
      notes: vaccination.notes,
    );

    if (payload.id == null || payload.id!.isEmpty) {
      final inserted = await _supabase.from('vaccinations').insert(payload.toInsertMap()).select('id').single();
      return inserted['id'].toString();
    }

    await _supabase.from('vaccinations').update(payload.toUpdateMap()).eq('id', payload.id!);
    return payload.id!;
  }

  Future<void> delete({
    required String patientId,
    required String id,
  }) async {
    await _supabase.from('vaccinations').delete().eq('id', id);
  }
}
