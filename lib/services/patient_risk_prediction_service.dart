import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/patient_risk_prediction_model.dart';

class PatientRiskPredictionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<PatientRiskPredictionModel>> fetchByPatient(
    String patientId,
  ) async {
    final rows = await _supabase
        .from('patient_risk_predictions')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map(
          (row) => PatientRiskPredictionModel.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<PatientRiskPredictionModel?> fetchLatest(String patientId) async {
    final rows = await _supabase
        .from('patient_risk_predictions')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;
    return PatientRiskPredictionModel.fromMap(
      Map<String, dynamic>.from(rows.first as Map),
    );
  }
}
