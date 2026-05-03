class FamilyDoctorModel {
  final String? id;
  final String fullName;
  final String? phone;
  final String? addressId;
  final String? medicalLicenseNumber;
  final DateTime? firstSeenDate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FamilyDoctorModel({
    this.id,
    required this.fullName,
    this.phone,
    this.addressId,
    this.medicalLicenseNumber,
    this.firstSeenDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory FamilyDoctorModel.fromMap(Map<String, dynamic> map) {
    return FamilyDoctorModel(
      id: map['id'] as String?,
      fullName: map['full_name'] as String,
      phone: map['phone'] as String?,
      addressId: map['address_id'] as String?,
      medicalLicenseNumber: map['medical_license_number'] as String?,
      firstSeenDate: map['first_seen_date'] != null
          ? DateTime.tryParse(map['first_seen_date'].toString())
          : null,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'full_name': fullName,
      'phone': phone,
      'address_id': addressId,
      'medical_license_number': medicalLicenseNumber,
      'first_seen_date': firstSeenDate?.toIso8601String().split('T').first,
      'notes': notes,
    };
  }
}