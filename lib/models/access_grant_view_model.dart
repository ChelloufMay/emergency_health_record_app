import 'access_grant_model.dart';
import 'model_utils.dart';

/// UI-friendly grant row used by both owner-management screens and caregiver
/// access screens.
class AccessGrantViewModel {
  final String grantId;
  final String patientId;

  /// CHANGED: display name for the patient in caregiver access screens.
  final String patientName;

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
    this.patientName = '',
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
      Map row,
      List keys, {
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

  static String _fullNameFromRow(Map row) {
    final direct = _stringValue(
      row,
      const ['patient_name', 'patient_full_name', 'full_name', 'name', 'display_name'],
    );
    if (direct.isNotEmpty) return direct;

    final firstName = _stringValue(
      row,
      const ['first_name', 'patient_first_name', 'given_name'],
    );
    final familyName = _stringValue(
      row,
      const ['family_name', 'patient_family_name', 'last_name', 'surname'],
    );

    return [firstName, familyName].where((part) => part.trim().isNotEmpty).join(' ').trim();
  }

  factory AccessGrantViewModel.fromGrant(AccessGrantModel grant) {
    return AccessGrantViewModel(
      grantId: grant.id ?? '',
      patientId: grant.patientId,
      patientName: '',
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
    final row = Map.from(map);

    final grantId = _stringValue(
      row,
      const ['grant_id', 'access_grant_id', 'id'],
    );

    final patientName = _fullNameFromRow(row);

    final granteeLabel = _stringValue(
      row,
      const [
        'grantee_name',
        'grantee_email',
        'grantee_display_name',
        'grantee_full_name',
        'grantee_user_id',
      ],
      fallback: 'Connected user',
    );

    return AccessGrantViewModel(
      grantId: grantId,
      patientId: row['patient_id']?.toString() ?? '',
      patientName: patientName,
      granteeUserId: _stringValue(row, const ['grantee_user_id']),
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

  Map toEditorRow() => {
    'id': grantId,
    'grant_id': grantId,
    'patient_id': patientId,
    'grantee_role': granteeRole,
    'permission': permission,
    'expires_at': expiresAt?.toIso8601String(),
    'notes': notes,
  };
}