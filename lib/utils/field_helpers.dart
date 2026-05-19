String displayUnknownAsNone(String? value) {
  final v = value?.trim().toLowerCase();
  if (v == null || v.isEmpty || v == 'unknown') return 'None';
  return value!.trim();
}

String yesNo(bool? value) {
  if (value == null) return 'None';
  return value ? 'Yes' : 'No';
}

String? noneToUnknownForStorage(String? displayValue) {
  if (displayValue == null) return null;
  final v = displayValue.trim().toLowerCase();
  if (v.isEmpty || v == 'none') return 'unknown';
  return displayValue.trim();
}