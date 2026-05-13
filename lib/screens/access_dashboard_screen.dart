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
    final rows = await _accessService.fetchMyAccessDashboardRows();
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  void _openPatient(Map<String, dynamic> row) {
    final patientId = row['patient_id']?.toString();
    if (patientId == null || patientId.isEmpty) return;

    PatientSessionService.instance.setSession(
      patientId: patientId,
      patientName: '${row['first_name'] ?? ''} ${row['family_name'] ?? ''}'.trim(),
      permission: row['permission']?.toString(),
    );

    Navigator.pushNamed(context, '/emergency');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access dashboard'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
          ? const Center(child: Text('No active patient access yet'))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final row = _rows[index];
          final name = '${row['first_name'] ?? ''} ${row['family_name'] ?? ''}'.trim();
          final permission = row['permission']?.toString() ?? '-';
          final status = row['status']?.toString() ?? '-';

          return Card(
            child: ListTile(
              title: Text(name.isEmpty ? 'Unknown patient' : name),
              subtitle: Text(
                'Role: ${row['grantee_role'] ?? '-'}\n'
                    'Permission: $permission\n'
                    'Status: $status',
              ),
              trailing: ElevatedButton(
                onPressed: () => _openPatient(row),
                child: const Text('Open'),
              ),
            ),
          );
        },
      ),
    );
  }
}