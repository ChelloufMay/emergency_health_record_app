import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/hospitalization_model.dart';

class HospitalizationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<HospitalizationModel>> fetchByPatient(String patientId) async {
    final rows = await _supabase
        .from('hospitalizations')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => HospitalizationModel.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<String> save({
    required HospitalizationModel hospitalization,
    required String patientId,
  }) async {
    final payload = HospitalizationModel(
      id: hospitalization.id,
      patientId: patientId,
      hospitalName: hospitalization.hospitalName,
      admissionDate: hospitalization.admissionDate,
      dischargeDate: hospitalization.dischargeDate,
      reason: hospitalization.reason,
      notes: hospitalization.notes,
    );

    if (payload.id == null || payload.id!.isEmpty) {
      final inserted = await _supabase.from('hospitalizations').insert(payload.toInsertMap()).select('id').single();
      return inserted['id'].toString();
    }

    await _supabase.from('hospitalizations').update(payload.toUpdateMap()).eq('id', payload.id!);
    return payload.id!;
  }

  Future<void> delete({
    required String patientId,
    required String id,
  }) async {
    await _supabase.from('hospitalizations').delete().eq('id', id).eq('patient_id', patientId);
  }
}