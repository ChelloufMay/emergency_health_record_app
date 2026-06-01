import 'model_utils.dart';

// Represents an invitation in a user's inbox. --> display incoming access requests to a caregiver or clinician.
class AccessInboxItemModel {
  final String? id;
  final String patientId;
  final String patientName;
  final String inviteToken;
  final String invitedRole; // The role being offered (caregiver, clinician).
  final String permission; // The level of permission
  final String status; // The current status of the invitation
  final String invitedEmail;
  final String? senderLabel; // A label for the person who sent the invitation.
  final String? message;
  final DateTime? eventAt;

  final Map<String, dynamic> raw; // The original raw data from the database.

  const AccessInboxItemModel({
    this.id,
    required this.patientId,
    required this.patientName,
    required this.inviteToken,
    required this.invitedRole,
    required this.permission,
    required this.status,
    required this.invitedEmail,
    this.senderLabel,
    this.message,
    this.eventAt,
    required this.raw,
  });

  // Helper to extract a string value from a map using a list of prioritized keys.
  static String _stringValue(
    Map<String, dynamic> row,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = row[key];
      if (value != null) {
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }
    return fallback;
  }

  // Helper to extract or construct a patient's full name from a database row.
  static String patientNameFromRow(Map<String, dynamic> row) {
    final directName = _stringValue(
      row,
      const ['patient_name', 'full_name', 'name', 'display_name'],
    );
    if (directName.isNotEmpty) return directName;

    final firstName = _stringValue(
      row,
      const ['first_name', 'patient_first_name', 'given_name'],
    );
    final familyName = _stringValue(
      row,
      const ['family_name', 'patient_family_name', 'last_name', 'surname'],
    );

    final fullName = '$firstName $familyName'.trim();
    return fullName.isEmpty ? 'Unknown patient' : fullName;
  }

  // Create an AccessInboxItemModel instance from a Map, handling various status based timestamps.
  factory AccessInboxItemModel.fromMap(Map map) {
    final raw = Map<String, dynamic>.from(map);
    final status = raw['status']?.toString() ?? 'pending';

    DateTime? eventAt;
    if (status == 'accepted') {
      eventAt = asDateTime(raw['accepted_at']) ?? asDateTime(raw['created_at']);
    } else if (status == 'rejected') {
      eventAt = asDateTime(raw['rejected_at']) ?? asDateTime(raw['created_at']);
    } else {
      eventAt = asDateTime(raw['invited_at']) ?? asDateTime(raw['created_at']);
    }

    return AccessInboxItemModel(
      id: raw['id']?.toString(),
      patientId: raw['patient_id']?.toString() ?? '',
      patientName: patientNameFromRow(raw),
      inviteToken: _stringValue(
        raw,
        const ['invite_token', 'token', 'access_invite_token'],
      ),
      invitedRole: _stringValue(
        raw,
        const ['invited_role', 'role'],
        fallback: 'caregiver',
      ),
      permission: raw['permission']?.toString() ?? 'read',
      status: status,
      invitedEmail: _stringValue(
        raw,
        const ['invited_email', 'email'],
      ),
      senderLabel: _stringValue(
        raw,
        const [
          'invited_by_name',
          'sender_name',
          'invited_by_email',
          'invited_by_user_id',
        ],
        fallback: '',
      ),
      message: _stringValue(
        raw,
        const ['message', 'notes', 'invite_message'],
        fallback: '',
      ),
      eventAt: eventAt,
      raw: raw,
    );
  }
}
