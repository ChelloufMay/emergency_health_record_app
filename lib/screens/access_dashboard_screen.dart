import 'package:flutter/material.dart';

import '../models/access_grant_model.dart';
import '../models/access_invite_model.dart';
import '../services/access_service.dart';
import '../services/patient_service.dart';
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
  final PatientService _patientService = PatientService();

  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _pendingInviteRows = [];
  String? _myEmail;

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final results = await Future.wait<dynamic>([
        _accessService.fetchMyAccessDashboardRowMaps(),
        _accessService.fetchMyPendingInvitesWithPatientDetails(),
        _patientService.fetchCurrentAppUserRow(),
      ]);

      final rows = List<Map<String, dynamic>>.from(results[0] as List);
      final pendingInvites =
      List<Map<String, dynamic>>.from(results[1] as List);
      final myUserRow = results[2] is Map
          ? Map<String, dynamic>.from(results[2] as Map)
          : null;

      if (!mounted) return;
      setState(() {
        _rows = rows;
        _pendingInviteRows = pendingInvites;
        _myEmail = myUserRow?['email']?.toString().trim().toLowerCase();
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

  Map<String, List<Map<String, dynamic>>> _groupRowsByPatient() {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final row in _rows) {
      final patientId = row['patient_id']?.toString();
      if (patientId == null || patientId.isEmpty) continue;
      grouped.putIfAbsent(patientId, () => []).add(row);
    }

    return grouped;
  }

  Future<void> _openPermissionEditor({
    required String grantId,
    required String patientId,
    required String granteeRole,
    required String currentPermission,
  }) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AccessPermissionEditorScreen(
          grantId: grantId,
          patientId: patientId,
          granteeRole: granteeRole,
          currentPermission: currentPermission,
        ),
      ),
    );

    if (changed == true && mounted) {
      await _load();
    }
  }

  Future<void> _revokeGrant(String grantId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke access'),
        content: const Text(
          'This will remove the active grant and the user will lose access immediately.',
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
      final result = await _accessService.acceptInvite(token);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite accepted.')),
      );

      await _load();

      String? patientId;
      if (result is Map) {
        final map = Map<String, dynamic>.from(result);
        patientId = map['patient_id']?.toString();
      } else if (result != null) {
        final text = result.toString().trim();
        if (text.isNotEmpty && text != 'null') {
          patientId = text;
        }
      }

      if (patientId != null && patientId.isNotEmpty) {
        final matchedRow = _rows.where(
              (row) => row['patient_id']?.toString() == patientId,
        );

        if (matchedRow.isNotEmpty) {
          await _showPatientSheet(
            patientId,
            title: _patientNameFromRow(matchedRow.first),
          );
        }
      }
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

  Widget _grantCard({
    required AccessGrantModel grant,
    required String patientId,
    required bool showActions,
  }) {
    final grantId = grant.id ?? '';
    final canEditGrant = grantId.isNotEmpty;

    return Card(
      child: ListTile(
        title: Text('${grant.granteeRole} • ${grant.permission}'),
        subtitle: Text(
          'Status: ${grant.status} • Expires: ${grant.expiresAt?.toIso8601String() ?? 'Never'}',
        ),
        trailing: showActions
            ? Wrap(
          spacing: 6,
          children: [
            IconButton(
              onPressed: !canEditGrant
                  ? null
                  : () => _openPermissionEditor(
                grantId: grantId,
                patientId: patientId,
                granteeRole: grant.granteeRole,
                currentPermission: grant.permission,
              ),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Change permission',
            ),
            IconButton(
              onPressed: !canEditGrant ? null : () => _revokeGrant(grantId),
              icon: const Icon(Icons.block),
              tooltip: 'Revoke grant',
            ),
          ],
        )
            : null,
      ),
    );
  }

  Widget _inviteCard({
    required Map<String, dynamic> invite,
    required bool showActions,
  }) {
    final token = _inviteToken(invite);
    final patientId = _invitePatientId(invite);
    final patientName = _patientNameFromRow(invite);
    final invitedRole = invite['invited_role']?.toString() ?? 'Unknown role';
    final permission = invite['permission']?.toString() ?? 'Unknown permission';
    final status = invite['status']?.toString() ?? 'pending';
    final invitedEmail = invite['invited_email']?.toString() ?? 'Unknown email';

    return Card(
      child: ListTile(
        title: Text(patientName),
        subtitle: Text(
          'Role: $invitedRole\nPermission: $permission\nEmail: $invitedEmail\nStatus: $status',
        ),
        isThreeLine: true,
        onTap: patientId.isEmpty
            ? null
            : () => _showPatientSheet(patientId, title: patientName),
        trailing: showActions
            ? Wrap(
          spacing: 6,
          children: [
            IconButton(
              onPressed: token.isEmpty ? null : () => _acceptInviteToken(token),
              icon: const Icon(Icons.check),
              tooltip: 'Accept invite',
            ),
            IconButton(
              onPressed: token.isEmpty ? null : () => _rejectInviteToken(token),
              icon: const Icon(Icons.close),
              tooltip: 'Reject invite',
            ),
          ],
        )
            : null,
      ),
    );
  }

  Widget _buildPendingInvitesSection() {
    if (_pendingInviteRows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My pending invites',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ..._pendingInviteRows.map(
              (invite) => _inviteCard(
            invite: invite,
            showActions: true,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
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
                            (grant) => _grantCard(
                          grant: grant,
                          patientId: patientId,
                          showActions: true,
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
                            (invite) => _inviteCard(
                          invite: {
                            'patient_id': invite.patientId,
                            'invited_email': invite.invitedEmail,
                            'invited_role': invite.invitedRole,
                            'permission': invite.permission,
                            'status': invite.status,
                            'invite_token': invite.inviteToken,
                            'first_name': invite.id, // fallback if the view is not returned
                          },
                          showActions: true,
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

  @override
  Widget build(BuildContext context) {
    final grouped = _groupRowsByPatient();
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
            _buildPendingInvitesSection(),
            if (patientId != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current patient',
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
              FutureBuilder<List<Object?>>(
                future: Future.wait<Object?>([
                  _accessService.fetchPatientGrants(patientId),
                  _accessService.fetchPatientInvites(patientId),
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Could not load patient access: ${snapshot.error}'),
                    );
                  }

                  final data = snapshot.data ?? const <Object?>[];
                  final grants = data.isNotEmpty
                      ? (data[0] as List<AccessGrantModel>)
                      : <AccessGrantModel>[];
                  final invites = data.length > 1
                      ? (data[1] as List<AccessInviteModel>)
                      : <AccessInviteModel>[];

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
                      if (grants.isEmpty)
                        const Text('No active grants')
                      else
                        ...grants.map(
                              (grant) => _grantCard(
                            grant: grant,
                            patientId: patientId,
                            showActions: true,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'Invites',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (invites.isEmpty)
                        const Text('No invites')
                      else
                        ...invites.map(
                              (invite) => _inviteCard(
                            invite: {
                              'patient_id': invite.patientId,
                              'invited_email': invite.invitedEmail,
                              'invited_role': invite.invitedRole,
                              'permission': invite.permission,
                              'status': invite.status,
                              'invite_token': invite.inviteToken,
                            },
                            showActions: true,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ] else if (grouped.isEmpty)
              const Center(child: Text('No access rows found.'))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: grouped.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final entry = grouped.entries.elementAt(index);
                  final rows = entry.value;
                  final first = rows.first;

                  final firstName = first['first_name']?.toString() ?? '';
                  final familyName = first['family_name']?.toString() ?? '';
                  final age = first['age_years']?.toString() ?? 'Unknown';
                  final sex = first['sex']?.toString() ?? 'Unknown';
                  final bloodType = first['blood_type']?.toString() ?? 'Unknown';

                  return Card(
                    child: ListTile(
                      title: Text('$firstName $familyName'.trim()),
                      subtitle: Text(
                        'Age: $age • Sex: $sex • Blood type: $bloodType\nAccess rows: ${rows.length}',
                      ),
                      onTap: () => _showPatientSheet(
                        entry.key,
                        title: '$firstName $familyName'.trim(),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}