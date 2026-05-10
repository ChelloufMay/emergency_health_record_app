class CaregiverPermissionModel {
  // The row id comes from the database on insert so keep it nullable.
  final String? id;

  final String patientId;
  final String caregiverUserId;

  // match the DB enum values exactly: read, edit, emergency_only
  final String permission;

  //match the DB enum values exactly: active, revoked, expired
  final String status;

  final String? grantedByUserId;
  final DateTime grantedAt;
  final DateTime? expiresAt;
  final String? notes;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  CaregiverPermissionModel({
    this.id,
    required this.patientId,
    required this.caregiverUserId,
    required this.permission,
    required this.status,
    this.grantedByUserId,
    required this.grantedAt,
    this.expiresAt,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory CaregiverPermissionModel.fromMap(Map<String, dynamic> map) {
    return CaregiverPermissionModel(
      id: map['id']?.toString(),
      patientId: map['patient_id']?.toString() ?? '',
      caregiverUserId: map['caregiver_user_id']?.toString() ?? '',
      permission: map['permission']?.toString() ?? 'read',
      status: map['status']?.toString() ?? 'active',
      grantedByUserId: map['granted_by_user_id']?.toString(),
      grantedAt: map['granted_at'] != null
          ? DateTime.tryParse(map['granted_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: map['expires_at'] != null
          ? DateTime.tryParse(map['expires_at'].toString())
          : null,
      notes: map['notes']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  // Use this for INSERT. leave id / created_at / updated_at to the database defaults/triggers.
  Map<String, dynamic> toInsertMap() {
    return {
      'patient_id': patientId,
      'caregiver_user_id': caregiverUserId,
      'permission': permission,
      'status': status,
      'granted_by_user_id': grantedByUserId,
      'granted_at': grantedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'notes': notes,
    };
  }

  // Use this for UPDATE. granted_at usually should not change after creation.
  Map<String, dynamic> toUpdateMap() {
    return {
      'patient_id': patientId,
      'caregiver_user_id': caregiverUserId,
      'permission': permission,
      'status': status,
      'granted_by_user_id': grantedByUserId,
      'expires_at': expiresAt?.toIso8601String(),
      'notes': notes,
    };
  }

  // Keep a simple alias if any old code still calls toMap().
  Map<String, dynamic> toMap() => toInsertMap();
}