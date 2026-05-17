import 'package:flutter/material.dart';

import '../models/access_grant_model.dart';
import '../models/access_invite_model.dart';
import '../services/access_service.dart';
import '../services/patient_service.dart';
import '../services/patient_session_service.dart';

class AccessDashboardScreen extends StatefulWidget {
  final String? patientId;

  const AccessDashboardScreen({
    super.key,
    this.patientId,
  });

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

    // Overview rows come from the DB view patient_access_dashboard.
    final rows = await _accessService.fetchMyAccessDashboardRows();
    final myUserRow = await _patientService.fetchCurrentAppUserRow();

    if (!mounted) return;
    setState(() {
      _rows = rows;
      _myEmail = myUserRow?['email']?.toString().toLowerCase();
      _loading = false;
    });
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

  Future<void> _showPatientSheet(
      String patientId, {
        String? title,
      }) async {
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
            return FutureBuilder(
              future: Future.wait([grantsFuture, invitesFuture]),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data as List<dynamic>;
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
                            (grant) => Card(
                          child: ListTile(
                            title: Text(
                              '${grant.granteeRole} • ${grant.permission}',
                            ),
                            subtitle: Text(
                              'Status: ${grant.status} • Expires: ${grant.expiresAt?.toIso8601String() ?? 'Never'}',
                            ),
                            trailing: IconButton(
                              onPressed: () async {
                                await _accessService.revokeGrant(grant.id ?? '');
                                if (!context.mounted) return;
                                Navigator.of(context).pop(true);
                              },
                              icon: const Icon(Icons.block),
                              tooltip: 'Revoke grant',
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
                      ...invites.map((invite) {
                        final canSelfAccept = _myEmail != null &&
                            _myEmail!.trim().isNotEmpty &&
                            invite.invitedEmail.trim().toLowerCase() ==
                                _myEmail!.trim().toLowerCase();

                        return Card(
                          child: ListTile(
                            title: Text(
                              '${invite.invitedRole} • ${invite.permission}',
                            ),
                            subtitle: Text(
                              'Email: ${invite.invitedEmail}\nStatus: ${invite.status}\nToken: ${invite.inviteToken ?? 'missing'}',
                            ),
                            isThreeLine: true,
                            trailing: Wrap(
                              spacing: 6,
                              children: [
                                if (canSelfAccept)
                                  IconButton(
                                    onPressed: () async {
                                      if (invite.inviteToken == null) return;
                                      await _accessService.acceptInvite(
                                        invite.inviteToken!,
                                      );
                                      if (!context.mounted) return;
                                      Navigator.of(context).pop(true);
                                    },
                                    icon: const Icon(Icons.check),
                                    tooltip: 'Accept invite',
                                  ),
                                if (canSelfAccept)
                                  IconButton(
                                    onPressed: () async {
                                      if (invite.inviteToken == null) return;
                                      await _accessService.rejectInvite(
                                        invite.inviteToken!,
                                      );
                                      if (!context.mounted) return;
                                      Navigator.of(context).pop(true);
                                    },
                                    icon: const Icon(Icons.close),
                                    tooltip: 'Reject invite',
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(false),
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
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : patientId != null
          ? FutureBuilder(
        future: Future.wait([
          _accessService.fetchPatientGrants(patientId),
          _accessService.fetchPatientInvites(patientId),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data as List<dynamic>;
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
                      (grant) => Card(
                    child: ListTile(
                      title: Text(
                        '${grant.granteeRole} • ${grant.permission}',
                      ),
                      subtitle: Text(
                        'Status: ${grant.status} • Expires: ${grant.expiresAt?.toIso8601String() ?? 'Never'}',
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
                        '${invite.invitedRole} • ${invite.permission}',
                      ),
                      subtitle: Text(
                        'Email: ${invite.invitedEmail}\nStatus: ${invite.status}\nToken: ${invite.inviteToken ?? 'missing'}',
                      ),
                    ),
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