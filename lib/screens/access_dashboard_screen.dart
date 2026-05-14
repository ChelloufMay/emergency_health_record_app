import 'package:flutter/material.dart';
import '../services/access_service.dart';
import '../services/patient_session_service.dart';

class AccessDashboardScreen extends StatefulWidget {
  const AccessDashboardScreen({super.key});

  @override
  State<AccessDashboardScreen> createState() => _AccessDashboardScreenState();
}

class _AccessDashboardScreenState extends State<AccessDashboardScreen> {
  final AccessService _accessService = AccessService();

  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await _accessService.fetchMyAccessDashboardRows();
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  Map<String, List<Map<String, dynamic>>> _groupRowsByPatient() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final row in _rows) {
      final patientId = row['patient_id']?.toString();
      if (patientId == null || patientId.isEmpty) continue;
      grouped.putIfAbsent(patientId, () => []).add(row);
    }
    return grouped;
  }

  void _openPatient(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return;
    final first = rows.first;
    final patientId = first['patient_id']?.toString();
    if (patientId == null || patientId.isEmpty) return;

    final patientName = [
      first['first_name']?.toString() ?? '',
      first['family_name']?.toString() ?? '',
    ].join(' ').trim();

    final permission = first['permission']?.toString();

    PatientSessionService.instance.setSession(
      patientId: patientId,
      patientName: patientName.isEmpty ? null : patientName,
      permission: permission,
    );

    final isEmergencyOnly = (permission ?? '').toLowerCase() == 'emergency_only';
    Navigator.pushNamedAndRemoveUntil(
      context,
      isEmergencyOnly ? '/emergency' : '/home',
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupRowsByPatient();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access dashboard'),
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
          : grouped.isEmpty
          ? const Center(
        child: Text('No active patient access yet.'),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: grouped.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final patientId = grouped.keys.elementAt(index);
          final rows = grouped[patientId] ?? const [];
          final first = rows.first;
          final name = [
            first['first_name']?.toString() ?? '',
            first['family_name']?.toString() ?? '',
          ].join(' ').trim();

          final permissions = rows
              .map((r) => r['permission']?.toString() ?? '-')
              .toSet()
              .join(', ');
          final statuses = rows
              .map((r) => r['status']?.toString() ?? '-')
              .toSet()
              .join(', ');

          return Card(
            child: InkWell(
              onTap: () => _openPatient(rows),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name.isEmpty ? 'Unknown patient' : name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Patient ID: $patientId'),
                    const SizedBox(height: 4),
                    Text('Permissions: $permissions'),
                    const SizedBox(height: 4),
                    Text('Statuses: $statuses'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: rows.map((row) {
                        return Chip(
                          label: Text(
                            '${row['grantee_role'] ?? '-'} • ${row['permission'] ?? '-'}',
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: () => _openPatient(rows),
                        child: const Text('Open'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}