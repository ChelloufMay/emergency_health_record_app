import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];

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
    final userId = await _currentAppUserId();
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    // patient_access_dashboard already merges the access row with the summary.
    // This is the right list for caregiver/guardian/clinician style dashboards.
    final rows = await _supabase
        .from('patient_access_dashboard')
        .select()
        .eq('grantee_user_id', userId)
        .order('granted_at', ascending: false);

    if (!mounted) return;
    setState(() {
      _rows = rows.cast<Map<String, dynamic>>();
      _loading = false;
    });
  }

  void _openPatient(String patientId) {
    Navigator.pushNamed(
      context,
      '/caregiver_patient_detail',
      arguments: {'patientId': patientId},
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, Map<String, dynamic>>{};

    for (final row in _rows) {
      final patientId = row['patient_id']?.toString();
      if (patientId == null || patientId.isEmpty) continue;
      grouped.putIfAbsent(patientId, () => row);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caregiver dashboard'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : grouped.isEmpty
          ? const Center(child: Text('No accessible patients yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: grouped.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = grouped.entries.elementAt(index);
                final row = entry.value;

                final name = [
                  row['first_name']?.toString() ?? '',
                  row['family_name']?.toString() ?? '',
                ].join(' ').trim();

                return Card(
                  child: ListTile(
                    title: Text(name.isEmpty ? 'Unnamed patient' : name),
                    subtitle: Text(
                      [
                        'Age: ${row['age_years']?.toString() ?? 'Unknown'}',
                        'Sex: ${row['sex']?.toString() ?? 'Unknown'}',
                        'Blood type: ${row['blood_type']?.toString() ?? 'Unknown'}',
                        'Permission: ${row['permission']?.toString() ?? 'Unknown'}',
                        'Status: ${row['status']?.toString() ?? 'Unknown'}',
                        'Granted at: ${row['granted_at']?.toString() ?? 'Unknown'}',
                      ].join('\n'),
                    ),
                    onTap: () => _openPatient(entry.key),
                  ),
                );
              },
            ),
    );
  }
}
