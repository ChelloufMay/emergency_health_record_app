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

  bool get canEdit => permission == 'edit' || permission == 'owner';
  bool get isEmergencyOnly => permission == 'emergency_only';
  bool get canRead => permission == 'read' || canEdit || isEmergencyOnly;
}