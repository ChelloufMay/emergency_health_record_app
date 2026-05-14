import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reproductive_health_model.dart';
import 'audit_service.dart';

class ReproductiveHealthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();

  Future<ReproductiveHealthModel?> fetchByPatient(String patientId) async {
    final row = await _supabase.from('reproductive_health').select().eq('patient_id', patientId).maybeSingle();
    if (row == null) return null;
    return ReproductiveHealthModel.fromMap(row);
  }

  Future<String> save({
    required ReproductiveHealthModel reproductiveHealth,
    required String patientId,
    required String performedByUserId,
  }) async {
    final payload = ReproductiveHealthModel(
      id: reproductiveHealth.id,
      patientId: patientId,
      hasMenstrualCycle: reproductiveHealth.hasMenstrualCycle,
      cycleRegular: reproductiveHealth.cycleRegular,
      cyclePainful: reproductiveHealth.cyclePainful,
      painLevel: reproductiveHealth.painLevel,
      lastPeriodStart: reproductiveHealth.lastPeriodStart,
      lastPeriodEnd: reproductiveHealth.lastPeriodEnd,
      currentlyPregnant: reproductiveHealth.currentlyPregnant,
      pregnancyTermWeeks: reproductiveHealth.pregnancyTermWeeks,
      gestity: reproductiveHealth.gestity,
      parity: reproductiveHealth.parity,
      abortions: reproductiveHealth.abortions,
      pubertyAge: reproductiveHealth.pubertyAge,
      breastExamNotes: reproductiveHealth.breastExamNotes,
      pregnancyHistory: reproductiveHealth.pregnancyHistory,
      birthHistory: reproductiveHealth.birthHistory,
      abortionHistory: reproductiveHealth.abortionHistory,
    );

    final existing = await _supabase.from('reproductive_health').select('id').eq('patient_id', patientId).maybeSingle();

    if (existing == null) {
      final inserted = await _supabase.from('reproductive_health').insert(payload.toInsertMap()).select('id').single();
      final id = inserted['id'].toString();

      await _audit.log(
        patientId: patientId,
        performedByUserId: performedByUserId,
        action: 'create',
        entityType: 'reproductive_health',
        entityId: id,
        fieldName: 'patient_id',
        newValue: patientId,
      );

      return id;
    }

    final id = existing['id'].toString();
    await _supabase.from('reproductive_health').update(payload.toUpdateMap()).eq('patient_id', patientId);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'update',
      entityType: 'reproductive_health',
      entityId: id,
      fieldName: 'patient_id',
      newValue: patientId,
    );

    return id;
  }

  Future<void> delete({
    required String patientId,
    required String performedByUserId,
  }) async {
    final existing = await _supabase.from('reproductive_health').select('id').eq('patient_id', patientId).maybeSingle();
    if (existing == null) return;

    final id = existing['id'].toString();
    await _supabase.from('reproductive_health').delete().eq('patient_id', patientId);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'delete',
      entityType: 'reproductive_health',
      entityId: id,
    );
  }
}