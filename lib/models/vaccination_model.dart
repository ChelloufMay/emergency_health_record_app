import 'model_utils.dart';

// Represents a vaccination record for a patient. --> maps to the 'vaccinations' table in the database.
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

  // Formats a DateTime to a YYYY-MM-DD.
  static String? _dateOnly(DateTime? value) {
    if (value == null) return null;
    return value.toIso8601String().split('T').first;
  }

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
    'date_administered': _dateOnly(dateAdministered),
    'notes': notes,
  });

  Map<String, dynamic> toUpdateMap() => cleanMap({
    // patient_id remains fixed for the vaccination row.
    'vaccine_name': vaccineName,
    'category': category,
    'dose_number': doseNumber,
    'date_administered': _dateOnly(dateAdministered),
    'notes': notes,
  });

  Map<String, dynamic> toMap() => toInsertMap();
}
