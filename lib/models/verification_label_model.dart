import 'model_utils.dart';

class VerificationLabelModel {
  final String? id;
  final String patientId;
  final String entityType;
  final String entityId;
  final String fieldName;
  final String status;
  final String? verifiedByUserId;
  final DateTime? verifiedAt;
  final String? comment;
  final String? enteredByUserId;
  final String? enteredByRole;
  final String? enteredByCredentials;
  final DateTime? createdAt;

  const VerificationLabelModel({
    this.id,
    required this.patientId,
    required this.entityType,
    required this.entityId,
    required this.fieldName,
    required this.status,
    this.verifiedByUserId,
    this.verifiedAt,
    this.comment,
    this.enteredByUserId,
    this.enteredByRole,
    this.enteredByCredentials,
    this.createdAt,
  });

  factory VerificationLabelModel.fromMap(Map map) {
    return VerificationLabelModel(
      id: map['id']?.toString(),
      patientId: map['patient_id']?.toString() ?? '',
      entityType: map['entity_type']?.toString() ?? '',
      entityId: map['entity_id']?.toString() ?? '',
      fieldName: map['field_name']?.toString() ?? '',
      status: map['status']?.toString() ?? 'unverified',
      verifiedByUserId: map['verified_by_user_id']?.toString(),
      verifiedAt: asDateTime(map['verified_at']),
      comment: map['comment']?.toString(),
      enteredByUserId: map['entered_by_user_id']?.toString(),
      enteredByRole: map['entered_by_role']?.toString(),
      enteredByCredentials: map['entered_by_credentials']?.toString(),
      createdAt: asDateTime(map['created_at']),
    );
  }

  Map<String, dynamic> toInsertMap() => cleanMap({
    'patient_id': patientId,
    'entity_type': entityType,
    'entity_id': entityId,
    'field_name': fieldName,
    'status': status,
    'verified_by_user_id': verifiedByUserId,
    'verified_at': verifiedAt?.toIso8601String(),
    'comment': comment,
    'entered_by_user_id': enteredByUserId,
    'entered_by_role': enteredByRole,
    'entered_by_credentials': enteredByCredentials,
  });

  Map<String, dynamic> toUpdateMap() => cleanMap({
    // The uniqueness key is patient_id + entity_type + entity_id + field_name.
    // Those fields should stay stable after creation.
    'status': status,
    'verified_by_user_id': verifiedByUserId,
    'verified_at': verifiedAt?.toIso8601String(),
    'comment': comment,
    'entered_by_user_id': enteredByUserId,
    'entered_by_role': enteredByRole,
    'entered_by_credentials': enteredByCredentials,
  });

  Map<String, dynamic> toMap() => toInsertMap();
}