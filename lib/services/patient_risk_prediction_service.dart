import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/patient_risk_prediction_model.dart';
import 'patient_risk_prediction_api_service.dart';

// Managing and generating patient risk predictions.
class PatientRiskPredictionService {
  // Creates a new instance of PatientRiskPredictionService
  PatientRiskPredictionService({
    SupabaseClient? supabase,
    PatientRiskPredictionApiService? apiService,
  }) : _supabase = supabase ?? Supabase.instance.client,
       _apiService = apiService ?? PatientRiskPredictionApiService();

  final SupabaseClient _supabase;
  final PatientRiskPredictionApiService _apiService;

  // Fetches all risk predictions for a specific patient.
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

  // Fetches the latest risk prediction for a specific patient.
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

  // Generates a new risk prediction for a patient and stores it in the database
  Future<PatientRiskPredictionModel> generateAndStoreForPatient(
    String patientId,
  ) async {
    final payload = await _buildPayload(patientId);
    final apiResult = await _apiService.predict(payload: payload);

    final riskLevel = apiResult['risk_level']?.toString() ?? 'low';
    final confidence = (apiResult['confidence'] as num?)?.toDouble() ?? 0.0;

    final reasons =
        (apiResult['reasons'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList() ??
        <String>[];

    final explanation = reasons.isEmpty
        ? 'Predicted $riskLevel risk.'
        : 'Predicted $riskLevel risk because ${reasons.join(", ")}.';

    final inserted = await _supabase
        .from('patient_risk_predictions')
        .insert({
          'patient_id': patientId,
          'model_name': 'Gradient Boosting',
          'model_version': 'v1',
          'risk_score': confidence,
          'risk_level': riskLevel,
          'main_factors': reasons,
          'input_snapshot': payload,
          'explanation': explanation,
        })
        .select()
        .single();

    return PatientRiskPredictionModel.fromMap(
      Map<String, dynamic>.from(inserted as Map),
    );
  }

  // Builds the data payload for the risk prediction API.
  Future<Map<String, dynamic>> _buildPayload(String patientId) async {
    final profile = await _supabase
        .from('patient_profiles')
        .select('date_of_birth, sex, blood_type, covid_vaccine_type')
        .eq('id', patientId)
        .maybeSingle();

    if (profile == null) {
      throw Exception('Patient profile not found.');
    }

    final lifestyleRows = await _supabase
        .from('lifestyle_factors')
        .select(
          'smoking, packs_per_day, smoking_years, chicha, chicha_years, drugs, alcohol_frequency, socioeconomic_class, work_status, lives_alone, has_caregiver, created_at',
        )
        .eq('patient_id', patientId)
        .order('created_at', ascending: false)
        .limit(1);

    final lifestyle = lifestyleRows.isNotEmpty
        ? Map<String, dynamic>.from(lifestyleRows.first as Map)
        : <String, dynamic>{};

    final chronicConditionsCount = await _countRows(
      'medical_conditions',
      patientId,
      'type',
      'chronic',
    );
    final acuteConditionsCount = await _countRows(
      'medical_conditions',
      patientId,
      'type',
      'acute',
    );
    final medicationsCount = await _countRows('medications', patientId);
    final allergiesCount = await _countRows('allergies', patientId);
    final surgeriesCount = await _countRows('surgeries', patientId);
    final hospitalizationsCount = await _countRows(
      'hospitalizations',
      patientId,
    );
    final vaccinationsCount = await _countRows('vaccinations', patientId);

    final dateOfBirthRaw = profile['date_of_birth']?.toString();
    final dateOfBirth = dateOfBirthRaw == null || dateOfBirthRaw.trim().isEmpty
        ? null
        : DateTime.tryParse(dateOfBirthRaw);

    final age = _calculateAge(dateOfBirth);

    final sex = _normalizeSex(profile['sex']?.toString());
    final alcoholFrequency = _normalizeAlcohol(
      lifestyle['alcohol_frequency']?.toString(),
    );
    final socioeconomicClass = _normalizeSocioeconomic(
      lifestyle['socioeconomic_class']?.toString(),
    );
    final workStatus = _normalizeWorkStatus(
      lifestyle['work_status']?.toString(),
    );

    final smoking = _asBool(lifestyle['smoking']);
    final chicha = _asBool(lifestyle['chicha']);

    final covidVaccineType = profile['covid_vaccine_type']?.toString().trim();
    final isCovidVaccinated =
        (covidVaccineType ?? '').isNotEmpty || vaccinationsCount > 0;

    return {
      'age': age ?? 0,
      'sex': sex,
      'smoking': smoking,
      'packs_per_day': smoking ? _asDouble(lifestyle['packs_per_day']) : 0.0,
      'smoking_years': smoking ? _asDouble(lifestyle['smoking_years']) : 0.0,
      'chicha': chicha,
      'chicha_years': chicha ? _asDouble(lifestyle['chicha_years']) : 0.0,
      'drugs': _asBool(lifestyle['drugs']),
      'alcohol_frequency': alcoholFrequency,
      'socioeconomic_class': socioeconomicClass,
      'work_status': workStatus,
      'lives_alone': _asBool(lifestyle['lives_alone']),
      'has_caregiver': _asBool(lifestyle['has_caregiver']),
      'chronic_conditions_count': chronicConditionsCount,
      'acute_conditions_count': acuteConditionsCount,
      'medications_count': medicationsCount,
      'allergies_count': allergiesCount,
      'surgeries_count': surgeriesCount,
      'hospitalizations_count': hospitalizationsCount,
      'is_covid_vaccinated': isCovidVaccinated,
    };
  }

  // Counts rows in a table for a specific patient, optionally filtering by a column.
  Future<int> _countRows(
    String table,
    String patientId, [
    String? filterColumn,
    Object? filterValue,
  ]) async {
    dynamic query = _supabase
        .from(table)
        .select('id')
        .eq('patient_id', patientId);

    if (filterColumn != null) {
      query = query.eq(filterColumn, filterValue);
    }

    final rows = await query;
    return (rows as List).length;
  }

  // Calculates age based on date of birth
  int? _calculateAge(DateTime? dateOfBirth) {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    var age = now.year - dateOfBirth.year;
    final hadBirthdayThisYear =
        (now.month > dateOfBirth.month) ||
        (now.month == dateOfBirth.month && now.day >= dateOfBirth.day);
    if (!hadBirthdayThisYear) {
      age -= 1;
    }
    return age < 0 ? 0 : age;
  }

  // Normalizes a value to a boolean
  bool _asBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    final text = value.toString().trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes' || text == 'y';
  }

  // Normalizes a value to a double
  double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  // Normalizes sex string to 'male' or 'female'
  String _normalizeSex(String? value) {
    final v = (value ?? '').trim().toLowerCase();
    if (v == 'male' || v == 'm') return 'male';
    if (v == 'female' || v == 'f') return 'female';
    return 'female';
  }

  // Normalizes alcohol frequency string
  String _normalizeAlcohol(String? value) {
    const allowed = {'never', 'rarely', 'monthly', 'weekly', 'daily'};
    final v = (value ?? '').trim().toLowerCase();
    return allowed.contains(v) ? v : 'never';
  }

  // Normalizes socioeconomic class string
  String _normalizeSocioeconomic(String? value) {
    const allowed = {'low', 'middle', 'high', 'unknown'};
    final v = (value ?? '').trim().toLowerCase();
    return allowed.contains(v) ? v : 'unknown';
  }

  // Normalizes work status string
  String _normalizeWorkStatus(String? value) {
    const allowed = {'employed', 'unemployed', 'retired', 'student'};
    final v = (value ?? '').trim().toLowerCase();
    return allowed.contains(v) ? v : 'employed';
  }
}
