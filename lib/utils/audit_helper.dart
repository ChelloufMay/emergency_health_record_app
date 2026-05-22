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
}