class HospitalizationModel {
  final String id;
  final String patientId;
  final String? hospitalName;
  final DateTime? admissionDate;
  final DateTime? dischargeDate;
  final String? reason;
  final String? notes;
  final DateTime createdAt;

  HospitalizationModel({
    required this.id,
    required this.patientId,
    this.hospitalName,
    this.admissionDate,
    this.dischargeDate,
    this.reason,
    this.notes,
    required this.createdAt,
  });

  factory HospitalizationModel.fromMap(Map<String, dynamic> map) {
    return HospitalizationModel(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      hospitalName: map['hospital_name'] as String?,
      admissionDate: map['admission_date'] != null
          ? DateTime.tryParse(map['admission_date'].toString())
          : null,
      dischargeDate: map['discharge_date'] != null
          ? DateTime.tryParse(map['discharge_date'].toString())
          : null,
      reason: map['reason'] as String?,
      notes: map['notes'] as String?,
      createdAt:
      DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now(),
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