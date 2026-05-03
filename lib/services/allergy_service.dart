import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/allergy_model.dart';
import 'audit_service.dart';

class AllergyService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();

  Future<List<AllergyModel>> fetchAllergies(String patientId) async {
    final rows = await _supabase
        .from('allergies')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => AllergyModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<String> saveAllergy({
    required AllergyModel allergy,
    required String performedByUserId,
    String? existingId,
  }) async {
    if (existingId != null) {
      await _supabase
          .from('allergies')
          .update(allergy.toMap())
          .eq('id', existingId);

      await _audit.log(
        patientId: allergy.patientId,
        performedByUserId: performedByUserId,
        action: 'update',
        entityType: 'allergies',
        entityId: existingId,
        fieldName: 'allergen_name',
        newValue: allergy.allergenName,
      );

      return existingId;
    } else {
      final result = await _supabase
          .from('allergies')
          .insert(allergy.toMap())
          .select('id')
          .single();

      final newId = result['id'] as String;

      await _audit.log(
        patientId: allergy.patientId,
        performedByUserId: performedByUserId,
        action: 'create',
        entityType: 'allergies',
        entityId: newId,
        fieldName: 'allergen_name',
        newValue: allergy.allergenName,
      );

      return newId;
    }
  }

  Future<void> deleteAllergy({
    required String id,
    required String patientId,
    required String performedByUserId,
    required String allergenName,
  }) async {
    await _supabase.from('allergies').delete().eq('id', id);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'delete',
      entityType: 'allergies',
      entityId: id,
      fieldName: 'allergen_name',
      oldValue: allergenName,
    );
  }
}