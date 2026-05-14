import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/emergency_payload_service.dart';
import '../services/patient_service.dart';

class EmergencyScreen extends StatefulWidget {
  final String? payload;

  const EmergencyScreen({
    super.key,
    this.payload,
  });

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final _patientService = PatientService();

  bool _loading = true;
  bool _hasOfflineSnapshot = false;

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
  DateTime? _lastUpdated;

  List<Map<String, dynamic>> _allergies = [];
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _conditions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Map<String, dynamic> _mapFrom(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _mapListFrom(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];

    return value
        .whereType<Map>()
        .map((item) => _mapFrom(item))
        .toList();
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatDateTime(DateTime dateTime) {
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  String? _formatAge(DateTime? dob) {
    if (dob == null) return null;
    final today = DateTime.now();
    var age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age.toString();
  }

  String? _buildAddressSummary(Map<String, dynamic>? row) {
    if (row == null) return null;

    final parts = <String>[
      row['address_country']?.toString().trim() ?? '',
      row['address_governorate']?.toString().trim() ?? '',
      row['address_city']?.toString().trim() ?? '',
      row['address_avenue']?.toString().trim() ?? '',
      row['address_street']?.toString().trim() ?? '',
      row['address_postal_code']?.toString().trim() ?? '',
      row['address_extra_details']?.toString().trim() ?? '',
    ].where((part) => part.isNotEmpty).toList();

    if (parts.isEmpty) {
      final nestedAddress = row['address'];
      if (nestedAddress is Map) {
        return _buildAddressSummary(_mapFrom(nestedAddress));
      }
      return null;
    }

    return parts.join(' • ');
  }

  Map<String, dynamic>? _extractSnapshot(Map<String, dynamic> decoded) {
    final offlineSummary = decoded['offline_summary'];
    if (offlineSummary is Map) {
      return _mapFrom(offlineSummary);
    }

    if (decoded.containsKey('patient_id') ||
        decoded.containsKey('first_name') ||
        decoded.containsKey('allergies') ||
        decoded.containsKey('medications') ||
        decoded.containsKey('chronic_conditions')) {
      return decoded;
    }

    return null;
  }

  void _applySummary(Map<String, dynamic> summary) {
    final dob = _parseDateTime(summary['date_of_birth']);

    final name = [
      summary['first_name']?.toString().trim() ?? '',
      summary['family_name']?.toString().trim() ?? '',
    ].where((part) => part.isNotEmpty).join(' ');

    final emergencyContactName =
        summary['emergency_contact_name']?.toString().trim() ?? '';
    final emergencyContactPhone =
        summary['emergency_contact_phone']?.toString().trim() ?? '';

    _patientId = summary['patient_id']?.toString() ??
        summary['id']?.toString() ??
        _patientId;

    _name = name.isEmpty ? _name : name;
    _dob = dob == null ? _dob : _formatDate(dob);
    _age = _formatAge(dob) ?? _age;
    _bloodType = summary['blood_type']?.toString() ?? _bloodType;
    _phone = summary['phone']?.toString() ?? _phone;

    final contactParts = <String>[
      emergencyContactName,
      emergencyContactPhone,
    ].where((part) => part.isNotEmpty).toList();
    if (contactParts.isNotEmpty) {
      _emergencyContact = contactParts.join(' • ');
    }

    _addressSummary = _buildAddressSummary(summary) ?? _addressSummary;
    _insurancePlan = summary['insurance_plan']?.toString() ?? _insurancePlan;
    _covidVaccineType =
        summary['covid_vaccine_type']?.toString() ?? _covidVaccineType;

    _allergies = _mapListFrom(summary['allergies']);
    _medications = _mapListFrom(summary['medications']);
    _conditions = _mapListFrom(
      summary['chronic_conditions'] ?? summary['medical_conditions'],
    );

    _lastUpdated = _parseDateTime(summary['updated_at']) ?? _lastUpdated;
    _hasOfflineSnapshot = true;
  }

  Future<void> _load() async {
    try {
      final rawPayload = widget.payload?.trim();

      if (rawPayload != null && rawPayload.isNotEmpty) {
        final decoded = EmergencyPayloadService.decodePayload(rawPayload);
        if (decoded != null) {
          final snapshot = _extractSnapshot(_mapFrom(decoded));
          if (snapshot != null) {
            _applySummary(snapshot);
          }
        }
      }

      final identity = await _patientService.resolveIdentity();

      _patientId ??= identity?.patientProfileId;

      if (_patientId != null) {
        final remote = await _patientService.fetchEmergencySummary(_patientId!);
        if (remote != null) {
          _applySummary(_mapFrom(remote));
        }
      }
    } catch (_) {
      // Keep whatever was decoded locally. Emergency view should still render.
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _joinDetails(List<String?> values) {
    final cleaned = values
        .where((value) => value != null && value.trim().isNotEmpty)
        .map((value) => value!.trim())
        .toList();

    if (cleaned.isEmpty) return '-';
    return cleaned.join(' • ');
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('$label: ${value?.trim().isNotEmpty == true ? value : '-'}'),
    );
  }

  Widget _buildMapItem({
    required Map<String, dynamic> row,
    required String titleKey,
    List<String> subtitleKeys = const [],
    String? fallbackTitle,
  }) {
    final title = row[titleKey]?.toString().trim();
    final subtitle = _joinDetails(
      subtitleKeys.map((key) => row[key]?.toString()).toList(),
    );

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        (title != null && title.isNotEmpty) ? title : (fallbackTitle ?? '-'),
      ),
      subtitle: Text(subtitle),
    );
  }

  Widget _buildEmptyState(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency view'),
        actions: [
          if (_hasOfflineSnapshot)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.offline_bolt),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _name ?? 'Unknown',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_hasOfflineSnapshot)
            const Text(
              'Offline emergency snapshot',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          const SizedBox(height: 8),
          _infoRow('DOB', _dob),
          _infoRow('Age', _age),
          _infoRow('Blood type', _bloodType),
          _infoRow('Phone', _phone),
          const SizedBox(height: 12),
          Text(
            'Address: ${_addressSummary ?? '-'}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (_insurancePlan != null || _covidVaccineType != null) ...[
            const SizedBox(height: 8),
            _infoRow('Insurance', _insurancePlan),
            _infoRow('COVID vaccine', _covidVaccineType),
          ],
          if (_lastUpdated != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last updated: ${_formatDateTime(_lastUpdated!)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
          _sectionTitle('Allergies'),
          if (_allergies.isEmpty)
            _buildEmptyState('No allergies recorded')
          else
            ..._allergies.map(
                  (row) => _buildMapItem(
                row: row,
                titleKey: 'allergen_name',
                subtitleKeys: const [
                  'reaction',
                  'severity',
                ],
              ),
            ),
          const SizedBox(height: 12),
          _sectionTitle('Medications'),
          if (_medications.isEmpty)
            _buildEmptyState('No medications recorded')
          else
            ..._medications.map(
                  (row) => _buildMapItem(
                row: row,
                titleKey: 'medication_name',
                subtitleKeys: const [
                  'dosage',
                  'frequency',
                  'purpose',
                ],
              ),
            ),
          const SizedBox(height: 12),
          _sectionTitle('Chronic conditions'),
          if (_conditions.isEmpty)
            _buildEmptyState('No chronic conditions recorded')
          else
            ..._conditions.map(
                  (row) => _buildMapItem(
                row: row,
                titleKey: 'condition_name',
                subtitleKeys: const [
                  'diagnosis_date',
                  'diagnosis_place',
                  'follow_up_doctor',
                  'treatment',
                  'notes',
                ],
              ),
            ),
          const SizedBox(height: 12),
          _sectionTitle('Emergency contact'),
          Text(_emergencyContact ?? '-'),
        ],
      ),
    );
  }
}