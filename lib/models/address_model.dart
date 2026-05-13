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
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() => cleanMap({
    'country': country,
    'governorate': governorate,
    'city': city,
    'avenue': avenue,
    'street': street,
    'postal_code': postalCode,
    'extra_details': extraDetails,
  });
}