// Converts "unknown" or empty values to "None" for UI display. (not used anymore I think I don't remember)
String displayUnknownAsNone(String? value) {
  final v = value?.trim().toLowerCase();
  if (v == null || v.isEmpty || v == 'unknown') return 'None';
  return value!.trim();
}

// Converts a boolean to a "Yes" or "No" string, returning "None" if null.
String yesNo(bool? value) {
  if (value == null) return 'None';
  return value ? 'Yes' : 'No';
}

// Converts "None" or empty UI values to "unknown" for database storage.
String? noneToUnknownForStorage(String? displayValue) {
  if (displayValue == null) return null;
  final v = displayValue.trim().toLowerCase();
  if (v.isEmpty || v == 'none') return 'unknown';
  return displayValue.trim();
}
