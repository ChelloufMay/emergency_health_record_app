import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vaccination_model.dart';
import 'audit_service.dart';

class VaccinationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();

  Future<List<VaccinationModel>> fetchByPatient(String patientId) async {
    final rows = await _supabase
        .from('vaccinations')
        .select()
        .eq('patient_id', patientId)
        .order('date_administered', ascending: false, nullsFirst: false);

    return (rows as List).map((row) => VaccinationModel.fromMap(row as Map)).toList();
  }

  Future<String> save({
    required VaccinationModel vaccination,
    required String patientId,
    required String performedByUserId,
  }) async {
    final payload = VaccinationModel(
      id: vaccination.id,
      patientId: patientId,
      vaccineName: vaccination.vaccineName,
      category: vaccination.category,
      doseNumber: vaccination.doseNumber,
      dateAdministered: vaccination.dateAdministered,
      notes: vaccination.notes,
    );

    if (payload.id == null || payload.id!.isEmpty) {
      final inserted = await _supabase.from('vaccinations').insert(payload.toInsertMap()).select('id').single();
      final id = inserted['id'].toString();

      await _audit.log(
        patientId: patientId,
        performedByUserId: performedByUserId,
        action: 'create',
        entityType: 'vaccinations',
        entityId: id,
        fieldName: 'vaccine_name',
        newValue: payload.vaccineName,
      );

      return id;
    }

    await _supabase.from('vaccinations').update(payload.toUpdateMap()).eq('id', payload.id!);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'update',
      entityType: 'vaccinations',
      entityId: payload.id!,
      fieldName: 'vaccine_name',
      newValue: payload.vaccineName,
    );

    return payload.id!;
  }

  Future<void> delete({
    required String patientId,
    required String id,
    required String performedByUserId,
  }) async {
    await _supabase.from('vaccinations').delete().eq('id', id);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'delete',
      entityType: 'vaccinations',
      entityId: id,
    );
  }
}