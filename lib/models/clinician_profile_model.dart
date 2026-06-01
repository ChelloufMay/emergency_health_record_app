import 'model_utils.dart';

// Represents the profile of a clinician (doctor, nurse ...). --> maps to the 'clinician_profiles' table in the database.
class ClinicianProfileModel {
  final String? id;
  final String userId;
  final String fullName;
  final String? phone;
  final String? addressId;
  final String? specialization;
  final String? facilityName;
  final String? workPhone;
  final bool isVerified;
  final String? verificationNote;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ClinicianProfileModel({
    this.id,
    required this.userId,
    required this.fullName,
    this.phone,
    this.addressId,
    this.specialization,
    this.facilityName,
    this.workPhone,
    this.isVerified = false,
    this.verificationNote,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory ClinicianProfileModel.fromMap(Map map) {
    return ClinicianProfileModel(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      phone: map['phone']?.toString(),
      addressId: map['address_id']?.toString(),
      specialization: map['specialization']?.toString(),
      facilityName: map['facility_name']?.toString(),
      workPhone: map['work_phone']?.toString(),
      isVerified: asBool(map['is_verified']) ?? false,
      verificationNote: map['verification_note']?.toString(),
      notes: map['notes']?.toString(),
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() => cleanMap({
    'user_id': userId,
    'full_name': fullName,
    'phone': phone,
    'address_id': addressId,
    'specialization': specialization,
    'facility_name': facilityName,
    'work_phone': workPhone,
    'is_verified': isVerified,
    'verification_note': verificationNote,
    'notes': notes,
  });

  Map<String, dynamic> toUpdateMap() => cleanMap({
    'full_name': fullName,
    'phone': phone,
    'address_id': addressId,
    'specialization': specialization,
    'facility_name': facilityName,
    'work_phone': workPhone,
    'is_verified': isVerified,
    'verification_note': verificationNote,
    'notes': notes,
  });

  Map<String, dynamic> toMap() => toInsertMap();
}
