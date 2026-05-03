class CaregiverPermissionModel {
  final String id;
  final String patientId;
  final String caregiverUserId;
  final String permission; // read, edit, emergency_only
  final String status; // active, revoked, expired
  final String? grantedByUserId;
  final DateTime grantedAt;
  final DateTime? expiresAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  CaregiverPermissionModel({
    required this.id,
    required this.patientId,
    required this.caregiverUserId,
    required this.permission,
    required this.status,
    this.grantedByUserId,
    required this.grantedAt,
    this.expiresAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CaregiverPermissionModel.fromMap(Map<String, dynamic> map) {
    return CaregiverPermissionModel(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      caregiverUserId: map['caregiver_user_id'] as String,
      permission: map['permission'] as String,
      status: map['status'] as String? ?? 'active',
      grantedByUserId: map['granted_by_user_id'] as String?,
      grantedAt: DateTime.tryParse(map['granted_at'].toString()) ?? DateTime.now(),
      expiresAt: map['expires_at'] != null
          ? DateTime.tryParse(map['expires_at'].toString())
          : null,
      notes: map['notes'] as String?,
      createdAt: DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
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
}