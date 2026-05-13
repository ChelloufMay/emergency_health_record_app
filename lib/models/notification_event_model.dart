import 'model_utils.dart';

class NotificationEventModel {
  final String? id;
  final String patientId;
  final String? actorUserId;
  final String? recipientUserId;
  final String? recipientEmail;
  final String eventType;
  final String? entityType;
  final String? entityId;
  final String message;
  final String deliveryChannel;
  final bool isSent;
  final DateTime? sentAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NotificationEventModel({
    this.id,
    required this.patientId,
    this.actorUserId,
    this.recipientUserId,
    this.recipientEmail,
    required this.eventType,
    this.entityType,
    this.entityId,
    required this.message,
    this.deliveryChannel = 'email',
    this.isSent = false,
    this.sentAt,
    this.createdAt,
    this.updatedAt,
  });

  factory NotificationEventModel.fromMap(Map map) {
    return NotificationEventModel(
      id: map['id']?.toString(),
      patientId: map['patient_id']?.toString() ?? '',
      actorUserId: map['actor_user_id']?.toString(),
      recipientUserId: map['recipient_user_id']?.toString(),
      recipientEmail: map['recipient_email']?.toString(),
      eventType: map['event_type']?.toString() ?? '',
      entityType: map['entity_type']?.toString(),
      entityId: map['entity_id']?.toString(),
      message: map['message']?.toString() ?? '',
      deliveryChannel: map['delivery_channel']?.toString() ?? 'email',
      isSent: asBool(map['is_sent']) ?? false,
      sentAt: asDateTime(map['sent_at']),
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }
}