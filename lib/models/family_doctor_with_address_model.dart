import 'model_utils.dart';

class FamilyDoctorWithAddressModel {
  final String? id;
  final String fullName;
  final String? phone;
  final String? addressId;

  // These come from the joined public.addresses row.
  // This is a view/composite model only, not a table-backed model.
  final String? country;
  final String? governorate;
  final String? city;
  final String? avenue;
  final String? street;
  final String? postalCode;
  final String? extraDetails;

  final String? medicalLicenseNumber;
  final DateTime? firstSeenDate;
  final String? notes;
  final String? createdByUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FamilyDoctorWithAddressModel({
    this.id,
    required this.fullName,
    this.phone,
    this.addressId,
    this.country,
    this.governorate,
    this.city,
    this.avenue,
    this.street,
    this.postalCode,
    this.extraDetails,
    this.medicalLicenseNumber,
    this.firstSeenDate,
    this.notes,
    this.createdByUserId,
    this.createdAt,
    this.updatedAt,
  });

  factory FamilyDoctorWithAddressModel.fromMap(Map map) {
    return FamilyDoctorWithAddressModel(
      id: map['id']?.toString(),
      fullName: map['full_name']?.toString() ?? '',
      phone: map['phone']?.toString(),
      addressId: map['address_id']?.toString(),
      country: map['country']?.toString(),
      governorate: map['governorate']?.toString(),
      city: map['city']?.toString(),
      avenue: map['avenue']?.toString(),
      street: map['street']?.toString(),
      postalCode: map['postal_code']?.toString(),
      extraDetails: map['extra_details']?.toString(),
      medicalLicenseNumber: map['medical_license_number']?.toString(),
      firstSeenDate: asDateTime(map['first_seen_date']),
      notes: map['notes']?.toString(),
      createdByUserId: map['created_by_user_id']?.toString(),
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }
}