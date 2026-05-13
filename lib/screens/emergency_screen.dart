import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/emergency_payload_service.dart';
import '../services/patient_service.dart';
import '../services/patient_session_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final PatientService _patientService = PatientService();

  bool _loading = true;
  Map<String, dynamic>? _data;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) {
      _load();
    }
  }

  String _joinParts(List<dynamic> values) {
    return values.map((e) => e?.toString().trim() ?? '').where((e) => e.isNotEmpty).join(' • ');
  }

  String? _fromListOrText(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      final parts = value.map((e) {
        if (e is Map) {
          return e['allergen_name']?.toString() ??
              e['medication_name']?.toString() ??
              e['condition_name']?.toString() ??
              e.toString();
        }
        return e.toString();
      }).where((e) => e.trim().isNotEmpty).toList();
      if (parts.isEmpty) return null;
      return parts.join('\n');
    }
    return value.toString();
  }

  Future<void> _load() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    Map<String, dynamic>? payload;

    if (args is Map && args['payload'] != null) {
      payload = EmergencyPayloadService.decodePayload(args['payload'].toString());
    }

    if (payload == null) {
      final session = PatientSessionService.instance.current;
      final identity = await _patientService.resolveIdentity();
      final patientId = session?.patientId ?? identity?.patientId;

      if (patientId != null) {
        payload = await _patientService.fetchEmergencySummary(patientId);
      }
    }

    if (!mounted) return;
    setState(() {
      _data = payload;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency view')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : data == null
          ? const Center(child: Text('No emergency data available'))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${data['first_name'] ?? ''} ${data['family_name'] ?? ''}'.trim().isEmpty
                ? 'Unknown'
                : '${data['first_name'] ?? ''} ${data['family_name'] ?? ''}'.trim(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Age: ${data['age_years'] ?? '-'}'),
          Text('Sex: ${data['sex'] ?? '-'}'),
          Text('Blood type: ${data['blood_type'] ?? '-'}'),
          const SizedBox(height: 12),
          Text(
            'Address: ${_joinParts([
              data['address_country'],
              data['address_governorate'],
              data['address_city'],
            ])}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          const Text('Allergies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_fromListOrText(data['allergies']) ?? 'No allergies recorded'),
          const SizedBox(height: 20),
          const Text('Medications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_fromListOrText(data['medications']) ?? 'No medications recorded'),
          const SizedBox(height: 20),
          const Text('Chronic conditions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_fromListOrText(data['chronic_conditions']) ?? 'No chronic conditions recorded'),
          const SizedBox(height: 20),
          const Text('Emergency contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            [
              data['emergency_contact_name'],
              data['emergency_contact_phone'],
            ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' • '),
          ),
        ],
      ),
    );
  }
}