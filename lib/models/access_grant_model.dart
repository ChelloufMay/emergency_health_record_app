class AccessGrantModel {
  final String id;
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
    required this.id,
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

  factory AccessGrantModel.fromJson(Map<String, dynamic> json) {
    return AccessGrantModel(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      granteeUserId: json['grantee_user_id']?.toString() ?? '',
      granteeRole: json['grantee_role']?.toString() ?? '',
      permission: json['permission']?.toString() ?? 'read',
      status: json['status']?.toString() ?? 'active',
      grantedByUserId: json['granted_by_user_id']?.toString(),
      grantedAt: DateTime.tryParse(json['granted_at']?.toString() ?? ''),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
      sourceInviteId: json['source_invite_id']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }
}