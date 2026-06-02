// Helper class for formatting and normalizing data for audit logs and UI display.
class AuditHelper {
  // Returns null if the string is empty or only contains whitespace.
  static String? nullIfEmpty(String? value) {
    final v = value?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  // Trims whitespace from the string.
  static String normalize(String value) {
    return value.trim();
  }

  // Normalizes a date string for database storage.
  static String dateToDb(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    return value.trim();
  }

  // Formats an action and entity type into a label
  static String actionLabel(String action, String entityType) {
    return '$action:$entityType';
  }

  // Joins non empty strings with a separator.
  static String joinNonEmpty(
    Iterable<String?> values, {
    String separator = ' • ',
    String fallback = '',
  }) {
    final parts = values
        .map((e) => e?.trim())
        .where((e) => e != null && e.isNotEmpty)
        .cast<String>()
        .toList();

    return parts.isEmpty ? fallback : parts.join(separator);
  }

  // Checks if the verification status indicates clinician verification
  static bool isClinicianVerified(String? status) {
    return status?.trim().toLowerCase() == 'clinician_verified';
  }

  // Returns the value or a fallback string if it is null or empty
  static String labelOrUnknown(String? value, {String fallback = 'Unknown'}) {
    final v = value?.trim();
    return v == null || v.isEmpty ? fallback : v;
  }

  // Builds a standard audit record map for database insertion
  static Map<String, dynamic> buildAuditRecord({
    required String patientId,
    required String action,
    required String entityType,
    String? performedByUserId,
    String? entityId,
    String? fieldName,
    String? oldValue,
    String? newValue,
    String? notes,
  }) {
    return {
      'patient_id': normalize(patientId),
      'performed_by_user_id': nullIfEmpty(performedByUserId),
      'action': normalize(action),
      'entity_type': normalize(entityType),
      'entity_id': nullIfEmpty(entityId),
      'field_name': nullIfEmpty(fieldName),
      'old_value': nullIfEmpty(oldValue),
      'new_value': nullIfEmpty(newValue),
      'notes': nullIfEmpty(notes),
    };
  }
}
