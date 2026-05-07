class MedicationModel {
  final String id;
  final String patientId;
  final String medicationName;
  final String? dosage;
  final String? frequency;
  final String? purpose;
  final DateTime? startDate;
  final DateTime? endDate;
  final String source; // user, caregiver, clinician
  final DateTime createdAt;
  final DateTime updatedAt;

  // used only in the UI
  String? verificationStatus;

  MedicationModel({
    required this.id,
    required this.patientId,
    required this.medicationName,
    this.dosage,
    this.frequency,
    this.purpose,
    this.startDate,
    this.endDate,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.verificationStatus,
  });

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  factory MedicationModel.fromMap(Map<String, dynamic> map) {
    return MedicationModel(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      medicationName: map['medication_name'] as String,
      dosage: map['dosage'] as String?,
      frequency: map['frequency'] as String?,
      purpose: map['purpose'] as String?,
      startDate: _parseDate(map['start_date']),
      endDate: _parseDate(map['end_date']),
      source: map['source'] as String? ?? 'user',
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patient_id': patientId,
      'medication_name': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'purpose': purpose,
      'start_date': startDate?.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'source': source,
    };
  }
}