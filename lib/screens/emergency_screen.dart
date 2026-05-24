import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/emergency_access_token_service.dart';
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
  final _tokenService = EmergencyAccessTokenService();

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

  bool _didInitialLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // CHANGED:
    // Load after the widget is attached to a route so ModalRoute arguments
    // can be read if the payload was passed through navigation instead of
    // the constructor.
    if (!_didInitialLoad) {
      _didInitialLoad = true;
      _load();
    }
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

  String _stripQuotesAndTrim(String value) {
    var out = value.trim();
    if (out.length >= 2) {
      final first = out[0];
      final last = out[out.length - 1];
      if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
        out = out.substring(1, out.length - 1).trim();
      }
    }
    return out;
  }

  String? _extractTokenFromPayload(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    final trimmed = _stripQuotesAndTrim(raw);

    // CHANGED:
    // Accept both direct tokens and wrapped payloads.
    // Examples:
    // - healthapp://emergency?payload=...
    // - healthapp://emergency?token=...
    // - {"token":"..."}
    // - plain token text
    final uri = Uri.tryParse(trimmed);
    if (uri != null) {
      final tokenFromQuery = uri.queryParameters['token']?.trim();
      if (tokenFromQuery != null && tokenFromQuery.isNotEmpty) {
        return _stripQuotesAndTrim(Uri.decodeComponent(tokenFromQuery));
      }

      final payloadFromQuery = uri.queryParameters['payload']?.trim();
      if (payloadFromQuery != null && payloadFromQuery.isNotEmpty) {
        final nested = _extractTokenFromPayload(
          Uri.decodeComponent(_stripQuotesAndTrim(payloadFromQuery)),
        );
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
        return _stripQuotesAndTrim(token);
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
        if (token != null && token.isNotEmpty) {
          return _stripQuotesAndTrim(token);
        }

        final payload = jsonValue['payload']?.toString().trim();
        if (payload != null && payload.isNotEmpty) {
          final nested = _extractTokenFromPayload(payload);
          if (nested != null && nested.isNotEmpty) return nested;
        }
      }
    } catch (_) {
      // Not JSON, keep trying raw text.
    }

    // CHANGED:
    // Final fallback is raw token text, normalized.
    return trimmed;
  }

  String? _resolveRawPayload() {
    // 1) Constructor payload has priority.
    final direct = widget.payload?.trim();
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }

    // 2) Route arguments are commonly used when the screen is opened via
    // Navigator.pushNamed or a deep-link handler.
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs == null) return null;

    if (routeArgs is String) {
      final value = routeArgs.trim();
      return value.isEmpty ? null : value;
    }

    if (routeArgs is Uri) {
      final value = routeArgs.toString().trim();
      return value.isEmpty ? null : value;
    }

    if (routeArgs is Map) {
      final map = Map<String, dynamic>.from(routeArgs);
      final candidates = [
        map['payload'],
        map['token'],
        map['uri'],
        map['link'],
        map['data'],
      ];

      for (final candidate in candidates) {
        if (candidate == null) continue;
        final value = candidate.toString().trim();
        if (value.isNotEmpty) return value;
      }
    }

    return null;
  }

  Future<void> _load() async {
    final rawInput = _resolveRawPayload();
    final token = _extractTokenFromPayload(rawInput);

    // CHANGED:
    // Clear any stale state before attempting a new resolve.
    _hasResolvedToken = false;
    _hasOfflineSnapshot = false;
    _patientId = null;
    _name = null;
    _dob = null;
    _age = null;
    _bloodType = null;
    _phone = null;
    _emergencyContact = null;
    _addressSummary = null;
    _insurancePlan = null;
    _covidVaccineType = null;
    _allergies = [];
    _medications = [];
    _conditions = [];

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    try {
      // CHANGED:
      // Resolve the emergency token through the dedicated token service.
      // This keeps the emergency flow on the RPC path and avoids any direct
      // read from emergency_access_tokens in the UI layer.
      final resolved = await _tokenService.resolveEmergencyAccessToken(token);

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
        _age = source['age_years']?.toString() ?? resolved['age_years']?.toString();
        _bloodType =
            source['blood_type']?.toString() ?? resolved['blood_type']?.toString();
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
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
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
                    _name?.isNotEmpty == true ? _name! : 'Emergency patient',
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
                  if (_hasOfflineSnapshot) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Offline summary was included in the token payload.',
                    ),
                  ],
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