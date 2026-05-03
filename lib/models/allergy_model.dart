class AllergyModel {
  final String id;
  final String patientId;
  final String allergenName;
  final String allergyType; // food, medication, other
  final String? reaction;
  final String? severity;
  final String source; // user, caregiver, clinician
  final DateTime createdAt;
  final DateTime updatedAt;

  AllergyModel({
    required this.id,
    required this.patientId,
    required this.allergenName,
    required this.allergyType,
    this.reaction,
    this.severity,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AllergyModel.fromMap(Map<String, dynamic> map) {
    return AllergyModel(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      allergenName: map['allergen_name'] as String,
      allergyType: map['allergy_type'] as String? ?? 'other',
      reaction: map['reaction'] as String?,
      severity: map['severity'] as String?,
      source: map['source'] as String? ?? 'user',
      createdAt: DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patient_id': patientId,
      'allergen_name': allergenName,
      'allergy_type': allergyType,
      'reaction': reaction,
      'severity': severity,
      'source': source,
    };
  }
}