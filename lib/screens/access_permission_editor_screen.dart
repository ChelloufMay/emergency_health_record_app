import 'package:flutter/material.dart';

import '../services/access_service.dart';

class AccessPermissionEditorScreen extends StatefulWidget {
  final String grantId;
  final String patientId;
  final String granteeRole;
  final String currentPermission;

  const AccessPermissionEditorScreen({
    super.key,
    required this.grantId,
    required this.patientId,
    required this.granteeRole,
    required this.currentPermission,
  });

  @override
  State<AccessPermissionEditorScreen> createState() =>
      _AccessPermissionEditorScreenState();
}

class _AccessPermissionEditorScreenState
    extends State<AccessPermissionEditorScreen> {
  final AccessService _service = AccessService();

  late String _permission;
  bool _saving = false;

  static const List<String> _permissions = [
    'read',
    'edit',
    'emergency_only',
  ];

  @override
  void initState() {
    super.initState();
    _permission = _permissions.contains(widget.currentPermission)
        ? widget.currentPermission
        : 'read';
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      // CHANGED: update the grant permission in the DB, then let the trigger
      // keep caregiver_permissions synchronized.
      await _service.updateGrantPermission(
        grantId: widget.grantId,
        permission: _permission,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update permission: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit access permission'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Change the DB permission for this ${widget.granteeRole}. '
                    'This updates the active grant directly, and the dashboard will refresh afterward.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._permissions.map(
                (value) => RadioListTile<String>(
              value: value,
              groupValue: _permission,
              onChanged: _saving
                  ? null
                  : (selected) {
                if (selected == null) return;
                setState(() => _permission = selected);
              },
              title: Text(value),
              subtitle: Text(
                value == 'read'
                    ? 'Read-only access'
                    : value == 'edit'
                    ? 'Read and edit access'
                    : 'Emergency-only access',
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Save permission'),
          ),
        ],
      ),
    );
  }
}