class ClinicianProfileModel {
  final String id;
  final String userId;
  final String fullName;
  final String? phone;
  final String? addressId;
  final String? licenseNumber;
  final String? specialization;
  final String? facilityName;
  final String? workPhone;
  final bool isVerified;
  final String? verificationNote;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ClinicianProfileModel({
    required this.id,
    required this.userId,
    required this.fullName,
    this.phone,
    this.addressId,
    this.licenseNumber,
    this.specialization,
    this.facilityName,
    this.workPhone,
    required this.isVerified,
    this.verificationNote,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory ClinicianProfileModel.fromJson(Map<String, dynamic> json) {
    return ClinicianProfileModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      addressId: json['address_id']?.toString(),
      licenseNumber: json['license_number']?.toString(),
      specialization: json['specialization']?.toString(),
      facilityName: json['facility_name']?.toString(),
      workPhone: json['work_phone']?.toString(),
      isVerified: json['is_verified'] == true,
      verificationNote: json['verification_note']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }
}