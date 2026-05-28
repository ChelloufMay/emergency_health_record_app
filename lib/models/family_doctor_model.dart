import 'model_utils.dart';

class FamilyDoctorModel {
  final String? id;
  final String fullName;
  final String? phone;
  final String? addressId; // Only the FK belongs in public.family_doctors.
  final DateTime? firstSeenDate;
  final String? notes;
  final String? createdByUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FamilyDoctorModel({
    this.id,
    required this.fullName,
    this.phone,
    this.addressId,
    this.firstSeenDate,
    this.notes,
    this.createdByUserId,
    this.createdAt,
    this.updatedAt,
  });

  static String? _dateOnly(DateTime? value) {
    if (value == null) return null;
    return value.toIso8601String().split('T').first;
  }

  factory FamilyDoctorModel.fromMap(Map map) {
    return FamilyDoctorModel(
      id: map['id']?.toString(),
      fullName: map['full_name']?.toString() ?? '',
      phone: map['phone']?.toString(),
      addressId: map['address_id']?.toString(),
      firstSeenDate: asDateTime(map['first_seen_date']),
      notes: map['notes']?.toString(),
      createdByUserId: map['created_by_user_id']?.toString(),
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() => cleanMap({
    // The model now matches public.family_doctors only.
    // Address details live in public.addresses and are linked by address_id.
    'full_name': fullName.trim(),
    'phone': phone?.trim(),
    'address_id': addressId,
    'first_seen_date': _dateOnly(firstSeenDate),
    'notes': notes,
    'created_by_user_id': createdByUserId,
  });

  Map<String, dynamic> toUpdateMap() => cleanMap({
    // Keep the row focused on the doctor record itself.
    'full_name': fullName.trim(),
    'phone': phone?.trim(),
    'address_id': addressId,
    'first_seen_date': _dateOnly(firstSeenDate),
    'notes': notes,
  });

  Map<String, dynamic> toMap() => toInsertMap();
}