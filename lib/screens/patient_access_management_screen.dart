import 'package:flutter/material.dart';

import '../models/access_grant_view_model.dart';
import '../models/access_invite_model.dart';
import '../services/access_service.dart';
import '../services/patient_session_service.dart';

// Patient-owner access management screen.

// This screen is for the patient's flow
// It shows current grants, lets the patient change permission, revoke access, and send new invites by email for caregivers / guardians / clinicians.

class PatientAccessManagementScreen extends StatefulWidget {
  // The unique identifier of the patient.
  final String? patientId;
  
  final String? patientName;

  const PatientAccessManagementScreen({
    super.key,
    this.patientId,
    this.patientName,
  });

  @override
  State<PatientAccessManagementScreen> createState() =>
      _PatientAccessManagementScreenState();
}

class _PatientAccessManagementScreenState
    extends State<PatientAccessManagementScreen> {
  final AccessService _accessService = AccessService();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _resolvedPatientId;
  String? _resolvedPatientName;

  List<AccessGrantViewModel> _grants = [];
  List<AccessInviteModel> _pendingInvites = [];

  final Set<String> _busyGrantIds = <String>{};

  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    _bootstrap();
  }

  String? _routePatientId() {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is String && arguments.trim().isNotEmpty) {
      return arguments.trim();
    }
    if (arguments is Map) {
      final map = Map<String, dynamic>.from(arguments);
      final value = map['patientId'] ?? map['patient_id'];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }

  String? _routePatientName() {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map) {
      final map = Map<String, dynamic>.from(arguments);
      final value = map['patientName'] ?? map['patient_name'];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }

  String? _currentPatientId() {
    final widgetId = widget.patientId?.trim();
    if (widgetId != null && widgetId.isNotEmpty) return widgetId;

    final routeId = _routePatientId();
    if (routeId != null && routeId.isNotEmpty) return routeId;

    final sessionId = PatientSessionService.instance.current?.patientId;
    if (sessionId != null && sessionId.trim().isNotEmpty) {
      return sessionId.trim();
    }

    return null;
  }

  String? _currentPatientName() {
    final widgetName = widget.patientName?.trim();
    if (widgetName != null && widgetName.isNotEmpty) return widgetName;

    final routeName = _routePatientName();
    if (routeName != null && routeName.isNotEmpty) return routeName;

    final sessionName = PatientSessionService.instance.current?.patientName?.trim();
    if (sessionName != null && sessionName.isNotEmpty) return sessionName;

    return null;
  }

  Future<void> _bootstrap() async {
    _resolvedPatientId = _currentPatientId();
    _resolvedPatientName = _currentPatientName();

    if (_resolvedPatientId == null || _resolvedPatientId!.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No patient session was found for this screen.';
      });
      return;
    }

    await _load();
  }

  Future<void> _load() async {
    final patientId = _resolvedPatientId;
    if (patientId == null || patientId.isEmpty) return;

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        _accessService.fetchPatientGrantViews(patientId),
        _accessService.fetchPatientInvites(patientId),
      ]);

      final grants = (results[0] as List<AccessGrantViewModel>)
          .where((grant) => grant.grantId.isNotEmpty)
          .toList();

      final invites = (results[1] as List<AccessInviteModel>)
          .where((invite) => invite.status.toLowerCase().trim() == 'pending')
          .toList();

      if (!mounted) return;
      setState(() {
        _grants = grants;
        _pendingInvites = invites;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _prettyText(String value) {
    final cleaned = value.replaceAll('_', ' ').trim();
    if (cleaned.isEmpty) return '-';
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  String _permissionLabel(String value) {
    switch (value.toLowerCase().trim()) {
      case 'read':
        return 'Read';
      case 'edit':
        return 'Edit';
      case 'emergency_only':
        return 'Emergency only';
      default:
        return _prettyText(value);
    }
  }

  String _roleLabel(String role) {
    switch (role.toLowerCase().trim()) {
      case 'caregiver':
        return 'Caregiver';
      case 'guardian':
        return 'Guardian';
      case 'clinician':
        return 'Clinician';
      default:
        return _prettyText(role);
    }
  }

  String _granteeLabel(AccessGrantViewModel grant) {
    final label = grant.granteeLabel.trim();
    if (label.isNotEmpty && label != grant.granteeUserId) {
      return label;
    }
    final fallback = grant.granteeUserId.trim();
    if (fallback.isNotEmpty) return fallback;
    return 'Connected user';
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'Never';
    final local = value.toLocal();
    final date = local.toIso8601String().split('.').first;
    return date.replaceFirst('T', ' ');
  }

  Future<DateTime?> _pickDateTime(
      BuildContext context, {
        DateTime? initial,
      }) async {
    final now = DateTime.now();
    final initialDate = initial ?? now.add(const Duration(days: 30));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 3650)),
    );

    if (date == null) return initial;

    final initialTime = TimeOfDay.fromDateTime(initial ?? now);
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (time == null) {
      return DateTime(date.year, date.month, date.day, now.hour, now.minute);
    }

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _openInviteDialog() async {
    if (_resolvedPatientId == null || _resolvedPatientId!.isEmpty) return;

    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final notesController = TextEditingController();

    String invitedRole = 'caregiver';
    String permission = 'read';
    DateTime? expiresAt;
    bool includeExpiry = false;

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Send invite'),
                content: Form(
                  key: formKey,
                  child: SizedBox(
                    width: 560,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email address',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) {
                                return 'Email is required';
                              }
                              if (!email.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: invitedRole,
                            decoration: const InputDecoration(
                              labelText: 'Role',
                              border: OutlineInputBorder(),
                            ),
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
                            onChanged: (value) {
                              if (value == null) return;
                              setDialogState(() {
                                invitedRole = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: permission,
                            decoration: const InputDecoration(
                              labelText: 'Permission',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'read',
                                child: Text('Read'),
                              ),
                              DropdownMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              DropdownMenuItem(
                                value: 'emergency_only',
                                child: Text('Emergency only'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setDialogState(() {
                                permission = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Set expiry'),
                            subtitle: Text(
                              includeExpiry && expiresAt != null
                                  ? _formatDateTime(expiresAt)
                                  : 'No expiry',
                            ),
                            value: includeExpiry,
                            onChanged: (value) async {
                              if (value) {
                                final picked = await _pickDateTime(
                                  dialogContext,
                                  initial: expiresAt,
                                );
                                if (picked == null) return;
                                setDialogState(() {
                                  includeExpiry = true;
                                  expiresAt = picked;
                                });
                              } else {
                                setDialogState(() {
                                  includeExpiry = false;
                                  expiresAt = null;
                                });
                              }
                            },
                          ),
                          if (includeExpiry)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () async {
                                  final picked = await _pickDateTime(
                                    dialogContext,
                                    initial: expiresAt,
                                  );
                                  if (picked == null) return;
                                  setDialogState(() {
                                    expiresAt = picked;
                                  });
                                },
                                icon: const Icon(Icons.event),
                                label: Text(
                                  expiresAt == null
                                      ? 'Choose expiry'
                                      : 'Expiry: ${_formatDateTime(expiresAt)}',
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Notes (optional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      Navigator.pop(dialogContext, true);
                    },
                    child: const Text('Send invite'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confirmed != true) return;

      final patientId = _resolvedPatientId;
      if (patientId == null || patientId.isEmpty) return;

      if (mounted) {
        setState(() => _saving = true);
      }

      await _accessService.createInvite(
        patientId: patientId,
        invitedEmail: emailController.text.trim(),
        invitedRole: invitedRole,
        permission: permission,
        expiresAt: includeExpiry ? expiresAt : null,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invite sent to ${emailController.text.trim()} as ${_roleLabel(invitedRole)}.',
          ),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send invite: $e')),
      );
    } finally {
      emailController.dispose();
      notesController.dispose();
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _openGrantEditor(AccessGrantViewModel grant) async {
    if (grant.grantId.isEmpty) return;
    if (_busyGrantIds.contains(grant.grantId)) return;

    final formKey = GlobalKey<FormState>();
    final notesController = TextEditingController(text: grant.notes ?? '');

    String permission = grant.permission;
    DateTime? expiresAt = grant.expiresAt;
    bool includeExpiry = expiresAt != null;

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text('Manage ${_granteeLabel(grant)}'),
                content: Form(
                  key: formKey,
                  child: SizedBox(
                    width: 560,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: permission,
                            decoration: const InputDecoration(
                              labelText: 'Permission',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'read',
                                child: Text('Read'),
                              ),
                              DropdownMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              DropdownMenuItem(
                                value: 'emergency_only',
                                child: Text('Emergency only'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setDialogState(() {
                                permission = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Set expiry'),
                            subtitle: Text(
                              includeExpiry && expiresAt != null
                                  ? _formatDateTime(expiresAt)
                                  : 'No expiry',
                            ),
                            value: includeExpiry,
                            onChanged: (value) async {
                              if (value) {
                                final picked = await _pickDateTime(
                                  dialogContext,
                                  initial: expiresAt,
                                );
                                if (picked == null) return;
                                setDialogState(() {
                                  includeExpiry = true;
                                  expiresAt = picked;
                                });
                              } else {
                                setDialogState(() {
                                  includeExpiry = false;
                                });
                              }
                            },
                          ),
                          if (includeExpiry)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () async {
                                  final picked = await _pickDateTime(
                                    dialogContext,
                                    initial: expiresAt,
                                  );
                                  if (picked == null) return;
                                  setDialogState(() {
                                    expiresAt = picked;
                                  });
                                },
                                icon: const Icon(Icons.event),
                                label: Text(
                                  expiresAt == null
                                      ? 'Choose expiry'
                                      : 'Expiry: ${_formatDateTime(expiresAt)}',
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Notes',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      Navigator.pop(dialogContext, true);
                    },
                    child: const Text('Save changes'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confirmed != true) return;

      setState(() {
        _busyGrantIds.add(grant.grantId);
        _saving = true;
      });

      await _accessService.updateGrantPermission(
        grantId: grant.grantId,
        permission: permission,
        expiresAt: includeExpiry ? expiresAt : grant.expiresAt,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        patientId: _resolvedPatientId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Updated access for ${_granteeLabel(grant)}.',
          ),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update access: $e')),
      );
    } finally {
      notesController.dispose();
      if (mounted) {
        setState(() {
          _busyGrantIds.remove(grant.grantId);
          _saving = _busyGrantIds.isNotEmpty;
        });
      }
    }
  }

  Future<void> _confirmRevoke(AccessGrantViewModel grant) async {
    if (grant.grantId.isEmpty) return;

    final shouldRevoke = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove access?'),
          content: Text(
            'This will revoke access for ${_granteeLabel(grant)}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Revoke'),
            ),
          ],
        );
      },
    );

    if (shouldRevoke != true) return;

    setState(() {
      _busyGrantIds.add(grant.grantId);
      _saving = true;
    });

    try {
      await _accessService.revokeGrant(
        grant.grantId,
        patientId: _resolvedPatientId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access revoked.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not revoke access: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyGrantIds.remove(grant.grantId);
          _saving = _busyGrantIds.isNotEmpty;
        });
      }
    }
  }

  Widget _grantCard(AccessGrantViewModel grant) {
    final busy = _busyGrantIds.contains(grant.grantId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: busy ? null : () => _openGrantEditor(grant),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _granteeLabel(grant),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(_roleLabel(grant.granteeRole)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: busy ? null : () => _confirmRevoke(grant),
                    tooltip: 'Revoke access',
                    icon: const Icon(Icons.person_remove_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text('Permission: ${_permissionLabel(grant.permission)}')),
                  Expanded(
                    child: Text(
                      'Status: ${_prettyText(grant.status)}',
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Expires: ${_formatDateTime(grant.expiresAt)}'),
              if (grant.notes != null && grant.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Notes',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(grant.notes!.trim()),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: busy ? null : () => _openGrantEditor(grant),
                  icon: const Icon(Icons.tune),
                  label: const Text('Manage'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inviteCard(AccessInviteModel invite) {
    final role = invite.invitedRole.trim();
    final permission = invite.permission.trim();
    final expiresAt = invite.expiresAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              invite.invitedEmail.trim().isEmpty
                  ? 'Pending invite'
                  : invite.invitedEmail.trim(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(_roleLabel(role)),
            const SizedBox(height: 8),
            Text('Permission: ${_permissionLabel(permission)}'),
            const SizedBox(height: 8),
            Text('Status: ${_prettyText(invite.status)}'),
            const SizedBox(height: 8),
            Text('Expires: ${_formatDateTime(expiresAt)}'),
            if (invite.notes != null && invite.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(invite.notes!.trim()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final patientName = _resolvedPatientName;
    final headerText = patientName == null || patientName.isEmpty
        ? 'Manage who can access your patient record.'
        : 'Manage who can access $patientName\'s record.';

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(headerText),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: _saving ? null : _openInviteDialog,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Send invite'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Active access (${_grants.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (_grants.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No active grants yet.'),
              ),
            )
          else
            ..._grants.map(_grantCard),
          const SizedBox(height: 8),
          Text(
            'Pending invites (${_pendingInvites.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (_pendingInvites.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No pending invites.'),
              ),
            )
          else
            ..._pendingInvites.map(_inviteCard),
          if (_saving) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildContent();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access management'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: body,
    );
  }
}