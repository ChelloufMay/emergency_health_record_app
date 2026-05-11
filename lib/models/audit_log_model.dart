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
      id: map['id']?.toString() ?? '',
      patientId: map['patient_id']?.toString() ?? '',
      performedByUserId: map['performed_by_user_id']?.toString(),
      action: map['action']?.toString() ?? 'view',
      entityType: map['entity_type']?.toString() ?? '',
      entityId: map['entity_id']?.toString(),
      fieldName: map['field_name']?.toString(),
      oldValue: map['old_value']?.toString(),
      newValue: map['new_value']?.toString(),
      deviceId: map['device_id']?.toString(),
      ipAddress: map['ip_address']?.toString(),
      breakGlassReason: map['break_glass_reason']?.toString(),
      eventHash: map['event_hash']?.toString(),
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // DB fills id automatically.
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

      // Keep the timestamp explicit in case you ever want to import or replay logs.
      'timestamp': timestamp.toIso8601String(),
    };
  }
}