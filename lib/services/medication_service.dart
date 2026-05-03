import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medication_model.dart';
import 'audit_service.dart';

class MedicationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();

  Future<List<MedicationModel>> fetchMedications(String patientId) async {
    final rows = await _supabase
        .from('medications')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => MedicationModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<String> saveMedication({
    required MedicationModel medication,
    required String performedByUserId,
    String? existingId,
  }) async {
    if (existingId != null) {
      await _supabase
          .from('medications')
          .update(medication.toMap())
          .eq('id', existingId);

      await _audit.log(
        patientId: medication.patientId,
        performedByUserId: performedByUserId,
        action: 'update',
        entityType: 'medications',
        entityId: existingId,
        fieldName: 'medication_name',
        newValue: medication.medicationName,
      );

      return existingId;
    } else {
      final result = await _supabase
          .from('medications')
          .insert(medication.toMap())
          .select('id')
          .single();

      final newId = result['id'] as String;

      await _audit.log(
        patientId: medication.patientId,
        performedByUserId: performedByUserId,
        action: 'create',
        entityType: 'medications',
        entityId: newId,
        fieldName: 'medication_name',
        newValue: medication.medicationName,
      );

      return newId;
    }
  }

  Future<void> deleteMedication({
    required String id,
    required String patientId,
    required String performedByUserId,
    required String medicationName,
  }) async {
    await _supabase.from('medications').delete().eq('id', id);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'delete',
      entityType: 'medications',
      entityId: id,
      fieldName: 'medication_name',
      oldValue: medicationName,
    );
  }
}