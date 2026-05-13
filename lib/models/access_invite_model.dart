class AccessInviteModel {
  final String id;
  final String patientId;
  final String invitedEmail;
  final String invitedRole;
  final String permission;
  final String status;
  final String inviteToken;
  final String? invitedByUserId;
  final String? acceptedByUserId;
  final DateTime? invitedAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? expiresAt;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AccessInviteModel({
    required this.id,
    required this.patientId,
    required this.invitedEmail,
    required this.invitedRole,
    required this.permission,
    required this.status,
    required this.inviteToken,
    this.invitedByUserId,
    this.acceptedByUserId,
    this.invitedAt,
    this.acceptedAt,
    this.rejectedAt,
    this.expiresAt,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory AccessInviteModel.fromJson(Map<String, dynamic> json) {
    return AccessInviteModel(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      invitedEmail: json['invited_email']?.toString() ?? '',
      invitedRole: json['invited_role']?.toString() ?? 'caregiver',
      permission: json['permission']?.toString() ?? 'read',
      status: json['status']?.toString() ?? 'pending',
      inviteToken: json['invite_token']?.toString() ?? '',
      invitedByUserId: json['invited_by_user_id']?.toString(),
      acceptedByUserId: json['accepted_by_user_id']?.toString(),
      invitedAt: DateTime.tryParse(json['invited_at']?.toString() ?? ''),
      acceptedAt: DateTime.tryParse(json['accepted_at']?.toString() ?? ''),
      rejectedAt: DateTime.tryParse(json['rejected_at']?.toString() ?? ''),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
      notes: json['notes']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }
}