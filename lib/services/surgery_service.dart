import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/surgery_model.dart';
import 'service_exceptions.dart';

// Handles CRUD operations for patient surgery records
class SurgeryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetches all surgery records.
  Future<List<SurgeryModel>> fetchByPatient(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return [];

    final rows = await _supabase
        .from('surgeries')
        .select()
        .eq('patient_id', pid)
        .order('created_at', ascending: false);

    return (rows as List)
        .map(
          (row) => SurgeryModel.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  // Saves/ creates/ updates a surgery record
  Future<String> save({
    required SurgeryModel surgery,
    required String patientId,
  }) async {
    final pid = requireText(patientId, 'patientId');
    final surgeryName = requireText(surgery.surgeryName, 'Surgery name');

    final payload = SurgeryModel(
      id: surgery.id,
      patientId: pid,
      surgeryName: surgeryName,
      surgeryDate: surgery.surgeryDate,
      place: trimToNull(surgery.place),
      prostheticOrImplant: trimToNull(surgery.prostheticOrImplant),
      notes: trimToNull(surgery.notes),
    );

    try {
      if (payload.id == null || payload.id!.isEmpty) {
        final inserted = await _supabase
            .from('surgeries')
            .insert(payload.toInsertMap())
            .select('id')
            .single();
        return inserted['id'].toString();
      }

      await _supabase
          .from('surgeries')
          .update(payload.toUpdateMap())
          .eq('id', payload.id!);
      return payload.id!;
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Surgery save'));
    }
  }

  // Deletes a surgery record.
  Future<void> delete({required String patientId, required String id}) async {
    final pid = requireText(patientId, 'patientId');
    final rowId = requireText(id, 'id');

    try {
      await _supabase
          .from('surgeries')
          .delete()
          .eq('id', rowId)
          .eq('patient_id', pid);
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Surgery delete'));
    }
  }
}
