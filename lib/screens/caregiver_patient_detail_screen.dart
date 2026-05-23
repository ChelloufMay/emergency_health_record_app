import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/access_service.dart';

class CaregiverPatientDetailScreen extends StatefulWidget {
  final String? patientId;

  const CaregiverPatientDetailScreen({super.key, this.patientId});

  @override
  State<CaregiverPatientDetailScreen> createState() =>
      _CaregiverPatientDetailScreenState();
}

class _CaregiverPatientDetailScreenState
    extends State<CaregiverPatientDetailScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AccessService _accessService = AccessService();

  bool _loading = true;
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _grant;

  String? _patientId;

  Map<String, dynamic>? _mapFromRpcResult(dynamic result) {
    if (result is List && result.isNotEmpty) {
      return Map<String, dynamic>.from(result.first as Map);
    }
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    return null;
  }

  Future<Map<String, dynamic>?> _loadSummary(String patientId) async {
    try {
      // Try the emergency summary first — it has the richest data set.
      final summaryRows = await _supabase
          .from('patient_emergency_summary')
          .select()
          .eq('patient_id', patientId)
          .limit(1);

      if (summaryRows.isNotEmpty) {
        return Map<String, dynamic>.from(summaryRows.first as Map);
      }
    } catch (_) {
      // Keep going and use the fallback below.
    }

    try {
      // Fallback: read from the enriched profile view directly.
      // This replaces the removed get_patient_dashboard_details RPC.
      final fallback = await _supabase
          .from('patient_profiles_enriched')
          .select(
            'id, first_name, family_name, sex, age_years, blood_type, phone, '
            'address_country, address_governorate, address_city, '
            'emergency_contact_name, emergency_contact_phone',
          )
          .eq('id', patientId)
          .maybeSingle();

      if (fallback == null) return null;
      return Map<String, dynamic>.from(fallback);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _loadGrant(String patientId) async {
    // CHANGED: resolve the active grant through the access service, which now
    // uses the authenticated app user's public.users.id.
    final rows = await _accessService.fetchActiveAccessForPatient(patientId);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final patientId = widget.patientId;

    if (patientId == null || patientId.trim().isEmpty) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final results = await Future.wait([
      _loadSummary(patientId),
      _loadGrant(patientId),
    ]);

    if (!mounted) return;

    setState(() {
      _patientId = patientId;
      _summary = results[0];
      _grant = results[1];
      _loading = false;
    });
  }

  bool get _canEdit => _grant?['permission']?.toString() == 'edit';

  String _value(Map<String, dynamic>? row, String key) {
    final value = row?[key]?.toString().trim();
    return value == null || value.isEmpty ? 'Unknown' : value;
  }

  String _fullAddress(Map<String, dynamic>? row) {
    final parts = [
      row?['address_country']?.toString() ?? '',
      row?['address_governorate']?.toString() ?? '',
      row?['address_city']?.toString() ?? '',
    ].where((e) => e.trim().isNotEmpty).toList();

    return parts.isEmpty ? 'Unknown' : parts.join(' • ');
  }

  void _openSection(String routeName) {
    Navigator.pushNamed(
      context,
      routeName,
      arguments: {
        'patientId': _patientId,
        'canEdit': _canEdit,
        'isEmergencyOnly': false,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient detail'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patientId == null
          ? const Center(child: Text('No patient selected.'))
          : _grant == null
      // CHANGED: show a clear access error when the grant is missing.
          ? const Center(
        child: Text('No active access grant found for this patient.'),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // CHANGED: the top card now reflects the active grant + the
          // loaded patient summary in one place.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      summary?['first_name']?.toString() ?? '',
                      summary?['family_name']?.toString() ?? '',
                    ].join(' ').trim().isEmpty
                        ? 'Patient'
                        : [
                      summary?['first_name']?.toString() ?? '',
                      summary?['family_name']?.toString() ?? '',
                    ].join(' ').trim(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Patient ID: $_patientId'),
                  Text('Age: ${_value(summary, 'age_years')}'),
                  Text('Sex: ${_value(summary, 'sex')}'),
                  Text('Blood type: ${_value(summary, 'blood_type')}'),
                  Text('Phone: ${_value(summary, 'phone')}'),
                  Text(
                    'Emergency contact: ${_value(summary, 'emergency_contact_name')}',
                  ),
                  Text(
                    'Emergency phone: ${_value(summary, 'emergency_contact_phone')}',
                  ),
                  Text('Address: ${_fullAddress(summary)}'),
                  Text(
                    'Permission: ${_grant?['permission']?.toString() ?? 'none'}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => _openSection('/medical_summary'),
                child: const Text('Open summary'),
              ),
              OutlinedButton(
                onPressed: () => _openSection('/allergies'),
                child: const Text('Allergies'),
              ),
              OutlinedButton(
                onPressed: () => _openSection('/medications'),
                child: const Text('Medications'),
              ),
              OutlinedButton(
                onPressed: () => _openSection('/conditions'),
                child: const Text('Conditions'),
              ),
              OutlinedButton(
                onPressed: () => _openSection('/vaccinations'),
                child: const Text('Vaccinations'),
              ),
              if (_canEdit)
                OutlinedButton(
                  onPressed: () => _openSection('/attachments'),
                  child: const Text('Attachments'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
