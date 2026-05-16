import 'model_utils.dart';

class AddressModel {
  final String? id;
  final String country;
  final String? governorate;
  final String? city;
  final String? avenue;
  final String? street;
  final String? postalCode;
  final String? extraDetails;
  final String? createdByUserId; // Matches public.addresses.created_by_user_id.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AddressModel({
    this.id,
    required this.country,
    this.governorate,
    this.city,
    this.avenue,
    this.street,
    this.postalCode,
    this.extraDetails,
    this.createdByUserId,
    this.createdAt,
    this.updatedAt,
  });

  factory AddressModel.fromMap(Map map) {
    return AddressModel(
      id: map['id']?.toString(),
      country: map['country']?.toString() ?? '',
      governorate: map['governorate']?.toString(),
      city: map['city']?.toString(),
      avenue: map['avenue']?.toString(),
      street: map['street']?.toString(),
      postalCode: map['postal_code']?.toString(),
      extraDetails: map['extra_details']?.toString(),
      createdByUserId: map['created_by_user_id']?.toString(),
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() => cleanMap({
    // created_by_user_id is DB-managed by default(current_app_user_id()).
    // Keeping it optional here allows service-side inserts when needed.
    'country': country,
    'governorate': governorate,
    'city': city,
    'avenue': avenue,
    'street': street,
    'postal_code': postalCode,
    'extra_details': extraDetails,
    'created_by_user_id': createdByUserId,
  });

  Map<String, dynamic> toUpdateMap() => cleanMap({
    // The creator owns the row, so creator identity should not change.
    'country': country,
    'governorate': governorate,
    'city': city,
    'avenue': avenue,
    'street': street,
    'postal_code': postalCode,
    'extra_details': extraDetails,
  });

  Map<String, dynamic> toMap() => toInsertMap();
}