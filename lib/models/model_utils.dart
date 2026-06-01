// Utility functions for converting data types and cleaning maps,

// Convert dynamic value to a trimmed String, returns null if empty or null.
String? asString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

// Convert dynamic value to a trimmed String, returns a fallback if  empty or null.
String stringOrEmpty(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return fallback;
  return text;
}

// Safely attempts to parse a dynamic value into a DateTime object.
DateTime? asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

// Safely attempts to parse a dynamic value into an integer.
int? asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

// Safely attempts to parse a dynamic value into a double.
double? asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
}

// Safely attempts to parse a dynamic value into a boolean.
bool? asBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  final text = value.toString().toLowerCase().trim();
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return null;
}

// Removes all entries with null values from the given map.
Map<String, dynamic> cleanMap(Map<String, dynamic> map) {
  final out = <String, dynamic>{};
  for (final entry in map.entries) {
    if (entry.value != null) out[entry.key] = entry.value;
  }
  return out;
}
