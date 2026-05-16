import 'model_utils.dart';

class EmergencyAccessTokenModel {
  final String? id;
  final String patientId;
  final String? token; // DB can generate this with gen_random_uuid().
  final bool isActive;
  final String? createdByUserId;
  final DateTime? createdAt;
  final DateTime? revokedAt;
  final String? notes;
  final DateTime? expiresAt;

  const EmergencyAccessTokenModel({
    this.id,
    required this.patientId,
    this.token,
    this.isActive = true,
    this.createdByUserId,
    this.createdAt,
    this.revokedAt,
    this.notes,
    this.expiresAt,
  });

  factory EmergencyAccessTokenModel.fromMap(Map map) {
    return EmergencyAccessTokenModel(
      id: map['id']?.toString(),
      patientId: map['patient_id']?.toString() ?? '',
      token: map['token']?.toString(),
      isActive: asBool(map['is_active']) ?? true,
      createdByUserId: map['created_by_user_id']?.toString(),
      createdAt: asDateTime(map['created_at']),
      revokedAt: asDateTime(map['revoked_at']),
      notes: map['notes']?.toString(),
      expiresAt: asDateTime(map['expires_at']),
    );
  }

  Map<String, dynamic> toInsertMap() => cleanMap({
    // Keep the model aligned with public.emergency_access_tokens.
    // token is optional because the DB can generate it automatically.
    'patient_id': patientId,
    'token': token,
    'is_active': isActive,
    'created_by_user_id': createdByUserId,
    'revoked_at': revokedAt?.toIso8601String(),
    'notes': notes,
    'expires_at': expiresAt?.toIso8601String(),
  });

  Map<String, dynamic> toUpdateMap() => cleanMap({
    // Only lifecycle fields should change after creation.
    'is_active': isActive,
    'revoked_at': revokedAt?.toIso8601String(),
    'notes': notes,
    'expires_at': expiresAt?.toIso8601String(),
  });

  Map<String, dynamic> toMap() => toInsertMap();
}