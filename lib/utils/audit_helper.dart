// keeps service calls cleaner by normalizing text before saving.
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
}