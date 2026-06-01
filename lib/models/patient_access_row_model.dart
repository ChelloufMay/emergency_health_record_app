// Represents a row in the UI that displays a patient and the user's access level to their record.
// Used in the "My Patients" or "Access" dashboard for caregivers and clinicians.
class PatientAccessRowModel {
  final String patientId;
  final String patientName;
  final String permission;
  final String role;
  final String? status;
  final String? grantId;
  final String? inviteToken;
  final Map<String, dynamic> raw;

  const PatientAccessRowModel({
    required this.patientId,
    required this.patientName,
    required this.permission,
    required this.role,
    required this.raw,
    this.status,
    this.grantId,
    this.inviteToken,
  });

  factory PatientAccessRowModel.fromMap(Map<String, dynamic> map) {
    String readString(List<String> keys, {String fallback = ''}) {
      for (final key in keys) {
        final value = map[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
      return fallback;
    }

    return PatientAccessRowModel(
      patientId: readString(['patient_id', 'id', 'target_patient_id']),
      patientName: readString([
        'patient_name',
        'full_name',
        'name',
        'display_name',
      ], fallback: 'Unknown patient'),
      permission: readString(['permission'], fallback: 'read'),
      role: readString(['grantee_role', 'role'], fallback: 'unknown'),
      status: map['status']?.toString(),
      grantId: map['grant_id']?.toString() ?? map['id']?.toString(),
      inviteToken: map['invite_token']?.toString(),
      raw: map,
    );
  }

  // Converts the model back to a Map.
  Map<String, dynamic> toMap() {
    return {
      'patient_id': patientId,
      'patient_name': patientName,
      'permission': permission,
      'grantee_role': role,
      'status': status,
      'grant_id': grantId,
      'invite_token': inviteToken,
      ...raw,
    };
  }

  // True if the user has permission to edit.
  bool get canEdit => permission == 'edit' || permission == 'owner';

  // True if the user only has emergency access.
  bool get isEmergencyOnly => permission == 'emergency_only';

  // True if the user has at least read access.
  bool get canRead => permission == 'read' || canEdit || isEmergencyOnly;
}
