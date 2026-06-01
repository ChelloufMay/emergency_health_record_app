import 'model_utils.dart';

// Represents a physical address within the system. --> maps to the 'addresses' table in the database.
class AddressModel {
  final String? id;
  final String country;
  final String? governorate;
  final String? city;
  final String? avenue;
  final String? street;
  final String? postalCode;
  final String? extraDetails;
  final String? createdByUserId;
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

  // Create an AddressModel instance from a Map.
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

  // Convert the AddressModel to a Map suitable for inserting a new record.
  Map<String, dynamic> toInsertMap() => cleanMap({
    'country': country,
    'governorate': governorate,
    'city': city,
    'avenue': avenue,
    'street': street,
    'postal_code': postalCode,
    'extra_details': extraDetails,
    'created_by_user_id': createdByUserId,
  });

  // Convert the AddressModel to a Map suitable for updating an existing record.
  Map<String, dynamic> toUpdateMap() => cleanMap({
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
