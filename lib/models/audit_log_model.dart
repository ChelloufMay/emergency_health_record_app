import 'model_utils.dart';

// Represents an audit log entry for tracking actions performed on patient records. --> maps to the 'audit_logs' table in the database.
class AuditLogModel {
  final String? id;
  final String patientId;
  final String? performedByUserId;
  final String action; // DB enum: action_type.
  final String entityType;
  final String? entityId;
  final String? fieldName;
  final String? oldValue;
  final String? newValue;
  final String? deviceId;
  final String? ipAddress;
  final String? breakGlassReason;
  final String? eventHash;
  final DateTime? timestamp; // DB defaults to now().

  const AuditLogModel({
    this.id,
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
    this.timestamp,
  });

  factory AuditLogModel.fromMap(Map map) {
    return AuditLogModel(
      id: map['id']?.toString(),
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
      timestamp: asDateTime(map['timestamp']),
    );
  }

  Map<String, dynamic> toInsertMap() => cleanMap({
    // Audit logs are append-only.
    // Service role writes them; the DB may also fill timestamp automatically.
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
    'timestamp': timestamp?.toIso8601String(),
  });

  Map<String, dynamic> toMap() => toInsertMap();
}
