import 'model_utils.dart';

class MedicationModel {
  final String? id;
  final String patientId;
  final String medicationName;
  final String? dosage;
  final String? frequency;
  final String? purpose;
  final DateTime? startDate;
  final DateTime? endDate;
  final String source;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MedicationModel({
    this.id,
    required this.patientId,
    required this.medicationName,
    this.dosage,
    this.frequency,
    this.purpose,
    this.startDate,
    this.endDate,
    this.source = 'user',
    this.createdAt,
    this.updatedAt,
  });

  String? get verificationStatus => 'user_entered';

  factory MedicationModel.fromMap(Map map) {
    return MedicationModel(
      id: map['id']?.toString(),
      patientId: map['patient_id']?.toString() ?? '',
      medicationName: map['medication_name']?.toString() ?? '',
      dosage: map['dosage']?.toString(),
      frequency: map['frequency']?.toString(),
      purpose: map['purpose']?.toString(),
      startDate: asDateTime(map['start_date']),
      endDate: asDateTime(map['end_date']),
      source: map['source']?.toString() ?? 'user',
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }

  Map toInsertMap() => cleanMap({
    'patient_id': patientId,
    'medication_name': medicationName,
    'dosage': dosage,
    'frequency': frequency,
    'purpose': purpose,
    'start_date': startDate?.toIso8601String().split('T').first,
    'end_date': endDate?.toIso8601String().split('T').first,
    'source': source,
  });

  Map toUpdateMap() => toInsertMap();
}