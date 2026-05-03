class FamilyDoctorModel {
  final String? id;
  final String fullName;
  final String? phone;
  final String? medicalLicenseNumber;
  final DateTime? firstSeenDate;
  final String? notes;

  FamilyDoctorModel({
    this.id,
    required this.fullName,
    this.phone,
    this.medicalLicenseNumber,
    this.firstSeenDate,
    this.notes,
  });

  factory FamilyDoctorModel.fromMap(Map<String, dynamic> map) {
    return FamilyDoctorModel(
      id: map['id'] as String?,
      fullName: map['full_name'] as String,
      phone: map['phone'] as String?,
      medicalLicenseNumber: map['medical_license_number'] as String?,
      firstSeenDate: map['first_seen_date'] != null
          ? DateTime.tryParse(map['first_seen_date'].toString())
          : null,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'full_name': fullName,
      'phone': phone,
      'medical_license_number': medicalLicenseNumber,
      'first_seen_date': firstSeenDate?.toIso8601String().split('T').first,
      'notes': notes,
    };
  }
}