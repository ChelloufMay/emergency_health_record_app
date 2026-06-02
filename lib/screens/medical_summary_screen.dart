import 'package:flutter/material.dart';

import '../services/patient_service.dart';
import '../services/patient_session_service.dart';
import '../utils/patient_access_context.dart';

// Displays a consolidated medical summary for a patient.
class MedicalSummaryScreen extends StatefulWidget {
  final String? patientId;
  final bool canEdit;
  final bool isEmergencyOnly;

  const MedicalSummaryScreen({
    super.key,
    this.patientId,
    this.canEdit = false,
    this.isEmergencyOnly = false,
  });

  @override
  State<MedicalSummaryScreen> createState() => _MedicalSummaryScreenState();
}

class _MedicalSummaryScreenState extends State<MedicalSummaryScreen> {
  final PatientService _patientService = PatientService();

  bool _loading = true;
  Map<String, dynamic>? _summary;

  String? _resolvePatientId() {
    return widget.patientId ??
        PatientSessionService.instance.current?.patientId;
  }



  @override
  void initState() {
    super.initState();

    PatientAccessContext.instance.addListener(_rebuildOnPermissionChange);


    _load();
  }

  void _rebuildOnPermissionChange() {
    if (!mounted) return;
    setState(() {
    });
  }

  @override
  void dispose() {
    PatientAccessContext.instance.removeListener(_rebuildOnPermissionChange);
    super.dispose();
  }

  Future<void> _load() async {
    final patientId = _resolvePatientId();
    if (patientId == null || patientId.isEmpty) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    // Important: this screen reads the DB view patient_emergency_summary,
    // not separate manual joins. That keeps the UI aligned with the DB view.
    final summary = await _patientService.fetchEmergencySummary(patientId);

    if (!mounted) return;
    setState(() {
      _summary = summary;
      _loading = false;
    });
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return const [];
  }

  String _displayName() {
    final first = _summary?['first_name']?.toString().trim() ?? '';
    final last = _summary?['family_name']?.toString().trim() ?? '';
    return '$first $last'.trim();
  }

  Widget _buildBulletList(dynamic value, {String emptyLabel = 'None'}) {
    final items = _asList(value);
    if (items.isEmpty) {
      return Text(emptyLabel);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        final map = item is Map
            ? Map<String, dynamic>.from(item)
            : <String, dynamic>{};
        final title =
            map['allergen_name'] ??
                map['medication_name'] ??
                map['condition_name'] ??
                item;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text('• $title'),
        );
      }).toList(),
    );
  }

  Widget _section(String title, Widget child) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientId = _resolvePatientId();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical summary'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : patientId == null
          ? const Center(child: Text('No patient selected.'))
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // This is the owner-safe summary view from the DB view
            // patient_emergency_summary.
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName().isEmpty
                          ? 'Patient summary'
                          : _displayName(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Patient ID: $patientId'),
                    Text(
                      'Sex: ${_summary?['sex']?.toString() ?? 'Unknown'}',
                    ),
                    Text(
                      'Age: ${_summary?['age_years']?.toString() ?? 'Unknown'}',
                    ),
                    Text(
                      'Blood type: ${_summary?['blood_type']?.toString() ?? 'Unknown'}',
                    ),
                    Text(
                      'Phone: ${_summary?['phone']?.toString() ?? 'Not set'}',
                    ),
                    Text(
                      'Emergency contact: ${_summary?['emergency_contact_name']?.toString() ?? 'Not set'}',
                    ),
                    Text(
                      'Emergency phone: ${_summary?['emergency_contact_phone']?.toString() ?? 'Not set'}',
                    ),
                    Text(
                      'Insurance: ${_summary?['insurance_plan']?.toString() ?? 'Not set'}',
                    ),
                    Text(
                      'COVID vaccine: ${_summary?['covid_vaccine_type']?.toString() ?? 'Not set'}',
                    ),
                    Text(
                      'Address: ${[_summary?['address_country'], _summary?['address_governorate'], _summary?['address_city']].where((e) => e != null && e.toString().trim().isNotEmpty).join(' • ')}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _section(
              'Allergies',
              _buildBulletList(_summary?['allergies']),
            ),
            const SizedBox(height: 12),
            _section(
              'Medications',
              _buildBulletList(_summary?['medications']),
            ),
            const SizedBox(height: 12),
            _section(
              'Chronic conditions',
              _buildBulletList(_summary?['chronic_conditions']),
            ),

          ],
        ),
      ),
    );
  }
}