import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medication_model.dart';
import 'audit_service.dart';

class MedicationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();

  Future<List<MedicationModel>> fetchByPatient(String patientId) async {
    final rows = await _supabase
        .from('medications')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List).map((row) => MedicationModel.fromMap(row as Map)).toList();
  }

  Future<String> save({
    required MedicationModel medication,
    required String patientId,
    required String performedByUserId,
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
      final id = inserted['id'].toString();

      await _audit.log(
        patientId: patientId,
        performedByUserId: performedByUserId,
        action: 'create',
        entityType: 'medications',
        entityId: id,
        fieldName: 'medication_name',
        newValue: payload.medicationName,
      );

      return id;
    }

    await _supabase.from('medications').update(payload.toUpdateMap()).eq('id', payload.id!);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'update',
      entityType: 'medications',
      entityId: payload.id!,
      fieldName: 'medication_name',
      newValue: payload.medicationName,
    );

    return payload.id!;
  }

  Future<void> delete({
    required String patientId,
    required String id,
    required String performedByUserId,
  }) async {
    await _supabase.from('medications').delete().eq('id', id);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'delete',
      entityType: 'medications',
      entityId: id,
    );
  }
}