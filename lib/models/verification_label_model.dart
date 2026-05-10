class VerificationLabelModel {
  final String id;
  final String patientId;
  final String entityType;
  final String entityId;
  final String fieldName;

  // Existing verification state:
  // - unverified
  // - user_entered
  // - caregiver_entered
  // - clinician_verified
  final String status;

  // Existing verification metadata:
  final String? verifiedByUserId;
  final DateTime? verifiedAt;
  final String? comment;
  final DateTime createdAt;

  // New provenance fields:
  // These capture who originally entered/created the value, what role they had, and any credentials/specialty text the UI stores.
  final String? enteredByUserId;
  final String? enteredByRole;
  final String? enteredByCredentials;

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
    this.enteredByUserId,
    this.enteredByRole,
    this.enteredByCredentials,
  });

  factory VerificationLabelModel.fromMap(Map<String, dynamic> map) {
    return VerificationLabelModel(
      id: map['id']?.toString() ?? '',
      patientId: map['patient_id']?.toString() ?? '',
      entityType: map['entity_type']?.toString() ?? '',
      entityId: map['entity_id']?.toString() ?? '',
      fieldName: map['field_name']?.toString() ?? '',
      status: map['status']?.toString() ?? 'unverified',
      verifiedByUserId: map['verified_by_user_id']?.toString(),
      verifiedAt: map['verified_at'] != null
          ? DateTime.tryParse(map['verified_at'].toString())
          : null,
      comment: map['comment']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),

      // New provenance fields read from the database.
      enteredByUserId: map['entered_by_user_id']?.toString(),
      enteredByRole: map['entered_by_role']?.toString(),
      enteredByCredentials: map['entered_by_credentials']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // Keep the core verification identity fields.
      'patient_id': patientId,
      'entity_type': entityType,
      'entity_id': entityId,
      'field_name': fieldName,
      'status': status,
      'verified_by_user_id': verifiedByUserId,
      'verified_at': verifiedAt?.toIso8601String(),
      'comment': comment,

      // New provenance fields written back to the database.
      'entered_by_user_id': enteredByUserId,
      'entered_by_role': enteredByRole,
      'entered_by_credentials': enteredByCredentials,
    };
  }
}