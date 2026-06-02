import 'dart:convert';

import 'package:http/http.dart' as http;

// Service for interacting with the patient risk prediction API.
class PatientRiskPredictionApiService {
  // Base URL of the prediction API.
  final String baseUrl;

  // Creates a new instance of PatientRiskPredictionApiService
  PatientRiskPredictionApiService({
    this.baseUrl = 'http://192.168.100.10:8000',
  });

  // Sends patient data to the prediction API and returns the results.
  Future<Map<String, dynamic>> predict({
    required Map<String, dynamic> payload,
  }) async {
    final uri = Uri.parse('$baseUrl/predict');

    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
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
