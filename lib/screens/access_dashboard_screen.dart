import 'package:flutter/material.dart';

import '../models/access_grant_model.dart';
import '../models/access_invite_model.dart';
import '../services/access_service.dart';
import '../services/patient_session_service.dart';
import 'access_permission_editor_screen.dart';

class AccessDashboardScreen extends StatefulWidget {
  final String? patientId;

  const AccessDashboardScreen({super.key, this.patientId});

  @override
  State<AccessDashboardScreen> createState() => _AccessDashboardScreenState();
}

class _AccessDashboardScreenState extends State<AccessDashboardScreen> {
  final AccessService _accessService = AccessService();

  bool _loading = true;
  List<Map<String, dynamic>> _activeGrantRows = [];
  List<Map<String, dynamic>> _pendingInviteRows = [];
  List<Map<String, dynamic>> _acceptedInviteRows = [];
  List<Map<String, dynamic>> _rejectedInviteRows = [];
  List<Map<String, dynamic>> _revokedInviteRows = [];

  String? _resolvePatientId() {
    return widget.patientId ?? PatientSessionService.instance.current?.patientId;
  }

  String _stringValue(
      Map<String, dynamic> row,
      List<String> keys, {
        String fallback = '',
      }) {
    for (final key in keys) {
      final value = row[key];
      if (value != null) {
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }
    return fallback;
  }

  String _patientNameFromRow(Map<String, dynamic> row) {
    final directName = _stringValue(
      row,
      const ['patient_name', 'full_name', 'name', 'display_name'],
    );
    if (directName.isNotEmpty) return directName;

    final firstName = _stringValue(
      row,
      const ['first_name', 'patient_first_name', 'given_name'],
    );
    final familyName = _stringValue(
      row,
      const ['family_name', 'patient_family_name', 'last_name', 'surname'],
    );

    final fullName = '$firstName $familyName'.trim();
    return fullName.isEmpty ? 'Unknown patient' : fullName;
  }

  String _inviteToken(Map<String, dynamic> row) {
    return _stringValue(
      row,
      const ['invite_token', 'token', 'access_invite_token'],
    );
  }

  String _invitePatientId(Map<String, dynamic> row) {
    return _stringValue(row, const ['patient_id', 'id', 'target_patient_id']);
  }

  String _grantId(Map<String, dynamic> row) {
    return _stringValue(
      row,
      const ['grant_id', 'access_grant_id', 'id'],
    );
  }

  String _granteeRole(Map<String, dynamic> row) {
    return _stringValue(
      row,
      const ['grantee_role', 'role', 'invited_role'],
      fallback: 'unknown',
    );
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);

    try {
      final results = await Future.wait<dynamic>([
        // CHANGED: current grant rows come from the patient-aware dashboard view.
        _accessService.fetchMyActiveGrants(),
        // CHANGED: invite history is split by status so the UI can show each one.
        _accessService.fetchMyPendingInvitesWithPatientDetails(),
        _accessService.fetchMyAcceptedInvitesWithPatientDetails(),
        _accessService.fetchMyRejectedInvitesWithPatientDetails(),
        _accessService.fetchMyRevokedInvitesWithPatientDetails(),
      ]);

      if (!mounted) return;

      setState(() {
        _activeGrantRows = List<Map<String, dynamic>>.from(results[0] as List);
        _pendingInviteRows = List<Map<String, dynamic>>.from(results[1] as List);
        _acceptedInviteRows = List<Map<String, dynamic>>.from(results[2] as List);
        _rejectedInviteRows = List<Map<String, dynamic>>.from(results[3] as List);
        _revokedInviteRows = List<Map<String, dynamic>>.from(results[4] as List);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load access dashboard: $e')),
      );
    }
  }

  Future<void> _openPermissionEditor({
    required Map<String, dynamic> grantRow,
  }) async {
    final grantId = _grantId(grantRow);
    if (grantId.isEmpty) return;

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AccessPermissionEditorScreen(
          grantId: grantId,
          patientId: _stringValue(grantRow, const ['patient_id']),
          granteeRole: _granteeRole(grantRow),
          currentPermission: _stringValue(
            grantRow,
            const ['permission'],
            fallback: 'read',
          ),
          currentExpiresAt: _parseDateTime(
            grantRow['expires_at'] ?? grantRow['expiresAt'],
          ),
          currentNotes: grantRow['notes']?.toString(),
        ),
      ),
    );

