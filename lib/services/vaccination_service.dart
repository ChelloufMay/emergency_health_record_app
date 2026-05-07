import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vaccination_model.dart';
import 'audit_service.dart';

class VaccinationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();

  Future<List<VaccinationModel>> fetchVaccinations(String patientId) async {
    final rows = await _supabase
        .from('vaccinations')
        .select('*')
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => VaccinationModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<String> saveVaccination({
    required VaccinationModel vaccination,
    required String performedByUserId,
    String? existingId,
  }) async {
    final payload = vaccination.toMap();

    if (existingId != null) {
      await _supabase
          .from('vaccinations')
          .update({
        ...payload,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', existingId);

      await _audit.log(
        patientId: vaccination.patientId,
        performedByUserId: performedByUserId,
        action: 'update',
        entityType: 'vaccinations',
        entityId: existingId,
        fieldName: 'vaccine_name',
        newValue: vaccination.vaccineName,
      );

      return existingId;
    } else {
      final result = await _supabase
          .from('vaccinations')
          .insert({
        ...payload,
        'created_at': vaccination.createdAt.toIso8601String(),
        'updated_at': vaccination.updatedAt.toIso8601String(),
      })
          .select('id')
          .single();

      final newId = result['id'] as String;

      await _audit.log(
        patientId: vaccination.patientId,
        performedByUserId: performedByUserId,
        action: 'create',
        entityType: 'vaccinations',
        entityId: newId,
        fieldName: 'vaccine_name',
        newValue: vaccination.vaccineName,
      );

      return newId;
    }
  }

  Future<void> deleteVaccination({
    required String id,
    required String patientId,
    required String performedByUserId,
    required String vaccineName,
  }) async {
    await _supabase.from('vaccinations').delete().eq('id', id);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'delete',
      entityType: 'vaccinations',
      entityId: id,
      fieldName: 'vaccine_name',
      oldValue: vaccineName,
    );
  }
}