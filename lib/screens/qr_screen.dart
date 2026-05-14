import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/emergency_payload_service.dart';
import '../services/patient_service.dart';
import '../services/patient_session_service.dart';

class QrScreen extends StatefulWidget {
  final String? patientId;
  final bool canEdit;
  final bool isEmergencyOnly;

  const QrScreen({
    super.key,
    this.patientId,
    this.canEdit = false,
    this.isEmergencyOnly = false,
  });

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final PatientService _patientService = PatientService();

  bool _loading = true;
  String _payload = '';
  Map<String, dynamic>? _summary;

  String? _resolvePatientId() {
    return widget.patientId ?? PatientSessionService.instance.current?.patientId;
  }

  Future<void> _load() async {
    final patientId = _resolvePatientId();
    if (patientId == null || patientId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _payload = '';
      });
      return;
    }

    final summary = await _patientService.fetchEmergencySummary(patientId);
    final payloadMap = <String, dynamic>{
      'version': 1,
      'type': 'emergency_access',
      'patient_id': patientId,
      'offline_summary': summary ?? {},
      'issued_at': DateTime.now().toIso8601String(),
    };

    final payload = EmergencyPayloadService.encodePayload(payloadMap);
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _payload = payload;
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _copyPayload() async {
    await Clipboard.setData(ClipboardData(text: _payload));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR payload copied.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientName = [
      _summary?['first_name']?.toString() ?? '',
      _summary?['family_name']?.toString() ?? '',
    ].join(' ').trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency QR'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _payload.isEmpty
          ? const Center(child: Text('No patient selected.'))
          : Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              QrImageView(
                data: _payload,
                size: 240,
              ),
              const SizedBox(height: 16),
              Text(
                patientName.isEmpty ? 'Emergency payload' : patientName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SelectableText(
                _payload,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _copyPayload,
                icon: const Icon(Icons.copy),
                label: const Text('Copy payload'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}