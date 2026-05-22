import 'dart:async';

import 'package:flutter/material.dart';

import '../models/access_grant_view_model.dart';
import '../models/access_invite_model.dart';
import '../services/access_realtime_service.dart';
import '../services/access_service.dart';
import '../services/patient_service.dart';
import '../services/patient_session_service.dart';
import '../widgets/access_grant_card.dart';
import 'access_permission_editor_screen.dart';

/// Patient-owner screen: manage grants and outbound invites for one patient.
///
/// Recipients accept/reject on [AccessInboxScreen] instead.
class PatientAccessManagementScreen extends StatefulWidget {
  final String? patientId;

  /// When true, renders body only (for [AccessCenterScreen] tabs).
  final bool embedded;

  const PatientAccessManagementScreen({
    super.key,
    this.patientId,
    this.embedded = false,
  });

  @override
  State<PatientAccessManagementScreen> createState() =>
      _PatientAccessManagementScreenState();
}

class _PatientAccessManagementScreenState
    extends State<PatientAccessManagementScreen> {
  final AccessService _accessService = AccessService();
  final PatientService _patientService = PatientService();
  StreamSubscription<void>? _realtimeSub;

  bool _loading = true;
  String? _patientId;
  String? _patientName;
  List<AccessGrantViewModel> _grants = [];
  List<AccessInviteModel> _invites = [];

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    AccessRealtimeService.instance.subscribe();
    _realtimeSub = AccessRealtimeService.instance.onChanged.listen((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    AccessRealtimeService.instance.unsubscribe();
    super.dispose();
  }

  Future<String?> _resolvePatientId() async {
    if (widget.patientId != null && widget.patientId!.trim().isNotEmpty) {
      return widget.patientId!.trim();
    }
    final session = PatientSessionService.instance.current;
    if (session?.patientId.isNotEmpty == true) return session!.patientId;
    final identity = await _patientService.resolveIdentity();
    return identity?.patientProfileId;
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);

    try {
      final patientId = await _resolvePatientId();
      if (patientId == null || patientId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _patientId = null;
        });
        return;
      }

      final summary = await _patientService.fetchPatientSummary(patientId);
      final grants = await _accessService.fetchPatientGrantViews(patientId);
      final invites = await _accessService.fetchPatientInvites(patientId);

      if (!mounted) return;
      setState(() {
        _patientId = patientId;
        _patientName = summary == null
            ? PatientSessionService.instance.current?.patientName
            : [
                summary['first_name']?.toString() ?? '',
                summary['family_name']?.toString() ?? '',
              ].join(' ').trim();
        _grants = grants;
        _invites = invites;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load access management: $e')),
      );
    }
  }

  Future<void> _showInviteDialog() async {
    final emailController = TextEditingController();
    final notesController = TextEditingController();
    String invitedRole = 'caregiver';
    String permission = 'read';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Invite access'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: invitedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(
                      value: 'caregiver',
                      child: Text('Caregiver'),
                    ),
                    DropdownMenuItem(
                      value: 'guardian',
                      child: Text('Guardian'),
                    ),
                    DropdownMenuItem(
                      value: 'clinician',
                      child: Text('Clinician'),
                    ),
                  ],
                  onChanged: (v) => invitedRole = v ?? 'caregiver',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: permission,
                  decoration: const InputDecoration(labelText: 'Permission'),
                  items: const [
                    DropdownMenuItem(value: 'read', child: Text('Read')),
                    DropdownMenuItem(value: 'edit', child: Text('Edit')),
                    DropdownMenuItem(
                      value: 'emergency_only',
                      child: Text('Emergency only'),
                    ),
                  ],
                  onChanged: (v) => permission = v ?? 'read',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Message / notes'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Send invite'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      emailController.dispose();
      notesController.dispose();
      return;
    }

    final patientId = _patientId;
    if (patientId == null) return;

    try {
      await _accessService.createInvite(
        patientId: patientId,
        invitedEmail: emailController.text.trim(),
        invitedRole: invitedRole,
        permission: permission,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite sent.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invite failed: $e')),
      );
    } finally {
      emailController.dispose();
      notesController.dispose();
    }
  }

  Future<void> _openPermissionEditor(AccessGrantViewModel grant) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AccessPermissionEditorScreen(
          grantId: grant.grantId,
          patientId: grant.patientId,
          granteeRole: grant.granteeRole,
          currentPermission: grant.permission,
          currentExpiresAt: grant.expiresAt,
          currentNotes: grant.notes,
        ),
      ),
    );

    if (changed == true && mounted) await _load();
  }

  Future<void> _revokeGrant(AccessGrantViewModel grant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke access'),
        content: const Text(
          'This removes the active grant immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _accessService.revokeGrant(
        grant.grantId,
        patientId: grant.patientId,
      );
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Revoke failed: $e')),
      );
    }
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_patientId == null) {
      return const Center(child: Text('No patient selected.'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(_patientName ?? 'Patient'),
              subtitle: Text('Patient ID: $_patientId'),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage who can access this patient record. Permission '
            'changes apply to caregivers, guardians, and clinicians.',
          ),
          const SizedBox(height: 16),
          Text(
            'Active grants',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (_grants.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No active grants.'),
              ),
            )
          else
            ..._grants.map(
              (grant) => AccessGrantCard(
                grant: grant,
                canManage: true,
                onEditPermission: () => _openPermissionEditor(grant),
                onRevoke: () => _revokeGrant(grant),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Outbound invites',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (_invites.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No invites sent yet.'),
              ),
            )
          else
            ..._invites.map(
              (invite) => Card(
                child: ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: Text(
                    '${invite.invitedRole} • ${invite.permission}',
                  ),
                  subtitle: Text(
                    'Email: ${invite.invitedEmail}\n'
                    'Status: ${invite.status}',
                  ),
                  isThreeLine: true,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Stack(
        children: [
          _buildBody(),
          if (_patientId != null)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: _showInviteDialog,
                child: const Icon(Icons.person_add),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access management'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: _patientId == null
          ? null
          : FloatingActionButton(
              onPressed: _showInviteDialog,
              tooltip: 'Invite someone',
              child: const Icon(Icons.person_add),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }
}
