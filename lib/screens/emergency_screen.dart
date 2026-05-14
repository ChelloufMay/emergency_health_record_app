import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/allergy_service.dart';
import '../services/emergency_payload_service.dart';
import '../services/medication_service.dart';
import '../services/patient_service.dart';
import '../services/patient_session_service.dart';

class EmergencyScreen extends StatefulWidget {
  final String? patientId;
  final String? payload;
  final bool canEdit;
  final bool isEmergencyOnly;

  const EmergencyScreen({
    super.key,
    this.patientId,
    this.payload,
    this.canEdit = false,
    this.isEmergencyOnly = false,
  });

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final PatientService _patientService = PatientService();
  final AllergyService _allergyService = AllergyService();
  final MedicationService _medicationService = MedicationService();

  bool _loading = true;
  String? _patientId;

  Map<String, dynamic>? _summary;
  List<dynamic> _allergies = [];
  List<dynamic> _medications = [];
  List<dynamic> _conditions = [];

  String? _resolvePatientId() {
    return widget.patientId ?? PatientSessionService.instance.current?.patientId;
  }

  Future<void> _load() async {
    final payload = widget.payload;
    if (payload != null && payload.isNotEmpty) {
      final decoded = EmergencyPayloadService.decodePayload(payload);
      if (decoded != null) {
        final offlineSummary = decoded['offline_summary'];
        if (offlineSummary is Map) {
          _summary = offlineSummary.map((key, value) => MapEntry(key.toString(), value));
        }
        final patientId = decoded['patient_id']?.toString();
        _patientId = patientId;
      }
    }

    final patientId = _patientId ?? _resolvePatientId();
    if (patientId == null || patientId.isEmpty) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    _patientId = patientId;

    _summary ??= await _patientService.fetchEmergencySummary(patientId);

    final allergies = await _allergyService.fetchByPatient(patientId);
    final medications = await _medicationService.fetchByPatient(patientId);

    if (!mounted) return;
    setState(() {
      _allergies = allergies;
      _medications = medications;
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final name = [
      _summary?['first_name']?.toString() ?? '',
      _summary?['family_name']?.toString() ?? '',
    ].join(' ').trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency view'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patientId == null
          ? const Center(child: Text('No emergency payload or active session found.'))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Unknown patient' : name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Blood type: ${_summary?['blood_type']?.toString() ?? '-'}'),
                  Text('Phone: ${_summary?['phone']?.toString() ?? '-'}'),
                  Text('Emergency contact: ${_summary?['emergency_contact_name']?.toString() ?? '-'}'),
                  Text('Contact phone: ${_summary?['emergency_contact_phone']?.toString() ?? '-'}'),
                  Text('Address: ${[
                    _summary?['address_country'],
                    _summary?['address_governorate'],
                    _summary?['address_city'],
                  ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', ')}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Allergies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._allergies.map((item) {
            final map = item is Map ? item : null;
            final title = map?['allergen_name']?.toString() ?? item.toString();
            final subtitle = [
              map?['reaction']?.toString(),
              map?['severity']?.toString(),
            ].where((e) => e != null && e.trim().isNotEmpty).join(' • ');
            return Card(
              child: ListTile(
                leading: const Icon(Icons.warning_amber),
                title: Text(title),
                subtitle: Text(subtitle.isEmpty ? '-' : subtitle),
              ),
            );
          }),
          const SizedBox(height: 16),
          const Text('Medications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._medications.map((item) {
            final map = item is Map ? item : null;
            final title = map?['medication_name']?.toString() ?? item.toString();
            final subtitle = [
              map?['dosage']?.toString(),
              map?['frequency']?.toString(),
              map?['purpose']?.toString(),
            ].where((e) => e != null && e.trim().isNotEmpty).join(' • ');
            return Card(
              child: ListTile(
                leading: const Icon(Icons.medication),
                title: Text(title),
                subtitle: Text(subtitle.isEmpty ? '-' : subtitle),
              ),
            );
          }),
        ],
      ),
    );
  }
}