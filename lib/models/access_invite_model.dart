import 'model_utils.dart';

class AccessInviteModel {
  final String? id;
  final String patientId;
  final String invitedEmail;
  final String invitedRole; // DB enum: user_role, but the table accepts only caregiver/guardian/clinician.
  final String permission; // DB enum: permission_type.
  final String status; // DB enum: access_invite_status.
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

  /// Keeps the original row available for screens that still rely on raw JSON-like access.
  final Map<String, dynamic> raw;

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
    required this.raw,
  });

  factory AccessInviteModel.fromMap(Map map) {
    final raw = Map<String, dynamic>.from(map);

    return AccessInviteModel(
      id: raw['id']?.toString(),
      patientId: raw['patient_id']?.toString() ?? '',
      invitedEmail: raw['invited_email']?.toString() ?? '',
      invitedRole: raw['invited_role']?.toString() ?? 'caregiver',
      permission: raw['permission']?.toString() ?? 'read',
      status: raw['status']?.toString() ?? 'pending',
      inviteToken: raw['invite_token']?.toString(),
      invitedByUserId: raw['invited_by_user_id']?.toString(),
      acceptedByUserId: raw['accepted_by_user_id']?.toString(),
      rejectedByUserId: raw['rejected_by_user_id']?.toString(),
      invitedAt: asDateTime(raw['invited_at']),
      acceptedAt: asDateTime(raw['accepted_at']),
      rejectedAt: asDateTime(raw['rejected_at']),
      expiresAt: asDateTime(raw['expires_at']),
      notes: raw['notes']?.toString(),
      createdAt: asDateTime(raw['created_at']),
      updatedAt: asDateTime(raw['updated_at']),
      raw: raw,
    );
  }

  Map<String, dynamic> toInsertMap() => cleanMap({
    // This payload is intentionally minimal.
    // Database defaults and the create_access_invite() RPC handle:
    // - invite_token
    // - invited_at
    // - invited_by_user_id
    // - accepted/rejected columns
    'patient_id': patientId,
    'invited_email': invitedEmail.trim().toLowerCase(),
    'invited_role': invitedRole,
    'permission': permission,
    'expires_at': expiresAt?.toIso8601String(),
    'notes': notes,
  });

  Map<String, dynamic> toUpdateMap() => cleanMap({
    // Only mutable invite lifecycle fields should be updated.
    // Identity fields stay fixed after creation.
    'permission': permission,
    'status': status,
    'accepted_by_user_id': acceptedByUserId,
    'accepted_at': acceptedAt?.toIso8601String(),
    'rejected_by_user_id': rejectedByUserId,
    'rejected_at': rejectedAt?.toIso8601String(),
    'expires_at': expiresAt?.toIso8601String(),
    'notes': notes,
  });

  Map<String, dynamic> toMap() => toInsertMap();
}