import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/reproductive_health_model.dart';
import 'service_exceptions.dart';

// Managing patient reproductive health records.
class ReproductiveHealthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetches the reproductive health record.
  Future<ReproductiveHealthModel?> fetchByPatient(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return null;

    final row = await _supabase
        .from('reproductive_health')
        .select()
        .eq('patient_id', pid)
        .maybeSingle();

    if (row == null) return null;
    return ReproductiveHealthModel.fromMap(Map<String, dynamic>.from(row));
  }

  // Saves or updates the reproductive health record for a patient
  Future<String> save({
    required ReproductiveHealthModel reproductiveHealth,
    required String patientId,
  }) async {
    final pid = requireText(patientId, 'patientId');

    final payload = ReproductiveHealthModel(
      id: reproductiveHealth.id,
      patientId: pid,
      hasMenstrualCycle: reproductiveHealth.hasMenstrualCycle,
      cycleRegular: reproductiveHealth.cycleRegular,
      cyclePainful: reproductiveHealth.cyclePainful,
      painLevel: trimToNull(reproductiveHealth.painLevel),
      lastPeriodStart: reproductiveHealth.lastPeriodStart,
      lastPeriodEnd: reproductiveHealth.lastPeriodEnd,
      currentlyPregnant: reproductiveHealth.currentlyPregnant,
      pregnancyTermWeeks: reproductiveHealth.pregnancyTermWeeks,
      gestity: reproductiveHealth.gestity,
      parity: reproductiveHealth.parity,
      abortions: reproductiveHealth.abortions,
      pubertyAge: reproductiveHealth.pubertyAge,
      breastExamNotes: trimToNull(reproductiveHealth.breastExamNotes),
      pregnancyHistory: trimToNull(reproductiveHealth.pregnancyHistory),
      birthHistory: trimToNull(reproductiveHealth.birthHistory),
      abortionHistory: trimToNull(reproductiveHealth.abortionHistory),
    );

    try {
      final existing = await _supabase
          .from('reproductive_health')
          .select('id')
          .eq('patient_id', pid)
          .maybeSingle();

      if (existing == null) {
        final inserted = await _supabase
            .from('reproductive_health')
            .insert(payload.toInsertMap())
            .select('id')
            .single();
        return inserted['id'].toString();
      }

      final id = existing['id'].toString();
      await _supabase
          .from('reproductive_health')
          .update(payload.toUpdateMap())
          .eq('patient_id', pid);
      return id;
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Reproductive health save'));
    }
  }

  // Deletes the reproductive health.
  Future<void> delete({required String patientId}) async {
    final pid = requireText(patientId, 'patientId');

    try {
      await _supabase
          .from('reproductive_health')
          .delete()
          .eq('patient_id', pid);
    } on PostgrestException catch (e) {
      throw Exception(
        readablePostgrestMessage(e, 'Reproductive health delete'),
      );
    }
  }
}
