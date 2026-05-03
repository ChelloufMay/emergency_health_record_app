class VerificationLabelModel {
  final String id;
  final String patientId;
  final String entityType;
  final String entityId;
  final String fieldName;
  final String status; // unverified, user_entered, caregiver_entered, clinician_verified
  final String? verifiedByUserId;
  final DateTime? verifiedAt;
  final String? comment;
  final DateTime createdAt;

  VerificationLabelModel({
    required this.id,
    required this.patientId,
    required this.entityType,
    required this.entityId,
    required this.fieldName,
    required this.status,
    this.verifiedByUserId,
    this.verifiedAt,
    this.comment,
    required this.createdAt,
  });

  factory VerificationLabelModel.fromMap(Map<String, dynamic> map) {
    return VerificationLabelModel(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      fieldName: map['field_name'] as String,
      status: map['status'] as String? ?? 'unverified',
      verifiedByUserId: map['verified_by_user_id'] as String?,
      verifiedAt: map['verified_at'] != null
          ? DateTime.tryParse(map['verified_at'].toString())
          : null,
      comment: map['comment'] as String?,
      createdAt: DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patient_id': patientId,
      'entity_type': entityType,
      'entity_id': entityId,
      'field_name': fieldName,
      'status': status,
      'verified_by_user_id': verifiedByUserId,
      'verified_at': verifiedAt?.toIso8601String(),
      'comment': comment,
    };
  }
}