class MedicalConditionModel {
  final String id;
  final String patientId;
  final String conditionName;
  final String type; // chronic, acute
  final DateTime? diagnosisDate;
  final String? diagnosisPlace;
  final String? followUpDoctor;
  final String? treatment;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // used only in the UI
  String? verificationStatus;

  MedicalConditionModel({
    required this.id,
    required this.patientId,
    required this.conditionName,
    required this.type,
    this.diagnosisDate,
    this.diagnosisPlace,
    this.followUpDoctor,
    this.treatment,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.verificationStatus,
  });

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  factory MedicalConditionModel.fromMap(Map<String, dynamic> map) {
    return MedicalConditionModel(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      conditionName: map['condition_name'] as String,
      type: map['type'] as String? ?? 'chronic',
      diagnosisDate: _parseDate(map['diagnosis_date']),
      diagnosisPlace: map['diagnosis_place'] as String?,
      followUpDoctor: map['follow_up_doctor'] as String?,
      treatment: map['treatment'] as String?,
      notes: map['notes'] as String?,
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patient_id': patientId,
      'condition_name': conditionName,
      'type': type,
      'diagnosis_date': diagnosisDate?.toIso8601String().split('T').first,
      'diagnosis_place': diagnosisPlace,
      'follow_up_doctor': followUpDoctor,
      'treatment': treatment,
      'notes': notes,
    };
  }
}