import 'dart:convert';

import 'model_utils.dart';

class PatientRiskPredictionModel {
  final String? id;
  final String patientId;
  final String modelName;
  final String? modelVersion;
  final double riskScore; // Stored as numeric(5,4) in the DB.
  final String riskLevel; // low / medium / high.
  final List<dynamic> mainFactors; // jsonb array.
  final Map<String, dynamic> inputSnapshot; // jsonb object.
  final String? explanation;
  final DateTime? createdAt;

  const PatientRiskPredictionModel({
    this.id,
    required this.patientId,
    required this.modelName,
    this.modelVersion,
    required this.riskScore,
    required this.riskLevel,
    this.mainFactors = const [],
    this.inputSnapshot = const {},
    this.explanation,
    this.createdAt,
  });

  static List<dynamic> _asList(dynamic value) {
    if (value == null) return const [];
    if (value is List) return value;
    if (value is String && value.trim().isNotEmpty) {
      final decoded = jsonDecode(value);
      if (decoded is List) return decoded;
    }
    return const [];
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value == null) return <String, dynamic>{};
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.trim().isNotEmpty) {
      final decoded = jsonDecode(value);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    return <String, dynamic>{};
  }

  factory PatientRiskPredictionModel.fromMap(Map map) {
    return PatientRiskPredictionModel(
      id: map['id']?.toString(),
      patientId: map['patient_id']?.toString() ?? '',
      modelName: map['model_name']?.toString() ?? '',
      modelVersion: map['model_version']?.toString(),
      riskScore: asDouble(map['risk_score']) ?? 0.0,
      riskLevel: map['risk_level']?.toString() ?? 'low',
      mainFactors: _asList(map['main_factors']),
      inputSnapshot: _asMap(map['input_snapshot']),
      explanation: map['explanation']?.toString(),
      createdAt: asDateTime(map['created_at']),
    );
  }

  Map<String, dynamic> toInsertMap() => cleanMap({
    // This table is append-only in practice.
    // The service role writes predictions; the app mainly reads them.
    'patient_id': patientId,
    'model_name': modelName,
    'model_version': modelVersion,
    'risk_score': riskScore,
    'risk_level': riskLevel,
    'main_factors': mainFactors,
    'input_snapshot': inputSnapshot,
    'explanation': explanation,
  });

  Map<String, dynamic> toMap() => toInsertMap();
}