    if (changed == true && mounted) {
      await _load();
    }
  }

  Future<void> _revokeGrant(Map<String, dynamic> grantRow) async {
    final grantId = _grantId(grantRow);
    if (grantId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke access'),
        content: const Text(
          'This removes the active grant immediately and the user loses access.',
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

    await _accessService.revokeGrant(grantId);
    if (!mounted) return;
    await _load();
  }

  Future<void> _acceptInviteToken(String token) async {
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing invite token.')),
      );
      return;
    }

    try {
      await _accessService.acceptInvite(token);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite accepted.')),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not accept invite: $e')),
      );
    }
  }

  Future<void> _rejectInviteToken(String token) async {
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing invite token.')),
      );
      return;
    }

    try {
      await _accessService.rejectInvite(token);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite rejected.')),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not reject invite: $e')),
      );
    }
  }

  Future<void> _showPatientSheet(String patientId, {String? title}) async {
    final grantsFuture = _accessService.fetchPatientGrants(patientId);
    final invitesFuture = _accessService.fetchPatientInvites(patientId);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return FutureBuilder<List<Object?>>(
              future: Future.wait<Object?>([grantsFuture, invitesFuture]),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Could not load details: ${snapshot.error}'),
                  );
                }

                final data = snapshot.data ?? const <Object?>[];
                final grants = data.isNotEmpty
                    ? (data[0] as List<AccessGrantModel>)
                    : <AccessGrantModel>[];
                final invites = data.length > 1
                    ? (data[1] as List<AccessInviteModel>)
                    : <AccessInviteModel>[];

                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      title ?? 'Patient access',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Patient ID: $patientId'),
                    const SizedBox(height: 16),
                    const Text(
                      'Active grants',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (grants.isEmpty)
                      const Text('No active grants')
                    else
                      ...grants.map(
                            (grant) => Card(
                          child: ListTile(
                            title: Text('${grant.granteeRole} • ${grant.permission}'),
                            subtitle: Text(
                              'Status: ${grant.status} • Expires: ${grant.expiresAt?.toIso8601String() ?? 'Never'}',
                            ),
                            trailing: Wrap(
                              spacing: 6,
                              children: [
                                IconButton(
                                  onPressed: grant.id == null
                                      ? null
                                      : () => _openPermissionEditor(
                                    grantRow: {
                                      'id': grant.id,
                                      'patient_id': grant.patientId,
                                      'grantee_role': grant.granteeRole,
                                      'permission': grant.permission,
                                      'expires_at': grant.expiresAt?.toIso8601String(),
                                      'notes': grant.notes,
                                    },
                                  ),
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Change permission',
                                ),
                                IconButton(
                                  onPressed: grant.id == null
                                      ? null
                                      : () => _revokeGrant(
                                    {
                                      'id': grant.id,
                                      'patient_id': grant.patientId,
                                      'grantee_role': grant.granteeRole,
                                      'permission': grant.permission,
                                    },
                                  ),
                                  icon: const Icon(Icons.block),
                                  tooltip: 'Revoke grant',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Invites',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (invites.isEmpty)
                      const Text('No invites')
                    else
                      ...invites.map(
                            (invite) => Card(
                          child: ListTile(
                            title: Text(
                              _patientNameFromRow({
                                'patient_name':
                                invite.patientId, // fallback if the model has no name field
                              }),
                            ),
                            subtitle: Text(
                              'Email: ${invite.invitedEmail}\n'
                                  'Role: ${invite.invitedRole}\n'
                                  'Permission: ${invite.permission}\n'
                                  'Status: ${invite.status}',
                            ),
                            isThreeLine: true,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildInviteSection({
    required String title,
    required List<Map<String, dynamic>> rows,
    required String emptyMessage,
    bool showActions = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(emptyMessage),
            ),
          )
        else
          ...rows.map((invite) {
            final token = _inviteToken(invite);
            final patientName = _patientNameFromRow(invite);
            final invitedRole =
            _stringValue(invite, const ['invited_role', 'role'], fallback: 'Unknown role');
            final permission =
            _stringValue(invite, const ['permission'], fallback: 'Unknown permission');
            final status =
            _stringValue(invite, const ['status'], fallback: 'pending');
            final invitedEmail =
            _stringValue(invite, const ['invited_email', 'email'], fallback: 'Unknown email');
            final message =
            _stringValue(invite, const ['message', 'notes', 'invite_message']);

            return Card(
              child: ListTile(
                title: Text(patientName),
                subtitle: Text(
                  'Role: $invitedRole\n'
                      'Permission: $permission\n'
                      'Email: $invitedEmail\n'
                      'Status: $status'
                      '${message.isNotEmpty ? '\nMessage: $message' : ''}',
                ),
                isThreeLine: message.isEmpty,
                onTap: _invitePatientId(invite).isEmpty
                    ? null
                    : () => _showPatientSheet(
                  _invitePatientId(invite),
                  title: patientName,
                ),
                trailing: showActions && status == 'pending'
                    ? Wrap(
                  spacing: 6,
                  children: [
                    IconButton(
                      onPressed: token.isEmpty
                          ? null
                          : () => _acceptInviteToken(token),
                      icon: const Icon(Icons.check),
                      tooltip: 'Accept invite',
                    ),
                    IconButton(
                      onPressed: token.isEmpty
                          ? null
                          : () => _rejectInviteToken(token),
                      icon: const Icon(Icons.close),
                      tooltip: 'Reject invite',
                    ),
                  ],
                )
                    : null,
              ),
            );
          }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildGrantSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active grants',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (_activeGrantRows.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No active access found.',
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            ),
          )
        else
          ..._activeGrantRows.map((grant) {
            final patientId = _stringValue(grant, const ['patient_id']);
            final patientName = _patientNameFromRow(grant);
            final permission = _stringValue(
              grant,
              const ['permission'],
              fallback: 'read',
            );
            final status = _stringValue(
              grant,
              const ['status'],
              fallback: 'active',
            );
            final grantId = _grantId(grant);
            final expiresAt = grant['expires_at']?.toString().trim() ??
                grant['expiresAt']?.toString().trim() ??
                'Never';

            return Card(
              child: ListTile(
                leading: Icon(
                  permission == 'edit'
                      ? Icons.edit_outlined
                      : permission == 'emergency_only'
                      ? Icons.warning_amber_outlined
                      : Icons.visibility_outlined,
                ),
                title: Text(patientName),
                subtitle: Text(
                  'Permission: $permission • Status: $status • Expires: $expiresAt',
                ),
                trailing: Wrap(
                  spacing: 6,
                  children: [
                    IconButton(
                      onPressed: grantId.isEmpty
                          ? null
                          : () => _openPermissionEditor(grantRow: grant),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit permission',
                    ),
                    IconButton(
                      onPressed: grantId.isEmpty ? null : () => _revokeGrant(grant),
                      icon: const Icon(Icons.block),
                      tooltip: 'Revoke grant',
                    ),
                  ],
                ),
                onTap: patientId.isEmpty
                    ? null
                    : () => _showPatientSheet(patientId, title: patientName),
              ),
            );
          }),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientId = _resolvePatientId();

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
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (patientId != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Focused patient',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text('Patient ID: $patientId'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => _showPatientSheet(patientId),
                        child: const Text('Open access details'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            _buildInviteSection(
              title: 'Pending invites',
              rows: _pendingInviteRows,
              emptyMessage: 'No pending invites.',
              showActions: true,
            ),
            _buildInviteSection(
              title: 'Accepted invites',
              rows: _acceptedInviteRows,
              emptyMessage: 'No accepted invites yet.',
            ),
            _buildInviteSection(
              title: 'Rejected invites',
              rows: _rejectedInviteRows,
              emptyMessage: 'No rejected invites yet.',
            ),
            _buildInviteSection(
              title: 'Revoked invites',
              rows: _revokedInviteRows,
              emptyMessage: 'No revoked invites yet.',
            ),
            _buildGrantSection(),
          ],
        ),
      ),
    );
  }
}