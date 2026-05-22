class AuditHelper {
  static String? nullIfEmpty(String? value) {
    final v = value?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  static String normalize(String value) {
    return value.trim();
  }

  static String dateToDb(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    return value.trim();
  }

  static String actionLabel(String action, String entityType) {
    return '$action:$entityType';
  }

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

  static bool isClinicianVerified(String? status) {
    return status?.trim().toLowerCase() == 'clinician_verified';
  }

  static String labelOrUnknown(String? value, {String fallback = 'Unknown'}) {
    final v = value?.trim();
    return v == null || v.isEmpty ? fallback : v;
  }

  // CHANGED: build a consistent audit payload so all callers use the same shape.
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