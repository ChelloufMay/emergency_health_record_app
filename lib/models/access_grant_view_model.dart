import 'access_grant_model.dart';
import 'model_utils.dart';

/// UI-friendly grant row for patient-owner access management.
class AccessGrantViewModel {
  final String grantId;
  final String patientId;
  final String granteeUserId;
  final String granteeRole;
  final String granteeLabel;
  final String permission;
  final String status;
  final DateTime? expiresAt;
  final String? notes;
  final AccessGrantModel? grant;

  const AccessGrantViewModel({
    required this.grantId,
    required this.patientId,
    required this.granteeUserId,
    required this.granteeRole,
    required this.granteeLabel,
    required this.permission,
    required this.status,
    this.expiresAt,
    this.notes,
    this.grant,
  });

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

  factory AccessGrantViewModel.fromGrant(AccessGrantModel grant) {
    return AccessGrantViewModel(
      grantId: grant.id ?? '',
      patientId: grant.patientId,
      granteeUserId: grant.granteeUserId,
      granteeRole: grant.granteeRole,
      granteeLabel: grant.granteeUserId,
      permission: grant.permission,
      status: grant.status,
      expiresAt: grant.expiresAt,
      notes: grant.notes,
      grant: grant,
    );
  }

  factory AccessGrantViewModel.fromDashboardRow(Map map) {
    final row = Map<String, dynamic>.from(map);
    final grantId = _stringValue(
      row,
      const ['grant_id', 'access_grant_id', 'id'],
    );

    final granteeLabel = _stringValue(
      row,
      const [
        'grantee_name',
        'grantee_email',
        'grantee_display_name',
        'grantee_user_id',
      ],
      fallback: 'Connected user',
    );

    return AccessGrantViewModel(
      grantId: grantId,
      patientId: row['patient_id']?.toString() ?? '',
      granteeUserId: _stringValue(
        row,
        const ['grantee_user_id'],
      ),
      granteeRole: _stringValue(
        row,
        const ['grantee_role', 'role'],
        fallback: 'caregiver',
      ),
      granteeLabel: granteeLabel,
      permission: row['permission']?.toString() ?? 'read',
      status: row['status']?.toString() ?? 'active',
      expiresAt: asDateTime(row['expires_at']),
      notes: row['notes']?.toString(),
    );
  }

  Map<String, dynamic> toEditorRow() => {
    'id': grantId,
    'grant_id': grantId,
    'patient_id': patientId,
    'grantee_role': granteeRole,
    'permission': permission,
    'expires_at': expiresAt?.toIso8601String(),
    'notes': notes,
  };
}
