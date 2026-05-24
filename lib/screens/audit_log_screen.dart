import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/audit_log_model.dart';
import '../services/audit_service.dart';
import '../services/patient_session_service.dart';
import '../utils/patient_access_context.dart';
import '../utils/section_screen_access.dart';

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
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _patientId;
  List<AuditLogModel> _logs = [];
  final Map<String, String> _userLabels = {};
  late SectionScreenAccess _access;

  String? _resolvePatientId() {
    return widget.patientId ?? PatientSessionService.instance.current?.patientId;
  }

  @override
  void initState() {
    super.initState();

    PatientAccessContext.instance.addListener(_rebuildOnPermissionChange);

    _access = SectionScreenAccess(
      widgetCanEdit: widget.canEdit,
      widgetIsEmergencyOnly: widget.isEmergencyOnly,
    );

    _load();
  }

  void _rebuildOnPermissionChange() {
    if (!mounted) return;
    setState(() {
      _access = SectionScreenAccess(
        widgetCanEdit: widget.canEdit,
        widgetIsEmergencyOnly: widget.isEmergencyOnly,
      );
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

    final logs = await _auditService.getRankedAuditLogsForPatient(patientId);

    await _loadUserLabels(logs);

    if (!mounted) return;
    setState(() {
      _patientId = patientId;
      _logs = logs;
      _loading = false;
    });
  }

  Future<void> _loadUserLabels(List<AuditLogModel> logs) async {
    final ids = logs
        .map((log) => log.performedByUserId)
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    if (ids.isEmpty) return;

    try {
      final rows = await _supabase
          .from('users')
          .select('id, email, full_name')
          .inFilter('id', ids);

      _userLabels.clear();

      for (final row in rows as List<dynamic>) {
        final map = row as Map<String, dynamic>;
        final id = map['id']?.toString();
        if (id == null || id.isEmpty) continue;

        final email = map['email']?.toString();
        final fullName = map['full_name']?.toString();

        final label = <String>[
          if (fullName != null && fullName.trim().isNotEmpty) fullName.trim(),
          if (email != null && email.trim().isNotEmpty) '<$email>',
        ].join(' ');

        _userLabels[id] = label.isEmpty ? 'Unknown user' : label;
      }
    } catch (e) {
      debugPrint('Could not load user labels: $e');
    }
  }

  String _prettyAction(AuditLogModel log) {
    final action = log.action.trim().toLowerCase();
    final entity = log.entityType.trim().replaceAll('_', ' ');
    final field = (log.fieldName ?? '').trim().replaceAll('_', ' ');
    final actionLabel = switch (action) {
      'create' => 'Created',
      'update' => 'Updated',
      'delete' => 'Deleted',
      'view' => 'Viewed',
      'break_glass' => 'Emergency access used',
      _ => action.isEmpty ? 'Action' : action[0].toUpperCase() + action.substring(1),
    };

    final entityLabel = entity.isEmpty
        ? ''
        : entity[0].toUpperCase() + entity.substring(1);

    final fieldLabel = field.isEmpty
        ? ''
        : ' • Field: ${field[0].toUpperCase()}${field.substring(1)}';

    return entityLabel.isEmpty
        ? '$actionLabel$fieldLabel'
        : '$actionLabel $entityLabel$fieldLabel';
  }

  String _prettyWhere(AuditLogModel log) {
    final entity = log.entityType.trim().replaceAll('_', ' ');
    if (entity.isEmpty) return 'Unknown';
    return entity[0].toUpperCase() + entity.substring(1);
  }

  String _prettyWho(AuditLogModel log) {
    final id = log.performedByUserId?.trim();
    if (id == null || id.isEmpty) return 'System';
    return _userLabels[id] ?? 'Unknown user';
  }

  String _prettyWhen(DateTime? dt) {
    if (dt == null) return 'Unknown';
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$hour:$minute on $month/$day/${dt.year}';
  }

  String _statusFor(AuditLogModel log) {
    return 'Recorded';
  }

  Widget _rowLabel(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text.rich(
        TextSpan(
          text: '$label ',
          style: const TextStyle(fontWeight: FontWeight.w700),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actions performed'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _access.isEmergencyOnly
          ? const Center(child: Text('Access restricted.'))
          : _patientId == null
          ? const Center(child: Text('No patient selected.'))
          : _logs.isEmpty
          ? const Center(child: Text('No actions performed found.'))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _logs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final log = _logs[index];
          final reason = (log.breakGlassReason ?? '').trim();

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _prettyAction(log),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  _rowLabel(context, 'Where performed:', _prettyWhere(log)),
                  _rowLabel(context, 'Who performed it:', _prettyWho(log)),
                  _rowLabel(context, 'Status:', _statusFor(log)),
                  _rowLabel(context, 'When performed:', _prettyWhen(log.timestamp)),
                  if (reason.isNotEmpty)
                    _rowLabel(context, 'Reason:', reason),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}