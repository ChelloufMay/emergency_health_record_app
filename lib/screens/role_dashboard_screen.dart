import 'package:flutter/material.dart';

import '../models/patient_access_row_model.dart';
import '../services/access_service.dart';
import '../services/auth_service.dart';
import '../services/patient_session_service.dart';
import 'patient_detail_screen.dart';

class RoleDashboardScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String emptyMessage;

  const RoleDashboardScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emptyMessage,
  });

  @override
  State<RoleDashboardScreen> createState() => _RoleDashboardScreenState();
}

class _RoleDashboardScreenState extends State<RoleDashboardScreen> {
  final AccessService _service = AccessService();
  final AuthService _authService = AuthService();

  bool _loading = true;
  List<PatientAccessRowModel> _rows = [];
  List<Map<String, dynamic>> _pendingInvites = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _loading = true);

    try {
      final rows = await _service.fetchMyAccessDashboardRows();

      // CHANGED: load invite rows from the patient-aware invite dashboard view.
      final invites = await _service.fetchMyPendingInvitesWithPatientDetails();

      if (!mounted) return;
      setState(() {
        _rows = rows;
        _pendingInvites = invites;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load dashboard: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _openPatient(PatientAccessRowModel row) {
    PatientSessionService.instance.setSession(
      patientId: row.patientId,
      patientName: row.patientName,
      permission: row.permission,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientDetailScreen(
          patientId: row.patientId,
          patientName: row.patientName,
          permission: row.permission,
          roleLabel: row.role,
          grantId: row.grantId ?? '',
        ),
      ),
    );
  }

  void _openInbox() {
    Navigator.pushNamed(context, '/access_inbox');
  }

  Future<void> _confirmRemove(PatientAccessRowModel row) async {
    final grantId = row.grantId;
    if (grantId == null || grantId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing grant id for this patient.')),
      );
      return;
    }

    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove patient'),
          content: Text(
            'Revoke your access to ${row.patientName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true) return;

    try {
      await _service.revokeGrant(grantId);
      if (!mounted) return;
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access removed.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove patient: $e')),
      );
    }
  }

  Widget _patientCard(PatientAccessRowModel row) {
    return Card(
      child: ListTile(
        leading: Icon(
          row.isEmergencyOnly
              ? Icons.warning_amber_outlined
              : row.canEdit
              ? Icons.edit_outlined
              : Icons.visibility_outlined,
        ),
        title: Text(row.patientName),
        subtitle: Text('${row.role} · ${row.permission}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.person_remove_outlined),
              tooltip: 'Remove patient',
              onPressed: () => _confirmRemove(row),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => _openPatient(row),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? BackButton(
          onPressed: () => Navigator.pop(context),
        )
            : null,
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(widget.subtitle),
              ),
            ),
            const SizedBox(height: 16),
            if (_pendingInvites.isNotEmpty) ...[
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.inbox_outlined),
                  title: Text(
                    '${_pendingInvites.length} pending invite(s)',
                  ),
                  subtitle: const Text(
                    'Open the inbox to accept or reject invites.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openInbox,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Accessible patients',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (_rows.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(widget.emptyMessage),
                ),
              )
            else
              ..._rows.map(_patientCard),
          ],
        ),
      ),
    );
  }
}