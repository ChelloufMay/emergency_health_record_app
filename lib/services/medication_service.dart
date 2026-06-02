import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medication_model.dart';
import 'service_exceptions.dart';

// Handles CRUD operations for patient medication records.
class MedicationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetches all medication records for a specific patient.
  Future<List<MedicationModel>> fetchByPatient(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return [];

    final rows = await _supabase
        .from('medications')
        .select()
        .eq('patient_id', pid)
        .order('created_at', ascending: false);

    return (rows as List)
        .map(
          (row) =>
              MedicationModel.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  // Saves/creates/updates a medication record.
  Future<String> save({
    required MedicationModel medication,
    required String patientId,
    String? actorUserId,
    String? actorRole,
  }) async {
    final pid = requireText(patientId, 'patientId');
    final medicationName = requireText(
      medication.medicationName,
      'Medication name',
    );

    final payload = MedicationModel(
      id: medication.id,
      patientId: pid,
      medicationName: medicationName,
      dosage: trimToNull(medication.dosage),
      frequency: trimToNull(medication.frequency),
      purpose: trimToNull(medication.purpose),
      startDate: medication.startDate,
      endDate: medication.endDate,
      source: medication.source.trim().isEmpty
          ? 'user'
          : medication.source.trim(),
    );

    try {
      if (payload.id == null || payload.id!.isEmpty) {
        final inserted = await _supabase
            .from('medications')
            .insert(payload.toInsertMap())
            .select('id')
            .single();
        return inserted['id'].toString();
      }

      await _supabase
          .from('medications')
          .update(payload.toUpdateMap())
          .eq('id', payload.id!);
      return payload.id!;
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Medication save'));
    }
  }

  // Deletes a medication record.
  Future<void> delete({
    required String patientId,
    required String id,
    String? actorUserId,
    String? actorRole,
  }) async {
    final pid = requireText(patientId, 'patientId');
    final rowId = requireText(id, 'id');

    try {
      await _supabase
          .from('medications')
          .delete()
          .eq('id', rowId)
          .eq('patient_id', pid);
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Medication delete'));
    }
  }
}
