import 'model_utils.dart';

// An invitation sent to a user to grant them access to a patient's record. --> maps to the 'access_invites' table in the database.
class AccessInviteModel {
  final String? id;
  final String patientId;
  final String invitedEmail;
  final String invitedRole;
  final String permission;
  final String status;

  // A token used to validate the invitation when the recipient accepts it.
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

  // Keeps the original row available for screens that rely on raw JSON like access.
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

  // Create an AccessInviteModel instance from a Map.
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

  // Convert the AccessInviteModel to a Map suitable for inserting a new record.
  Map<String, dynamic> toInsertMap() => cleanMap({
    // This payload is intentionally minimal.
    // Database defaults and the create_access_invite() RPC handle
    'invited_email': invitedEmail.trim().toLowerCase(),
    'invited_role': invitedRole,
    'permission': permission,
    'expires_at': expiresAt?.toIso8601String(),
    'notes': notes,
  });

  // Converts the [AccessInviteModel] to a Map suitable for updating an existing record.
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

  // Converts the [AccessInviteModel] to a Map. Defaults to insertion format.
  Map<String, dynamic> toMap() => toInsertMap();
}
