import 'dart:convert';

import 'package:http/http.dart' as http;

class PatientRiskPredictionApiService {
  final String baseUrl;

  PatientRiskPredictionApiService({
    this.baseUrl = 'http://192.168.1.20:8000',
  });

  Future<Map<String, dynamic>> predict({
    required Map<String, dynamic> payload,
  }) async {
    final uri = Uri.parse('$baseUrl/predict');

    final response = await http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Prediction API failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected API response format.');
    }

    return decoded;
  }
}