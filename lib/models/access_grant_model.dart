import 'model_utils.dart';

class AccessGrantModel {
  final String? id;
  final String patientId;
  final String granteeUserId;
  final String granteeRole;
  final String permission;
  final String status;
  final String? grantedByUserId;
  final DateTime? grantedAt;
  final DateTime? expiresAt;
  final String? sourceInviteId;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AccessGrantModel({
    this.id,
    required this.patientId,
    required this.granteeUserId,
    required this.granteeRole,
    required this.permission,
    required this.status,
    this.grantedByUserId,
    this.grantedAt,
    this.expiresAt,
    this.sourceInviteId,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory AccessGrantModel.fromMap(Map map) {
    return AccessGrantModel(
      id: map['id']?.toString(),
      patientId: map['patient_id']?.toString() ?? '',
      granteeUserId: map['grantee_user_id']?.toString() ?? '',
      granteeRole: map['grantee_role']?.toString() ?? 'caregiver',
      permission: map['permission']?.toString() ?? 'read',
      status: map['status']?.toString() ?? 'active',
      grantedByUserId: map['granted_by_user_id']?.toString(),
      grantedAt: asDateTime(map['granted_at']),
      expiresAt: asDateTime(map['expires_at']),
      sourceInviteId: map['source_invite_id']?.toString(),
      notes: map['notes']?.toString(),
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() => cleanMap({
    'patient_id': patientId,
    'grantee_user_id': granteeUserId,
    'grantee_role': granteeRole,
    'permission': permission,
    'status': status,
    'granted_by_user_id': grantedByUserId,
    'granted_at': grantedAt?.toIso8601String(),
    'expires_at': expiresAt?.toIso8601String(),
    'source_invite_id': sourceInviteId,
    'notes': notes,
  });

  Map<String, dynamic> toUpdateMap() => cleanMap({
    'patient_id': patientId,
    'grantee_user_id': granteeUserId,
    'grantee_role': granteeRole,
    'permission': permission,
    'status': status,
    'granted_by_user_id': grantedByUserId,
    'expires_at': expiresAt?.toIso8601String(),
    'source_invite_id': sourceInviteId,
    'notes': notes,
  });

  Map<String, dynamic> toMap() => toInsertMap();
}