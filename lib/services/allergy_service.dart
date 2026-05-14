import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/allergy_model.dart';
import 'audit_service.dart';

class AllergyService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();

  Future<List<AllergyModel>> fetchByPatient(String patientId) async {
    final rows = await _supabase
        .from('allergies')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List).map((row) => AllergyModel.fromMap(row as Map)).toList();
  }

  Future<String> save({
    required AllergyModel allergy,
    required String patientId,
    required String performedByUserId,
  }) async {
    final payload = AllergyModel(
      id: allergy.id,
      patientId: patientId,
      allergenName: allergy.allergenName,
      allergyType: allergy.allergyType,
      reaction: allergy.reaction,
      severity: allergy.severity,
      source: allergy.source,
    );

    if (payload.id == null || payload.id!.isEmpty) {
      final inserted = await _supabase.from('allergies').insert(payload.toInsertMap()).select('id').single();
      final id = inserted['id'].toString();

      await _audit.log(
        patientId: patientId,
        performedByUserId: performedByUserId,
        action: 'create',
        entityType: 'allergies',
        entityId: id,
        fieldName: 'allergen_name',
        newValue: payload.allergenName,
      );

      return id;
    }

    await _supabase.from('allergies').update(payload.toUpdateMap()).eq('id', payload.id!);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'update',
      entityType: 'allergies',
      entityId: payload.id!,
      fieldName: 'allergen_name',
      newValue: payload.allergenName,
    );

    return payload.id!;
  }

  Future<void> delete({
    required String patientId,
    required String id,
    required String performedByUserId,
  }) async {
    await _supabase.from('allergies').delete().eq('id', id);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'delete',
      entityType: 'allergies',
      entityId: id,
    );
  }
}