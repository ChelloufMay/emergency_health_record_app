// A collection of static validation methods for form fields.
class Validators {
  // Validates that a field is not empty.
  static String? requiredField(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  // Validates that a field contains a properly formatted email address
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final pattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!pattern.hasMatch(value.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  // Validates that a password meets the minimum length requirement
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Validates that a field contains a valid date string (YYYY-MM-DD) or is empty
  static String? optionalDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(value.trim());
    if (parsed == null) {
      return 'Use YYYY-MM-DD';
    }
    return null;
  }

  // Validates that a field contains a valid number or is empty
  static String? optionalNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = num.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number';
    }
    return null;
  }

  // Validates that a field contains a valid phone number format or is empty.
  static String? optionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.trim();
    final pattern = RegExp(r'^[0-9+\-\s().]{6,}$');
    if (!pattern.hasMatch(cleaned)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  // Validates that a value belongs to a specific set of allowed strings.
  // Useful for dropdown-backed fields when to keep values aligned with the enums/allowed strings in the database.
  static String? valueInSet(
    String? value, {
    required Set<String> allowed,
    String label = 'Value',
  }) {
    if (value == null || value.trim().isEmpty) return null;
    if (!allowed.contains(value.trim())) {
      return '$label is invalid';
    }
    return null;
  }
}
