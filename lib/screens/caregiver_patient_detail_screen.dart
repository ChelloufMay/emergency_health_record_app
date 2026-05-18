import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  bool _loading = true;
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _grant;

  String? _patientId;

  Future<String?> _currentAppUserId() async {
    final value = await _supabase.rpc('current_app_user_id');
    return value?.toString();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final patientId = widget.patientId;
    final userId = await _currentAppUserId();

    if (patientId == null ||
        patientId.isEmpty ||
        userId == null ||
        userId.isEmpty) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    // The summary comes from the DB view patient_emergency_summary.
    // The permission row comes from access_grants so the UI can decide
    // whether edit navigation is allowed.
    final summaryRows = await _supabase
        .from('patient_emergency_summary')
        .select()
        .eq('patient_id', patientId)
        .limit(1);

    final grantRows = await _supabase
        .from('access_grants')
        .select()
        .eq('patient_id', patientId)
        .eq('grantee_user_id', userId)
        .eq('status', 'active')
        .limit(1);

    if (!mounted) return;
    setState(() {
      _patientId = patientId;
      _summary = (summaryRows.isNotEmpty)
          ? Map<String, dynamic>.from(summaryRows.first as Map)
          : null;
      _grant = (grantRows.isNotEmpty)
          ? Map<String, dynamic>.from(grantRows.first as Map)
          : null;
      _loading = false;
    });
  }

  bool get _canEdit => _grant?['permission']?.toString() == 'edit';

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
          : summary == null
          ? const Center(child: Text('No patient summary available.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // This screen uses the access row + emergency summary together.
                // That keeps caregiver/clinician/guardian detail views aligned
                // with the same DB rules as the owner flow.
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            summary['first_name']?.toString() ?? '',
                            summary['family_name']?.toString() ?? '',
                          ].join(' ').trim(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Patient ID: $_patientId'),
                        Text(
                          'Age: ${summary['age_years']?.toString() ?? 'Unknown'}',
                        ),
                        Text('Sex: ${summary['sex']?.toString() ?? 'Unknown'}'),
                        Text(
                          'Blood type: ${summary['blood_type']?.toString() ?? 'Unknown'}',
                        ),
                        Text(
                          'Phone: ${summary['phone']?.toString() ?? 'Unknown'}',
                        ),
                        Text(
                          'Emergency contact: ${summary['emergency_contact_name']?.toString() ?? 'Unknown'}',
                        ),
                        Text(
                          'Emergency phone: ${summary['emergency_contact_phone']?.toString() ?? 'Unknown'}',
                        ),
                        Text(
                          'Address: ${[summary['address_country']?.toString() ?? '', summary['address_governorate']?.toString() ?? '', summary['address_city']?.toString() ?? ''].where((e) => e.trim().isNotEmpty).join(' • ')}',
                        ),
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
