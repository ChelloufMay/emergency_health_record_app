import 'model_utils.dart';

class VaccinationModel {
  final String? id;
  final String patientId;
  final String vaccineName;
  final String category;
  final int? doseNumber;
  final DateTime? dateAdministered;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VaccinationModel({
    this.id,
    required this.patientId,
    required this.vaccineName,
    required this.category,
    this.doseNumber,
    this.dateAdministered,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory VaccinationModel.fromMap(Map map) {
    return VaccinationModel(
      id: map['id']?.toString(),
      patientId: map['patient_id']?.toString() ?? '',
      vaccineName: map['vaccine_name']?.toString() ?? '',
      category: map['category']?.toString() ?? 'other',
      doseNumber: asInt(map['dose_number']),
      dateAdministered: asDateTime(map['date_administered']),
      notes: map['notes']?.toString(),
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() => cleanMap({
    'patient_id': patientId,
    'vaccine_name': vaccineName,
    'category': category,
    'dose_number': doseNumber,
    'date_administered': dateAdministered?.toIso8601String().split('T').first,
    'notes': notes,
  });

  Map<String, dynamic> toUpdateMap() => toInsertMap();
}