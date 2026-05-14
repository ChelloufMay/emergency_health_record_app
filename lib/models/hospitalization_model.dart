import 'model_utils.dart';

class HospitalizationModel {
  final String? id;
  final String patientId;
  final String? hospitalName;
  final DateTime? admissionDate;
  final DateTime? dischargeDate;
  final String? reason;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HospitalizationModel({
    this.id,
    required this.patientId,
    this.hospitalName,
    this.admissionDate,
    this.dischargeDate,
    this.reason,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory HospitalizationModel.fromMap(Map map) {
    return HospitalizationModel(
      id: map['id']?.toString(),
      patientId: map['patient_id']?.toString() ?? '',
      hospitalName: map['hospital_name']?.toString(),
      admissionDate: asDateTime(map['admission_date']),
      dischargeDate: asDateTime(map['discharge_date']),
      reason: map['reason']?.toString(),
      notes: map['notes']?.toString(),
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() => cleanMap({
    'patient_id': patientId,
    'hospital_name': hospitalName,
    'admission_date': admissionDate?.toIso8601String().split('T').first,
    'discharge_date': dischargeDate?.toIso8601String().split('T').first,
    'reason': reason,
    'notes': notes,
  });

  Map<String, dynamic> toUpdateMap() => toInsertMap();
}