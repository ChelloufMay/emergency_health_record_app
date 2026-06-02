import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/hospitalization_model.dart';
import 'service_exceptions.dart';

// Managing patient hospitalization records.
class HospitalizationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetches all hospitalisation records for a specific patient
  Future<List<HospitalizationModel>> fetchByPatient(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return [];

    final rows = await _supabase
        .from('hospitalizations')
        .select()
        .eq('patient_id', pid)
        .order('created_at', ascending: false);

    return (rows as List)
        .map(
          (row) => HospitalizationModel.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  // Saves or updates a hospitalisation record.
  Future<String> save({
    required HospitalizationModel hospitalization,
    required String patientId,
  }) async {
    final pid = requireText(patientId, 'patientId');

    final payload = HospitalizationModel(
      id: hospitalization.id,
      patientId: pid,
      hospitalName: trimToNull(hospitalization.hospitalName),
      admissionDate: hospitalization.admissionDate,
      dischargeDate: hospitalization.dischargeDate,
      reason: trimToNull(hospitalization.reason),
      notes: trimToNull(hospitalization.notes),
    );

    try {
      if (payload.id == null || payload.id!.isEmpty) {
        final inserted = await _supabase
            .from('hospitalizations')
            .insert(payload.toInsertMap())
            .select('id')
            .single();
        return inserted['id'].toString();
      }

      await _supabase
          .from('hospitalizations')
          .update(payload.toUpdateMap())
          .eq('id', payload.id!);
      return payload.id!;
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Hospitalization save'));
    }
  }

  // Deletes a specific hospitalisation record for a patient.
  Future<void> delete({required String patientId, required String id}) async {
    final pid = requireText(patientId, 'patientId');
    final rowId = requireText(id, 'id');

    try {
      await _supabase
          .from('hospitalizations')
          .delete()
          .eq('id', rowId)
          .eq('patient_id', pid);
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Hospitalization delete'));
    }
  }
}
