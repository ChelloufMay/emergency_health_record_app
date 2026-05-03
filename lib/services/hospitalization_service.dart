import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hospitalization_model.dart';
import 'audit_service.dart';

class HospitalizationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();

  Future<List<HospitalizationModel>> fetchHospitalizations(String patientId) async {
    final rows = await _supabase
        .from('hospitalizations')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => HospitalizationModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<String> saveHospitalization({
    required HospitalizationModel hospitalization,
    required String performedByUserId,
    String? existingId,
  }) async {
    if (existingId != null) {
      await _supabase
          .from('hospitalizations')
          .update(hospitalization.toMap())
          .eq('id', existingId);

      await _audit.log(
        patientId: hospitalization.patientId,
        performedByUserId: performedByUserId,
        action: 'update',
        entityType: 'hospitalizations',
        entityId: existingId,
        fieldName: 'hospital_name',
        newValue: hospitalization.hospitalName,
      );

      return existingId;
    } else {
      final result = await _supabase
          .from('hospitalizations')
          .insert(hospitalization.toMap())
          .select('id')
          .single();

      final newId = result['id'] as String;

      await _audit.log(
        patientId: hospitalization.patientId,
        performedByUserId: performedByUserId,
        action: 'create',
        entityType: 'hospitalizations',
        entityId: newId,
        fieldName: 'hospital_name',
        newValue: hospitalization.hospitalName,
      );

      return newId;
    }
  }

  Future<void> deleteHospitalization({
    required String id,
    required String patientId,
    required String performedByUserId,
    required String hospitalName,
  }) async {
    await _supabase.from('hospitalizations').delete().eq('id', id);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'delete',
      entityType: 'hospitalizations',
      entityId: id,
      fieldName: 'hospital_name',
      oldValue: hospitalName,
    );
  }
}