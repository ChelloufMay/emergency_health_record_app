import 'package:flutter/material.dart';

import '../models/access_grant_model.dart';
import '../models/access_invite_model.dart';
import '../services/access_service.dart';
import '../services/patient_service.dart';
import '../services/patient_session_service.dart';
import 'access_permission_editor_screen.dart'; // CHANGED: permission editing for active grants

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
  String? _myEmail;

  String? _resolvePatientId() {
    return widget.patientId ?? PatientSessionService.instance.current?.patientId;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final rows = await _accessService.fetchMyAccessDashboardRowMaps();
      final myUserRow = await _patientService.fetchCurrentAppUserRow();

      if (!mounted) return;
      setState(() {
        _rows = rows;
        _myEmail = myUserRow?['email']?.toString().toLowerCase();
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

  Future<void> _acceptInvite(AccessInviteModel invite) async {
    final token = invite.inviteToken ?? '';
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

      // If the RPC returns a patient id, try to open the refreshed details.
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
            title:
            '${matchedRow.first['first_name']?.toString() ?? ''} ${matchedRow.first['family_name']?.toString() ?? ''}'
                .trim(),
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

  Future<void> _rejectInvite(AccessInviteModel invite) async {
    final token = invite.inviteToken ?? '';
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
    required AccessInviteModel invite,
    required bool showActions,
  }) {
    final token = invite.inviteToken ?? '';
    final canSelfAct = _myEmail != null &&
        _myEmail!.trim().isNotEmpty &&
        invite.invitedEmail.trim().toLowerCase() ==
            _myEmail!.trim().toLowerCase();

    return Card(
      child: ListTile(
        title: Text('${invite.invitedRole} • ${invite.permission}'),
        subtitle: Text(
          'Email: ${invite.invitedEmail}\nStatus: ${invite.status}\nToken: ${token.isEmpty ? 'missing' : token}',
        ),
        isThreeLine: true,
        trailing: showActions
            ? Wrap(
          spacing: 6,
          children: [
            if (canSelfAct)
              IconButton(
                onPressed: token.isEmpty
                    ? null
                    : () => _acceptInvite(invite),
                icon: const Icon(Icons.check),
                tooltip: 'Accept invite',
              ),
            if (canSelfAct)
              IconButton(
                onPressed: token.isEmpty
                    ? null
                    : () => _rejectInvite(invite),
                icon: const Icon(Icons.close),
                tooltip: 'Reject invite',
              ),
          ],
        )
            : null,
      ),
    );
  }

  Future<void> _showPatientSheet(String patientId, {String? title}) async {
    final grantsFuture = _accessService.fetchPatientGrants(patientId);
    final invitesFuture = _accessService.fetchPatientInvites(patientId);

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return FutureBuilder<List<dynamic>>(
              future: Future.wait([grantsFuture, invitesFuture]),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Could not load details: ${snapshot.error}'),
                  );
                }

                final data = snapshot.data ?? const [];
                final grants = (data[0] as List<AccessGrantModel>);
                final invites = (data[1] as List<AccessInviteModel>);

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
                          invite: invite,
                          showActions: true,
                        ),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(false),
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

    if (result == true) {
      await _load();
    }
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
          : patientId != null
          ? FutureBuilder<List<dynamic>>(
        future: Future.wait([
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

          final data = snapshot.data ?? const [];
          final grants = data[0] as List<AccessGrantModel>;
          final invites = data[1] as List<AccessInviteModel>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
                    invite: invite,
                    showActions: true,
                  ),
                ),
            ],
          );
        },
      )
          : grouped.isEmpty
          ? const Center(child: Text('No access rows found.'))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: grouped.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
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
    );
  }
}