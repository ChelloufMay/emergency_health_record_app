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

  AddressModel({
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

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      id: map['id'] as String?,
      country: map['country'] as String,
      governorate: map['governorate'] as String?,
      city: map['city'] as String?,
      avenue: map['avenue'] as String?,
      street: map['street'] as String?,
      postalCode: map['postal_code'] as String?,
      extraDetails: map['extra_details'] as String?,
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
      'country': country,
      'governorate': governorate,
      'city': city,
      'avenue': avenue,
      'street': street,
      'postal_code': postalCode,
      'extra_details': extraDetails,
    };
  }
}