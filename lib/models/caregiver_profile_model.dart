class CaregiverProfileModel {
  final String? id;
  final String userId;
  final String fullName;
  final String? relationshipToPatient;
  final String? phone;

  // Links the caregiver profile to public.addresses.
  // This is the field your caregiver profile form should bind to
  // when you want to save an address for the caregiver.
  final String? addressId;

  // DB enum values: cohabitant, near, far
  final String? proximity;

  // DB enum values:
  // daily, doctor_visits_only, phone_checkups, long_periods_between_visits
  final String? attendance;

  final bool? canDrive;

  // DB enum values: independent, cane, wheelchair, needs_help
  final String mobility;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  CaregiverProfileModel({
    this.id,
    required this.userId,
    required this.fullName,
    this.relationshipToPatient,
    this.phone,
    this.addressId,
    this.proximity,
    this.attendance,
    this.canDrive,
    this.mobility = 'independent',
    this.createdAt,
    this.updatedAt,
  });

  factory CaregiverProfileModel.fromMap(Map<String, dynamic> map) {
    return CaregiverProfileModel(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      relationshipToPatient: map['relationship_to_patient']?.toString(),
      phone: map['phone']?.toString(),
      addressId: map['address_id']?.toString(),
      proximity: map['proximity']?.toString(),
      attendance: map['attendance']?.toString(),
      canDrive: map['can_drive'] as bool?,
      mobility: map['mobility']?.toString() ?? 'independent',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  // Insert payload for public.caregiver_profiles.
  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'relationship_to_patient': relationshipToPatient,
      'phone': phone,
      'address_id': addressId,
      'proximity': proximity,
      'attendance': attendance,
      'can_drive': canDrive,
      'mobility': mobility,
    };
  }

  // Update payload for public.caregiver_profiles.
  Map<String, dynamic> toUpdateMap() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'relationship_to_patient': relationshipToPatient,
      'phone': phone,
      'address_id': addressId,
      'proximity': proximity,
      'attendance': attendance,
      'can_drive': canDrive,
      'mobility': mobility,
    };
  }

  // Backward-compatible alias.
  Map<String, dynamic> toMap() => toInsertMap();
}