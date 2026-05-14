import 'model_utils.dart';

class MedicalConditionModel {
  final String? id;
  final String patientId;
  final String conditionName;
  final String type;
  final DateTime? diagnosisDate;
  final String? diagnosisPlace;
  final String? followUpDoctor;
  final String? treatment;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MedicalConditionModel({
    this.id,
    required this.patientId,
    required this.conditionName,
    required this.type,
    this.diagnosisDate,
    this.diagnosisPlace,
    this.followUpDoctor,
    this.treatment,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory MedicalConditionModel.fromMap(Map map) {
    return MedicalConditionModel(
      id: map['id']?.toString(),
      patientId: map['patient_id']?.toString() ?? '',
      conditionName: map['condition_name']?.toString() ?? '',
      type: map['type']?.toString() ?? 'chronic',
      diagnosisDate: asDateTime(map['diagnosis_date']),
      diagnosisPlace: map['diagnosis_place']?.toString(),
      followUpDoctor: map['follow_up_doctor']?.toString(),
      treatment: map['treatment']?.toString(),
      notes: map['notes']?.toString(),
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() => cleanMap({
    'patient_id': patientId,
    'condition_name': conditionName,
    'type': type,
    'diagnosis_date': diagnosisDate?.toIso8601String().split('T').first,
    'diagnosis_place': diagnosisPlace,
    'follow_up_doctor': followUpDoctor,
    'treatment': treatment,
    'notes': notes,
  });

  Map<String, dynamic> toUpdateMap() => toInsertMap();
}