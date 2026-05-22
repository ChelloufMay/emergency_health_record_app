import 'package:flutter/material.dart';

import '../models/access_invite_model.dart';
import '../models/access_grant_model.dart';
import '../services/access_service.dart';
import '../services/patient_service.dart';
import '../services/patient_session_service.dart';

class CaregiverScreen extends StatefulWidget {
  const CaregiverScreen({super.key});

  @override
  State<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends State<CaregiverScreen> {
  final AccessService _accessService = AccessService();
  final PatientService _patientService = PatientService();

  bool _loading = true;
  String? _patientId;
  String? _patientName;
  List<AccessGrantModel> _grants = [];
  List<AccessInviteModel> _invites = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = PatientSessionService.instance.current;
    if (session == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _patientId = null;
      });
      return;
    }

    final patientId = session.patientId;
    final summary = await _patientService.fetchPatientSummary(patientId);
    final grants = await _accessService.fetchPatientGrants(patientId);
    final invites = await _accessService.fetchPatientInvites(patientId);

    if (!mounted) return;
    setState(() {
      _patientId = patientId;
      _patientName = summary == null
          ? session.patientName
          : [
              summary['first_name']?.toString() ?? '',
              summary['family_name']?.toString() ?? '',
            ].join(' ').trim();
      _grants = grants;
      _invites = invites;
      _loading = false;
    });
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
                  decoration: const InputDecoration(labelText: 'Notes'),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invite sent.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invite failed: $e')));
    } finally {
      emailController.dispose();
      notesController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access management'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: _patientId == null
          ? null
          : FloatingActionButton(
              onPressed: _showInviteDialog,
              child: const Icon(Icons.person_add),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patientId == null
          ? const Center(child: Text('Select a patient session first.'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(_patientName ?? 'Patient'),
                      subtitle: Text('Patient ID: $_patientId'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Access grants',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (_grants.isEmpty)
                    const Text('No grants yet.')
                  else
                    ..._grants.map((grant) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.verified_user_outlined),
                          title: Text(
                            '${grant.granteeRole} • ${grant.permission}',
                          ),
                          subtitle: Text(
                            [
                              'User: ${grant.granteeUserId}',
                              'Status: ${grant.status}',
                              if (grant.expiresAt != null)
                                'Expires: ${grant.expiresAt}',
                            ].join('\n'),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  const Text(
                    'Invites',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (_invites.isEmpty)
                    const Text('No invites yet.')
                  else
                    ..._invites.map((invite) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.mail_outline),
                          title: Text(
                            '${invite.invitedRole} • ${invite.permission}',
                          ),
                          subtitle: Text(
                            [
                              'Email: ${invite.invitedEmail}',
                              'Status: ${invite.status}',
                              if (invite.expiresAt != null)
                                'Expires: ${invite.expiresAt}',
                            ].join('\n'),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

