import 'package:flutter/material.dart';

import '../models/audit_log_model.dart';
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
  List<AuditLogModel> _logs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _formatDateTime(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  Future<void> _load() async {
    final identity = await _patientService.resolveIdentity();
    if (identity == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    _logs = await _audit.fetchLogs(identity.patientId);

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit log')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
          ? const Center(child: Text('No audit logs yet'))
          : ListView.builder(
        itemCount: _logs.length,
        itemBuilder: (context, index) {
          final item = _logs[index];

          return Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: Text('${item.action} • ${item.entityType}'),
              subtitle: Text(
                [
                  if ((item.fieldName ?? '').trim().isNotEmpty)
                    'Field: ${item.fieldName}',
                  if ((item.performedByUserId ?? '').trim().isNotEmpty)
                    'By: ${item.performedByUserId}',
                  'Time: ${_formatDateTime(item.timestamp)}',
                  if ((item.oldValue ?? '').trim().isNotEmpty)
                    'Old: ${item.oldValue}',
                  if ((item.newValue ?? '').trim().isNotEmpty)
                    'New: ${item.newValue}',
                ].join('\n'),
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}