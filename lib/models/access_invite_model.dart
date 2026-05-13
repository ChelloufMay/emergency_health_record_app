import 'model_utils.dart';

class AccessInviteModel {
  final String? id;
  final String patientId;
  final String invitedEmail;
  final String invitedRole;
  final String permission;
  final String status;
  final String? inviteToken;
  final String? invitedByUserId;
  final String? acceptedByUserId;
  final String? rejectedByUserId;
  final DateTime? invitedAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? expiresAt;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AccessInviteModel({
    this.id,
    required this.patientId,
    required this.invitedEmail,
    required this.invitedRole,
    required this.permission,
    required this.status,
    this.inviteToken,
    this.invitedByUserId,
    this.acceptedByUserId,
    this.rejectedByUserId,
    this.invitedAt,
    this.acceptedAt,
    this.rejectedAt,
    this.expiresAt,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory AccessInviteModel.fromMap(Map map) {
    return AccessInviteModel(
      id: map['id']?.toString(),
      patientId: map['patient_id']?.toString() ?? '',
      invitedEmail: map['invited_email']?.toString() ?? '',
      invitedRole: map['invited_role']?.toString() ?? 'caregiver',
      permission: map['permission']?.toString() ?? 'read',
      status: map['status']?.toString() ?? 'pending',
      inviteToken: map['invite_token']?.toString(),
      invitedByUserId: map['invited_by_user_id']?.toString(),
      acceptedByUserId: map['accepted_by_user_id']?.toString(),
      rejectedByUserId: map['rejected_by_user_id']?.toString(),
      invitedAt: asDateTime(map['invited_at']),
      acceptedAt: asDateTime(map['accepted_at']),
      rejectedAt: asDateTime(map['rejected_at']),
      expiresAt: asDateTime(map['expires_at']),
      notes: map['notes']?.toString(),
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() => cleanMap({
    'patient_id': patientId,
    'invited_email': invitedEmail,
    'invited_role': invitedRole,
    'permission': permission,
    'status': status,
    'invite_token': inviteToken,
    'invited_by_user_id': invitedByUserId,
    'accepted_by_user_id': acceptedByUserId,
    'rejected_by_user_id': rejectedByUserId,
    'invited_at': invitedAt?.toIso8601String(),
    'accepted_at': acceptedAt?.toIso8601String(),
    'rejected_at': rejectedAt?.toIso8601String(),
    'expires_at': expiresAt?.toIso8601String(),
    'notes': notes,
  });

  Map<String, dynamic> toUpdateMap() => cleanMap({
    'patient_id': patientId,
    'invited_email': invitedEmail,
    'invited_role': invitedRole,
    'permission': permission,
    'status': status,
    'invited_by_user_id': invitedByUserId,
    'accepted_by_user_id': acceptedByUserId,
    'rejected_by_user_id': rejectedByUserId,
    'expires_at': expiresAt?.toIso8601String(),
    'notes': notes,
  });

  Map<String, dynamic> toMap() => toInsertMap();
}