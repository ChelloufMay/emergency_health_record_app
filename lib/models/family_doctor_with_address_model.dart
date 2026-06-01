import 'model_utils.dart';

// A composite model that represents a family doctor along with their full address details.
// Used for UI display because doctor information and address information are joined in a single view or query.
class FamilyDoctorWithAddressModel {
  final String? id;
  final String fullName;
  final String? phone;
  final String? addressId;

  // These fields come from the joined 'addresses' table record.
  final String? country;
  final String? governorate;
  final String? city;
  final String? avenue;
  final String? street;
  final String? postalCode;
  final String? extraDetails;

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
      firstSeenDate: asDateTime(map['first_seen_date']),
      notes: map['notes']?.toString(),
      createdByUserId: map['created_by_user_id']?.toString(),
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }
}
