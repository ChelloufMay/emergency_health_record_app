import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vaccination_model.dart';
import 'service_exceptions.dart';

// Handles CRUD operations for patient vaccination records
class VaccinationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetches all vaccination records
  Future<List<VaccinationModel>> fetchByPatient(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return [];

    final rows = await _supabase
        .from('vaccinations')
        .select()
        .eq('patient_id', pid)
        .order('created_at', ascending: false);

    return (rows as List)
        .map(
          (row) =>
              VaccinationModel.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  // Saves/creates/updates a vaccination record.
  Future<String> save({
    required VaccinationModel vaccination,
    required String patientId,
  }) async {
    final pid = requireText(patientId, 'patientId');
    final vaccineName = requireText(vaccination.vaccineName, 'Vaccine name');

    final payload = VaccinationModel(
      id: vaccination.id,
      patientId: pid,
      vaccineName: vaccineName,
      category: vaccination.category.trim().isEmpty
          ? 'other'
          : vaccination.category.trim(),
      doseNumber: vaccination.doseNumber,
      dateAdministered: vaccination.dateAdministered,
      notes: trimToNull(vaccination.notes),
    );

    try {
      if (payload.id == null || payload.id!.isEmpty) {
        final inserted = await _supabase
            .from('vaccinations')
            .insert(payload.toInsertMap())
            .select('id')
            .single();
        return inserted['id'].toString();
      }

      await _supabase
          .from('vaccinations')
          .update(payload.toUpdateMap())
          .eq('id', payload.id!);
      return payload.id!;
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Vaccination save'));
    }
  }

  // Deletes a vaccination record.
  Future<void> delete({required String patientId, required String id}) async {
    final pid = requireText(patientId, 'patientId');
    final rowId = requireText(id, 'id');

    try {
      await _supabase
          .from('vaccinations')
          .delete()
          .eq('id', rowId)
          .eq('patient_id', pid);
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Vaccination delete'));
    }
  }
}
