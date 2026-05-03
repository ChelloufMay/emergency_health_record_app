class CaregiverProfileModel {
  final String? id;
  final String userId;
  final String fullName;
  final String? relationshipToPatient;
  final String? phone;
  final String? addressId;
  final String? proximity;
  final String? attendance;
  final bool? canDrive;
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
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      fullName: map['full_name'] as String,
      relationshipToPatient: map['relationship_to_patient'] as String?,
      phone: map['phone'] as String?,
      addressId: map['address_id'] as String?,
      proximity: map['proximity'] as String?,
      attendance: map['attendance'] as String?,
      canDrive: map['can_drive'] as bool?,
      mobility: map['mobility'] as String? ?? 'independent',
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
}