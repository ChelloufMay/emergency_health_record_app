import 'package:flutter/material.dart';

import '../models/audit_log_model.dart';
import '../services/audit_service.dart';
import '../services/patient_session_service.dart';

class AuditLogScreen extends StatefulWidget {
  final String? patientId;
  final bool canEdit;
  final bool isEmergencyOnly;

  const AuditLogScreen({
    super.key,
    this.patientId,
    this.canEdit = false,
    this.isEmergencyOnly = false,
  });

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final AuditService _auditService = AuditService();

  bool _loading = true;
  String? _patientId;
  List<AuditLogModel> _logs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? _resolvePatientId() {
    return widget.patientId ?? PatientSessionService.instance.current?.patientId;
  }

  Future<void> _load() async {
    final patientId = _resolvePatientId();
    if (patientId == null || patientId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _patientId = null;
        _logs = [];
      });
      return;
    }

    final logs = await _auditService.fetchLogs(patientId);
    if (!mounted) return;
    setState(() {
      _patientId = patientId;
      _logs = logs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit log'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patientId == null
          ? const Center(child: Text('No patient selected.'))
          : _logs.isEmpty
          ? const Center(child: Text('No audit entries yet.'))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _logs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final log = _logs[index];
          return Card(
            child: ListTile(
              title: Text('${log.action} • ${log.entityType}'),
              subtitle: Text(
                [
                  if (log.fieldName != null) 'Field: ${log.fieldName}',
                  if (log.oldValue != null) 'Old: ${log.oldValue}',
                  if (log.newValue != null) 'New: ${log.newValue}',
                  if (log.breakGlassReason != null) 'Reason: ${log.breakGlassReason}',
                  if (log.timestamp != null) 'At: ${log.timestamp}',
                ].join('\n'),
              ),
              trailing: log.action == 'break_glass'
                  ? const Icon(Icons.warning_amber, color: Colors.orange)
                  : null,
            ),
          );
        },
      ),
    );
  }
}