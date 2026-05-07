class HospitalizationModel {
  final String id;
  final String patientId;
  final String? hospitalName;
  final DateTime? admissionDate;
  final DateTime? dischargeDate;
  final String? reason;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  HospitalizationModel({
    required this.id,
    required this.patientId,
    this.hospitalName,
    this.admissionDate,
    this.dischargeDate,
    this.reason,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  factory HospitalizationModel.fromMap(Map<String, dynamic> map) {
    return HospitalizationModel(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      hospitalName: map['hospital_name'] as String?,
      admissionDate: _parseDate(map['admission_date']),
      dischargeDate: _parseDate(map['discharge_date']),
      reason: map['reason'] as String?,
      notes: map['notes'] as String?,
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patient_id': patientId,
      'hospital_name': hospitalName,
      'admission_date': admissionDate?.toIso8601String().split('T').first,
      'discharge_date': dischargeDate?.toIso8601String().split('T').first,
      'reason': reason,
      'notes': notes,
    };
  }
}