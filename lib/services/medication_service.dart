import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medication_model.dart';

class MedicationService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<MedicationModel>> fetchMedications(String patientId) async {
    final response = await _client
        .from('medications')
        .select('*')
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    final rows = response as List<dynamic>;
    return rows
        .map((row) => MedicationModel.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<MedicationModel> saveMedication({
    required MedicationModel medication,
    required String performedByUserId,
    String? existingId,
  }) async {
    final data = medication.toMap();

    if (existingId != null && existingId.isNotEmpty) {
      final response = await _client
          .from('medications')
          .update(data)
          .eq('id', existingId)
          .select('*')
          .single();

      return MedicationModel.fromMap(
        Map<String, dynamic>.from(response as Map),
      );
    } else {
      final response = await _client
          .from('medications')
          .insert(data)
          .select('*')
          .single();

      return MedicationModel.fromMap(
        Map<String, dynamic>.from(response as Map),
      );
    }
  }

  Future<void> deleteMedication({
    required String id,
    required String patientId,
    required String performedByUserId,
    required String medicationName,
  }) async {
    await _client.from('medications').delete().eq('id', id);
  }
}