class AuditLogModel {
  final String id;
  final String patientId;
  final String? performedByUserId;
  final String action; // create, update, delete, view, break_glass
  final String entityType;
  final String? entityId;
  final String? fieldName;
  final String? oldValue;
  final String? newValue;
  final String? deviceId;
  final String? ipAddress;
  final String? breakGlassReason;
  final String? eventHash;
  final DateTime timestamp;

  AuditLogModel({
    required this.id,
    required this.patientId,
    this.performedByUserId,
    required this.action,
    required this.entityType,
    this.entityId,
    this.fieldName,
    this.oldValue,
    this.newValue,
    this.deviceId,
    this.ipAddress,
    this.breakGlassReason,
    this.eventHash,
    required this.timestamp,
  });

  factory AuditLogModel.fromMap(Map<String, dynamic> map) {
    return AuditLogModel(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      performedByUserId: map['performed_by_user_id'] as String?,
      action: map['action'] as String,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String?,
      fieldName: map['field_name'] as String?,
      oldValue: map['old_value'] as String?,
      newValue: map['new_value'] as String?,
      deviceId: map['device_id'] as String?,
      ipAddress: map['ip_address'] as String?,
      breakGlassReason: map['break_glass_reason'] as String?,
      eventHash: map['event_hash'] as String?,
      timestamp: DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patient_id': patientId,
      'performed_by_user_id': performedByUserId,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'field_name': fieldName,
      'old_value': oldValue,
      'new_value': newValue,
      'device_id': deviceId,
      'ip_address': ipAddress,
      'break_glass_reason': breakGlassReason,
      'event_hash': eventHash,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}