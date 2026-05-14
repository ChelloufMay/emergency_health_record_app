import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hospitalization_model.dart';
import 'audit_service.dart';

class HospitalizationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();

  Future<List<HospitalizationModel>> fetchByPatient(String patientId) async {
    final rows = await _supabase
        .from('hospitalizations')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List).map((row) => HospitalizationModel.fromMap(row as Map)).toList();
  }

  Future<String> save({
    required HospitalizationModel hospitalization,
    required String patientId,
    required String performedByUserId,
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
      final id = inserted['id'].toString();

      await _audit.log(
        patientId: patientId,
        performedByUserId: performedByUserId,
        action: 'create',
        entityType: 'hospitalizations',
        entityId: id,
        fieldName: 'hospital_name',
        newValue: payload.hospitalName,
      );

      return id;
    }

    await _supabase.from('hospitalizations').update(payload.toUpdateMap()).eq('id', payload.id!);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'update',
      entityType: 'hospitalizations',
      entityId: payload.id!,
      fieldName: 'hospital_name',
      newValue: payload.hospitalName,
    );

    return payload.id!;
  }

  Future<void> delete({
    required String patientId,
    required String id,
    required String performedByUserId,
  }) async {
    await _supabase.from('hospitalizations').delete().eq('id', id);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'delete',
      entityType: 'hospitalizations',
      entityId: id,
    );
  }
}