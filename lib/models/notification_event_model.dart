class NotificationEventModel {
  final String id;
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
    required this.id,
    required this.patientId,
    this.actorUserId,
    this.recipientUserId,
    this.recipientEmail,
    required this.eventType,
    this.entityType,
    this.entityId,
    required this.message,
    required this.deliveryChannel,
    required this.isSent,
    this.sentAt,
    this.createdAt,
    this.updatedAt,
  });

  factory NotificationEventModel.fromJson(Map<String, dynamic> json) {
    return NotificationEventModel(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      actorUserId: json['actor_user_id']?.toString(),
      recipientUserId: json['recipient_user_id']?.toString(),
      recipientEmail: json['recipient_email']?.toString(),
      eventType: json['event_type']?.toString() ?? '',
      entityType: json['entity_type']?.toString(),
      entityId: json['entity_id']?.toString(),
      message: json['message']?.toString() ?? '',
      deliveryChannel: json['delivery_channel']?.toString() ?? 'email',
      isSent: json['is_sent'] == true,
      sentAt: DateTime.tryParse(json['sent_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }
}