import 'package:flutter/material.dart';
import '../services/audit_service.dart';
import '../services/patient_service.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final _audit = AuditService();
  final _patientService = PatientService();

  bool _loading = true;
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final identity = await _patientService.resolveIdentity();
    if (identity == null) {
      setState(() => _loading = false);
      return;
    }

    _logs = await _audit.fetchLogs(identity.patientId);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit log')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _logs.length,
        itemBuilder: (context, index) {
          final item = _logs[index];
          return Card(
            child: ListTile(
              title: Text('${item['action']} • ${item['entity_type']}'),
              subtitle: Text(
                '${item['field_name'] ?? ''}\n${item['timestamp'] ?? ''}',
              ),
            ),
          );
        },
      ),
    );
  }
}