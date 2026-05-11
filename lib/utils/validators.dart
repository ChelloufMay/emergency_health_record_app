class Validators {
  static String? requiredField(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

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

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? optionalDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(value.trim());
    if (parsed == null) {
      return 'Use YYYY-MM-DD';
    }
    return null;
  }

  static String? optionalNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = num.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number';
    }
    return null;
  }

  // Useful for contact fields where you want lightweight validation
  // without forcing a single country format.
  static String? optionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.trim();
    final pattern = RegExp(r'^[0-9+\-\s().]{6,}$');
    if (!pattern.hasMatch(cleaned)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  // Useful for dropdown-backed fields when you want to keep values aligned
  // with the enums/allowed strings in the database.
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