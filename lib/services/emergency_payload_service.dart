import 'dart:convert';

class EmergencyPayloadService {
  static String encodePayload(Map<String, dynamic> data) {
    return base64UrlEncode(utf8.encode(jsonEncode(data)));
  }

  static Map<String, dynamic>? decodePayload(String raw) {
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

  static String buildQrLink(String payload) {
    return 'healthapp://emergency?payload=${Uri.encodeComponent(payload)}';
  }

  static String? extractPayloadFromUri(Uri uri) {
    final query = uri.queryParameters['payload'];
    if (query != null && query.isNotEmpty) return query;
    if (uri.pathSegments.isNotEmpty) return uri.pathSegments.last;
    return null;
  }
}