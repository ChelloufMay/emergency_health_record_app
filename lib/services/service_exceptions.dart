import 'package:supabase_flutter/supabase_flutter.dart';

// Converts a PostgrestException into a human-readable error message.
String readablePostgrestMessage(PostgrestException error, String action) {
  final parts = <String>[error.message];

  final details = error.details?.toString().trim();
  if (details != null && details.isNotEmpty) {
    parts.add(details);
  }

  final hint = error.hint?.toString().trim();
  if (hint != null && hint.isNotEmpty) {
    parts.add(hint);
  }

  return '$action failed: ${parts.join(' ')}';
}

// Ensures a string value is not empty after trimming; throws ArgumentError otherwise.
String requireText(String value, String label) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError('$label is required.');
  }
  return trimmed;
}

// Trims a string and returns null if the resulting string is empty
String? trimToNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
