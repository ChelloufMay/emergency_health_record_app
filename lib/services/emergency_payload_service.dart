import 'dart:convert';

// Encoding and decoding emergency data payloads and links.
class EmergencyPayloadService {
  // Encodes a Map of data into a Base64URL string.
  static String encodePayload(Map data) {
    return base64UrlEncode(utf8.encode(jsonEncode(data)));
  }

  // Decodes a Base64URL string back into a Map
  static Map? decodePayload(String raw) {
    try {
      final bytes = base64Url.decode(raw);
      final jsonText = utf8.decode(bytes);
      final decoded = jsonDecode(jsonText);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Builds an emergency web link with the provided token.
  static String buildEmergencyWebLink(String token) {
    return 'https://chelloufmay.github.io/ehr-emergency-web/?token=${Uri.encodeComponent(token)}';
  }

  // Extracts the payload string from a Uri
  static String? extractPayloadFromUri(Uri uri) {
    final query = uri.queryParameters['payload'];
    if (query != null && query.isNotEmpty) return query;
    if (uri.pathSegments.isNotEmpty) return uri.pathSegments.last;
    return null;
  }
}
