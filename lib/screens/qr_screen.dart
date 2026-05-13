import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/emergency_payload_service.dart';
import '../services/patient_service.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final PatientService _patientService = PatientService();

  bool _loading = true;
  String _qrData = '';
  String _displayText = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _stringify(dynamic value) => value?.toString().trim() ?? '';

  Future<void> _load() async {
    final identity = await _patientService.resolveIdentity();
    if (identity == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _displayText = 'No profile found';
      });
      return;
    }

    final summary = await _patientService.fetchEmergencySummary(identity.patientId);
    if (summary == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _displayText = 'No emergency summary found';
      });
      return;
    }

    final payload = <String, dynamic>{
      'version': 1,
      'patient_id': summary['patient_id'],
      'first_name': summary['first_name'],
      'family_name': summary['family_name'],
      'sex': summary['sex'],
      'age_years': summary['age_years'],
      'blood_type': summary['blood_type'],
      'phone': summary['phone'],
      'emergency_contact_name': summary['emergency_contact_name'],
      'emergency_contact_phone': summary['emergency_contact_phone'],
      'address_country': summary['address_country'],
      'address_governorate': summary['address_governorate'],
      'address_city': summary['address_city'],
      'allergies': summary['allergies'],
      'medications': summary['medications'],
      'chronic_conditions': summary['chronic_conditions'],
    };

    final encoded = EmergencyPayloadService.encodePayload(payload);
    final link = EmergencyPayloadService.buildQrLink(encoded);

    if (!mounted) return;
    setState(() {
      _qrData = link;
      _displayText = link;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR code')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QrImageView(
                data: _qrData,
                size: 230,
              ),
              const SizedBox(height: 20),
              const Text(
                'This QR contains the offline emergency payload.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SelectableText(_displayText),
            ],
          ),
        ),
      ),
    );
  }
}