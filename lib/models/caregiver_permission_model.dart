import 'model_utils.dart';

class CaregiverPermissionModel {
  final String? id;
  final String patientId;
  final String caregiverUserId;
  final String permission; // read, edit, emergency_only
  final String status; // active, revoked, expired
  final String? grantedByUserId;
  final DateTime? grantedAt;
  final DateTime? expiresAt;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CaregiverPermissionModel({
    this.id,
    required this.patientId,
    required this.caregiverUserId,
    required this.permission,
    required this.status,
    this.grantedByUserId,
    this.grantedAt,
    this.expiresAt,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory CaregiverPermissionModel.fromMap(Map map) {
    return CaregiverPermissionModel(
      id: map['id']?.toString(),
      patientId: map['patient_id']?.toString() ?? '',
      caregiverUserId: map['caregiver_user_id']?.toString() ?? '',
      permission: map['permission']?.toString() ?? 'read',
      status: map['status']?.toString() ?? 'active',
      grantedByUserId: map['granted_by_user_id']?.toString(),
      grantedAt: asDateTime(map['granted_at']),
      expiresAt: asDateTime(map['expires_at']),
      notes: map['notes']?.toString(),
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() => cleanMap({
    // Mirrors public.caregiver_permissions.
    'patient_id': patientId,
    'caregiver_user_id': caregiverUserId,
    'permission': permission,
    'status': status,
    'granted_by_user_id': grantedByUserId,
    'granted_at': grantedAt?.toIso8601String(),
    'expires_at': expiresAt?.toIso8601String(),
    'notes': notes,
  });

  Map<String, dynamic> toUpdateMap() => cleanMap({
    // Only lifecycle fields are mutable.
    'permission': permission,
    'status': status,
    'granted_by_user_id': grantedByUserId,
    'granted_at': grantedAt?.toIso8601String(),
    'expires_at': expiresAt?.toIso8601String(),
    'notes': notes,
  });

  Map<String, dynamic> toMap() => toInsertMap();
}