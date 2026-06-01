import 'access_grant_model.dart';
import 'model_utils.dart';

// A view model representing an access grant, optimized for display . --> aggregates data from the access grant and potentially related entities like patient names.
class AccessGrantViewModel {
  final String grantId;
  final String patientId;
  final String patientName;
  final String granteeUserId;
  final String granteeRole;
  final String granteeLabel;
  final String permission;
  final String status;
  final DateTime? expiresAt;
  final String? notes;

  // The underlying AccessGrantModel if available.
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

  // Helper to extract a non-empty string value from a map using a list of possible keys.
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

  // Helper to construct a full name from various possible patient name fields in a map.
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

  // Create a view model from a base AccessGrantModel.
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

  // Create a view model from a database row (Map), handling various potential field names.
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
