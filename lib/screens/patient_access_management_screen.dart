import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/access_grant_view_model.dart';
import '../services/access_service.dart';
import '../services/patient_session_service.dart';

/// Patient-owner access management screen.
///
/// This screen is intentionally for the patient's own flow only.
/// It shows current grants, lets the patient change permission, and revoke access.
class PatientAccessManagementScreen extends StatefulWidget {
  /// Optional explicit patient id, usually passed from the patient home flow.
  final String? patientId;

  /// Optional display name for the current patient.
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
    if (sessionId != null && sessionId.trim().isNotEmpty) return sessionId.trim();

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
      final rows = await Supabase.instance.client
          .from('patient_access_dashboard')
          .select()
          .eq('patient_id', patientId);

      final list = (rows as List)
          .map((item) => AccessGrantViewModel.fromDashboardRow(item))
          .where((grant) => grant.grantId.isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _grants = list;
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

  String _granteeLabel(AccessGrantViewModel grant) {
    final label = grant.granteeLabel.trim();
    if (label.isNotEmpty && label != grant.granteeUserId) {
      return label;
    }
    final fallback = grant.granteeUserId.trim();
    if (fallback.isNotEmpty) return fallback;
    return 'Connected user';
  }

  String _granteeRoleLabel(String role) {
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

  Future<void> _updatePermission(
      AccessGrantViewModel grant,
      String permission,
      ) async {
    if (grant.grantId.isEmpty) return;
    if (_busyGrantIds.contains(grant.grantId)) return;

    setState(() {
      _busyGrantIds.add(grant.grantId);
      _saving = true;
    });

    try {
      await _accessService.updateGrantPermission(
        grantId: grant.grantId,
        permission: permission,
        patientId: _resolvedPatientId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Permission updated to ${_permissionLabel(permission)}.',
          ),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update permission: $e')),
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

  Widget _permissionDropdown(AccessGrantViewModel grant) {
    final options = const ['read', 'edit', 'emergency_only'];
    final busy = _busyGrantIds.contains(grant.grantId);

    return DropdownButtonFormField<String>(
      initialValue: options.contains(grant.permission) ? grant.permission : 'read',
      decoration: const InputDecoration(
        labelText: 'Permission',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: options
          .map(
            (value) => DropdownMenuItem<String>(
          value: value,
          child: Text(_permissionLabel(value)),
        ),
      )
          .toList(),
      onChanged: busy ? null : (value) {
        if (value == null || value == grant.permission) return;
        _updatePermission(grant, value);
      },
    );
  }

  Widget _grantCard(AccessGrantViewModel grant) {
    final busy = _busyGrantIds.contains(grant.grantId);
    final expiresAt = grant.expiresAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                      Text(_granteeRoleLabel(grant.granteeRole)),
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
            _permissionDropdown(grant),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text('Status: ${_prettyText(grant.status)}'),
                ),
                Expanded(
                  child: Text(
                    expiresAt == null
                        ? 'Expires: never'
                        : 'Expires: ${expiresAt.toLocal().toIso8601String().split(".").first}',
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            if (grant.notes != null &&
                grant.notes!.trim().isNotEmpty) ...[
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
              child: Text(headerText),
            ),
          ),
          const SizedBox(height: 12),
          if (_grants.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No active grants yet.'),
              ),
            )
          else
            ..._grants.map(_grantCard),
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
