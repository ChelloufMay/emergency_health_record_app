import 'model_utils.dart';

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

  const CaregiverProfileModel({
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

  factory CaregiverProfileModel.fromMap(Map map) {
    return CaregiverProfileModel(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      relationshipToPatient: map['relationship_to_patient']?.toString(),
      phone: map['phone']?.toString(),
      addressId: map['address_id']?.toString(),
      proximity: map['proximity']?.toString(),
      attendance: map['attendance']?.toString(),
      canDrive: asBool(map['can_drive']),
      mobility: map['mobility']?.toString() ?? 'independent',
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() => cleanMap({
    'user_id': userId,
    'full_name': fullName,
    'relationship_to_patient': relationshipToPatient,
    'phone': phone,
    'address_id': addressId,
    'proximity': proximity,
    'attendance': attendance,
    'can_drive': canDrive,
    'mobility': mobility,
  });

  Map<String, dynamic> toUpdateMap() => cleanMap({
    // user_id is the ownership key and should not change.
    'full_name': fullName,
    'relationship_to_patient': relationshipToPatient,
    'phone': phone,
    'address_id': addressId,
    'proximity': proximity,
    'attendance': attendance,
    'can_drive': canDrive,
    'mobility': mobility,
  });

  Map<String, dynamic> toMap() => toInsertMap();
}