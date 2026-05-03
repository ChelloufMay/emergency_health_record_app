import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reproductive_health_model.dart';
import 'audit_service.dart';

class ReproductiveHealthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();

  Future<ReproductiveHealthModel?> fetchReproductiveHealth(String patientId) async {
    final row = await _supabase
        .from('reproductive_health')
        .select()
        .eq('patient_id', patientId)
        .maybeSingle();

    if (row == null) return null;
    return ReproductiveHealthModel.fromMap(row);
  }

  Future<void> saveReproductiveHealth({
    required ReproductiveHealthModel item,
    required String performedByUserId,
  }) async {
    final existing = await _supabase
        .from('reproductive_health')
        .select('id')
        .eq('patient_id', item.patientId)
        .maybeSingle();

    if (existing == null) {
      final inserted = await _supabase
          .from('reproductive_health')
          .insert(item.toMap())
          .select('id')
          .single();

      await _audit.log(
        patientId: item.patientId,
        performedByUserId: performedByUserId,
        action: 'create',
        entityType: 'reproductive_health',
        entityId: inserted['id'] as String,
        fieldName: 'pregnancy_history',
        newValue: item.pregnancyHistory,
      );
    } else {
      await _supabase
          .from('reproductive_health')
          .update(item.toMap())
          .eq('patient_id', item.patientId);

      await _audit.log(
        patientId: item.patientId,
        performedByUserId: performedByUserId,
        action: 'update',
        entityType: 'reproductive_health',
        entityId: existing['id'] as String,
        fieldName: 'pregnancy_history',
        newValue: item.pregnancyHistory,
      );
    }
  }
}