import 'model_utils.dart';

class SurgeryModel {
  final String? id;
  final String patientId;
  final String surgeryName;
  final DateTime? surgeryDate;
  final String? place;
  final String? prostheticOrImplant;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SurgeryModel({
    this.id,
    required this.patientId,
    required this.surgeryName,
    this.surgeryDate,
    this.place,
    this.prostheticOrImplant,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  static String? _dateOnly(DateTime? value) {
    if (value == null) return null;
    return value.toIso8601String().split('T').first;
  }

  factory SurgeryModel.fromMap(Map map) {
    return SurgeryModel(
      id: map['id']?.toString(),
      patientId: map['patient_id']?.toString() ?? '',
      surgeryName: map['surgery_name']?.toString() ?? '',
      surgeryDate: asDateTime(map['surgery_date']),
      place: map['place']?.toString(),
      prostheticOrImplant: map['prosthetic_or_implant']?.toString(),
      notes: map['notes']?.toString(),
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() => cleanMap({
    'patient_id': patientId,
    'surgery_name': surgeryName,
    'surgery_date': _dateOnly(surgeryDate),
    'place': place,
    'prosthetic_or_implant': prostheticOrImplant,
    'notes': notes,
  });

  Map<String, dynamic> toUpdateMap() => cleanMap({
    // patient_id should not be edited on an existing surgery row.
    'surgery_name': surgeryName,
    'surgery_date': _dateOnly(surgeryDate),
    'place': place,
    'prosthetic_or_implant': prostheticOrImplant,
    'notes': notes,
  });

  Map<String, dynamic> toMap() => toInsertMap();
}