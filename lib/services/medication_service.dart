import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medication_model.dart';

class MedicationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<MedicationModel>> fetchByPatient(String patientId) async {
    final rows = await _supabase
        .from('medications')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => MedicationModel.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<String> save({
    required MedicationModel medication,
    required String patientId,
  }) async {
    final payload = MedicationModel(
      id: medication.id,
      patientId: patientId,
      medicationName: medication.medicationName,
      dosage: medication.dosage,
      frequency: medication.frequency,
      purpose: medication.purpose,
      startDate: medication.startDate,
      endDate: medication.endDate,
      source: medication.source,
    );

    if (payload.id == null || payload.id!.isEmpty) {
      final inserted = await _supabase.from('medications').insert(payload.toInsertMap()).select('id').single();
      return inserted['id'].toString();
    }

    await _supabase.from('medications').update(payload.toUpdateMap()).eq('id', payload.id!);
    return payload.id!;
  }

  Future<void> delete({
    required String patientId,
    required String id,
  }) async {
    await _supabase.from('medications').delete().eq('id', id).eq('patient_id', patientId);
  }
}
