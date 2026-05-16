import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/reproductive_health_model.dart';

class ReproductiveHealthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<ReproductiveHealthModel?> fetchByPatient(String patientId) async {
    final row = await _supabase
        .from('reproductive_health')
        .select()
        .eq('patient_id', patientId)
        .maybeSingle();

    if (row == null) return null;
    return ReproductiveHealthModel.fromMap(Map<String, dynamic>.from(row));
  }

  Future<String> save({
    required ReproductiveHealthModel reproductiveHealth,
    required String patientId,
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
      return inserted['id'].toString();
    }

    final id = existing['id'].toString();
    await _supabase.from('reproductive_health').update(payload.toUpdateMap()).eq('patient_id', patientId);
    return id;
  }

  Future<void> delete({
    required String patientId,
  }) async {
    await _supabase.from('reproductive_health').delete().eq('patient_id', patientId);
  }
}