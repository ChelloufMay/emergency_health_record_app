import 'model_utils.dart';

class AllergyModel {
  final String? id;
  final String patientId;
  final String allergenName;
  final String allergyType;
  final String? reaction;
  final String? severity;
  final String source;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AllergyModel({
    this.id,
    required this.patientId,
    required this.allergenName,
    required this.allergyType,
    this.reaction,
    this.severity,
    this.source = 'user',
    this.createdAt,
    this.updatedAt,
  });

  String? get verificationStatus => 'user_entered';

  factory AllergyModel.fromMap(Map map) {
    return AllergyModel(
      id: map['id']?.toString(),
      patientId: map['patient_id']?.toString() ?? '',
      allergenName: map['allergen_name']?.toString() ?? '',
      allergyType: map['allergy_type']?.toString() ?? 'other',
      reaction: map['reaction']?.toString(),
      severity: map['severity']?.toString(),
      source: map['source']?.toString() ?? 'user',
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }

  Map toInsertMap() => cleanMap({
    'patient_id': patientId,
    'allergen_name': allergenName,
    'allergy_type': allergyType,
    'reaction': reaction,
    'severity': severity,
    'source': source,
  });

  Map toUpdateMap() => toInsertMap();
}