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
  final AuditService _auditService = AuditService.instance;

  bool _loading = true;
  String? _patientId;
  List<AuditLogModel> _logs = [];

  String? _resolvePatientId() {
    return widget.patientId ??
        PatientSessionService.instance.current?.patientId;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final patientId = _resolvePatientId();
    if (patientId == null || patientId.isEmpty) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    // This uses the ranked audit view so the newest rows are already ordered
    // correctly at the DB layer.
    final logs = await _auditService.getRankedAuditLogsForPatient(patientId);

    if (!mounted) return;
    setState(() {
      _patientId = patientId;
      _logs = logs;
      _loading = false;
    });
  }

  String _summary(AuditLogModel log) {
    final action = log.action;
    final entity = log.entityType;
    final field = log.fieldName;
    final newValue = log.newValue;

    final parts = <String>[
      action,
      entity,
      if ((field ?? '').trim().isNotEmpty) field!,
      if ((newValue ?? '').trim().isNotEmpty) '→ $newValue',
    ];

    return parts.where((e) => e.trim().isNotEmpty).join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit log'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patientId == null
          ? const Center(child: Text('No patient selected.'))
          : _logs.isEmpty
          ? const Center(child: Text('No audit logs found.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Card(
                  child: ListTile(
                    title: Text(_summary(log)),
                    subtitle: Text(
                      [
                        'When: ${log.timestamp?.toIso8601String() ?? 'Unknown'}',
                        'Performed by: ${log.performedByUserId ?? 'System'}',
                        if ((log.breakGlassReason ?? '').trim().isNotEmpty)
                          'Reason: ${log.breakGlassReason}',
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
