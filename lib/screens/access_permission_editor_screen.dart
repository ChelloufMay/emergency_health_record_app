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

  String _labelFor(String value) {
    switch (value) {
      case 'read':
        return 'Read-only access';
      case 'edit':
        return 'Read and edit access';
      case 'emergency_only':
        return 'Emergency-only access';
      default:
        return value;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
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
                    'This updates the active grant directly and keeps the access flow consistent with the schema.',
              ),
            ),
          ),
          const SizedBox(height: 16),

          // RadioGroup now owns the selected value and the change handler.
          RadioGroup<String>(
            groupValue: _permission,
            onChanged: _saving
                ? (value) {}
                : (selected) {
              if (selected == null) return;
              setState(() => _permission = selected);
            },
            child: Column(
              children: _permissions.map((value) {
                return RadioListTile<String>(
                  value: value,
                  title: Text(_labelFor(value)),
                  subtitle: Text(value),
                  selected: _permission == value,
                );
              }).toList(),
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