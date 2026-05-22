import 'dart:convert';
import 'package:flutter/material.dart';

import '../services/emergency_payload_service.dart';
import '../services/patient_service.dart';

class EmergencyScreen extends StatefulWidget {
  final String? payload;

  const EmergencyScreen({super.key, this.payload});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final _patientService = PatientService();

  bool _loading = true;
  bool _hasOfflineSnapshot = false;
  bool _hasResolvedToken = false;

  String? _patientId;
  String? _name;
  String? _dob;
  String? _age;
  String? _bloodType;
  String? _phone;
  String? _emergencyContact;
  String? _addressSummary;
  String? _insurancePlan;
  String? _covidVaccineType;

  List<Map<String, dynamic>> _allergies = [];
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _conditions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Map<String, dynamic> _mapFrom(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _listFrom(dynamic value) {
    if (value is List) {
      return value
          .map((item) => _mapFrom(item))
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  String? _extractTokenFromPayload(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    final trimmed = raw.trim();

    // Accept both payload links and direct token links.
    // Examples:
    // - healthapp://emergency?payload=...
    // - healthapp://emergency?token=...
    final uri = Uri.tryParse(trimmed);
    if (uri != null) {
      final tokenFromQuery = uri.queryParameters['token']?.trim();
      if (tokenFromQuery != null && tokenFromQuery.isNotEmpty) {
        return tokenFromQuery;
      }

      final payloadFromQuery = uri.queryParameters['payload']?.trim();
      if (payloadFromQuery != null && payloadFromQuery.isNotEmpty) {
        final nested = _extractTokenFromPayload(Uri.decodeComponent(payloadFromQuery));
        if (nested != null && nested.isNotEmpty) return nested;
      }

      final uriPayload = EmergencyPayloadService.extractPayloadFromUri(uri);
      if (uriPayload != null && uriPayload.trim().isNotEmpty) {
        final nested = _extractTokenFromPayload(uriPayload);
        if (nested != null && nested.isNotEmpty) return nested;
      }
    }

    final decoded = EmergencyPayloadService.decodePayload(trimmed);
    if (decoded != null) {
      final token = decoded['token']?.toString().trim();
      if (token != null && token.isNotEmpty) {
        _hasOfflineSnapshot = decoded['offline_summary'] is Map;
        return token;
      }

      final nestedPayload = decoded['payload']?.toString().trim();
      if (nestedPayload != null && nestedPayload.isNotEmpty) {
        final nested = _extractTokenFromPayload(nestedPayload);
        if (nested != null && nested.isNotEmpty) return nested;
      }
    }

    try {
      final jsonValue = jsonDecode(trimmed);
      if (jsonValue is Map) {
        final token = jsonValue['token']?.toString().trim();
        if (token != null && token.isNotEmpty) return token;
      }
    } catch (_) {
      // Not JSON, continue.
    }

    // Fall back to raw token text.
    return trimmed;
  }

  Future<void> _load() async {
    final token = _extractTokenFromPayload(widget.payload);

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    try {
      final resolved = await _patientService.resolveEmergencyAccessToken(token);

      if (resolved == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      final patientId =
          resolved['patient_id']?.toString() ??
              resolved['patient_profile_id']?.toString();

      Map<String, dynamic>? emergencySummary;

      if (patientId != null && patientId.isNotEmpty) {
        emergencySummary = await _patientService.fetchEmergencySummary(patientId);
      }

      final fallback = _mapFrom(resolved['offline_summary']);
      final source = emergencySummary ?? fallback;

      if (!mounted) return;
      setState(() {
        _hasResolvedToken = true;
        _patientId = patientId;
        _name = [
          source['first_name']?.toString() ??
              resolved['first_name']?.toString() ??
              '',
          source['family_name']?.toString() ??
              resolved['family_name']?.toString() ??
              '',
        ].join(' ').trim();

        final dobValue = source['date_of_birth'] ?? resolved['date_of_birth'];
        _dob = dobValue?.toString();
        _age =
            source['age_years']?.toString() ??
                resolved['age_years']?.toString();
        _bloodType =
            source['blood_type']?.toString() ??
                resolved['blood_type']?.toString();
        _phone = source['phone']?.toString() ?? resolved['phone']?.toString();
        _emergencyContact = [
          source['emergency_contact_name']?.toString() ??
              resolved['emergency_contact_name']?.toString() ??
              '',
          source['emergency_contact_phone']?.toString() ??
              resolved['emergency_contact_phone']?.toString() ??
              '',
        ].where((e) => e.trim().isNotEmpty).join(' • ');
        _addressSummary = [
          source['address_country']?.toString() ??
              resolved['address_country']?.toString() ??
              '',
          source['address_governorate']?.toString() ??
              resolved['address_governorate']?.toString() ??
              '',
          source['address_city']?.toString() ??
              resolved['address_city']?.toString() ??
              '',
        ].where((e) => e.trim().isNotEmpty).join(' • ');
        _insurancePlan =
            source['insurance_plan']?.toString() ??
                resolved['insurance_plan']?.toString();
        _covidVaccineType =
            source['covid_vaccine_type']?.toString() ??
                resolved['covid_vaccine_type']?.toString();
        _allergies = _listFrom(source['allergies']);
        _medications = _listFrom(source['medications']);
        _conditions = _listFrom(source['chronic_conditions']);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Widget _renderItem(Map<String, dynamic> item) {
    final title =
        item['allergen_name'] ??
            item['medication_name'] ??
            item['condition_name'] ??
            'Item';
    final detailParts = <String>[
      if ((item['reaction']?.toString() ?? '').trim().isNotEmpty)
        item['reaction'].toString(),
      if ((item['severity']?.toString() ?? '').trim().isNotEmpty)
        item['severity'].toString(),
      if ((item['dosage']?.toString() ?? '').trim().isNotEmpty)
        item['dosage'].toString(),
      if ((item['frequency']?.toString() ?? '').trim().isNotEmpty)
        item['frequency'].toString(),
      if ((item['type']?.toString() ?? '').trim().isNotEmpty)
        item['type'].toString(),
      if ((item['notes']?.toString() ?? '').trim().isNotEmpty)
        item['notes'].toString(),
    ];

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(title.toString()),
      subtitle: detailParts.isEmpty ? null : Text(detailParts.join(' • ')),
    );
  }

  Widget _section(String title, List<Map<String, dynamic>> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (items.isEmpty) const Text('No data') else ...items.map(_renderItem),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientIdLabel = _patientId ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency view'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_hasResolvedToken
          ? const Center(child: Text('Invalid or missing emergency token.'))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name?.isNotEmpty == true
                        ? _name!
                        : 'Emergency patient',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Patient ID: $patientIdLabel'),
                  Text('DOB: ${_dob ?? 'Unknown'}'),
                  Text('Age: ${_age ?? 'Unknown'}'),
                  Text('Blood type: ${_bloodType ?? 'Unknown'}'),
                  Text('Phone: ${_phone ?? 'Unknown'}'),
                  Text('Emergency contact: ${_emergencyContact ?? 'Unknown'}'),
                  Text('Address: ${_addressSummary ?? 'Unknown'}'),
                  Text('Insurance: ${_insurancePlan ?? 'Unknown'}'),
                  Text('COVID vaccine: ${_covidVaccineType ?? 'Unknown'}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _section('Allergies', _allergies),
          const SizedBox(height: 12),
          _section('Medications', _medications),
          const SizedBox(height: 12),
          _section('Chronic conditions', _conditions),
          if (_allergies.isEmpty &&
              _medications.isEmpty &&
              _conditions.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'No detailed emergency data was returned for this token.',
              ),
            ),
        ],
      ),
    );
  }
}