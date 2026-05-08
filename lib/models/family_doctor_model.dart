class FamilyDoctorModel {
  final String? id;
  final String fullName;
  final String? phone;

  final String? addressId;

  // Address fields come from the separate addresses table.
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FamilyDoctorModel({
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
    this.createdAt,
    this.updatedAt,
  });

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static String? _clean(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  factory FamilyDoctorModel.fromMap(Map<String, dynamic> map) {
    return FamilyDoctorModel(
      id: map['id'] as String?,
      fullName: map['full_name'] as String,
      phone: _clean(map['phone']),
      addressId: map['address_id'] as String?,
      country: _clean(map['country']),
      governorate: _clean(map['governorate']),
      city: _clean(map['city']),
      avenue: _clean(map['avenue']),
      street: _clean(map['street']),
      postalCode: _clean(map['postal_code']),
      extraDetails: _clean(map['extra_details']),
      medicalLicenseNumber: _clean(map['medical_license_number']),
      firstSeenDate: map['first_seen_date'] != null
          ? DateTime.tryParse(map['first_seen_date'].toString())
          : null,
      notes: _clean(map['notes']),
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
    );
  }

  /// For public.family_doctors
  Map<String, dynamic> toDoctorMap({String? addressIdOverride}) {
    return {
      'full_name': fullName,
      'phone': phone,
      'address_id': addressIdOverride ?? addressId,
      'medical_license_number': medicalLicenseNumber,
      'first_seen_date': firstSeenDate?.toIso8601String().split('T').first,
      'notes': notes,
    };
  }

  /// For public.addresses
  Map<String, dynamic> toAddressMap() {
    return {
      'country': country?.trim(),
      'governorate': governorate?.trim(),
      'city': city?.trim(),
      'avenue': avenue?.trim(),
      'street': street?.trim(),
      'postal_code': postalCode?.trim(),
      'extra_details': extraDetails?.trim(),
    };
  }
}