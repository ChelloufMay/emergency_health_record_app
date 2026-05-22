import 'package:flutter/material.dart';

import '../services/access_service.dart';

class AccessPermissionEditorScreen extends StatefulWidget {
  final String grantId;
  final String patientId;
  final String granteeRole;
  final String currentPermission;
  final DateTime? currentExpiresAt;
  final String? currentNotes;

  const AccessPermissionEditorScreen({
    super.key,
    required this.grantId,
    required this.patientId,
    required this.granteeRole,
    required this.currentPermission,
    this.currentExpiresAt,
    this.currentNotes,
  });

  @override
  State<AccessPermissionEditorScreen> createState() =>
      _AccessPermissionEditorScreenState();
}

class _AccessPermissionEditorScreenState
    extends State<AccessPermissionEditorScreen> {
  final AccessService _service = AccessService();
  final TextEditingController _notesController = TextEditingController();

  late String _permission;
  DateTime? _expiresAt;
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
    _expiresAt = widget.currentExpiresAt;
    _notesController.text = widget.currentNotes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'caregiver':
        return 'caregiver';
      case 'guardian':
        return 'guardian';
      case 'clinician':
        return 'clinician';
      default:
        return role;
    }
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

  String _expiryLabel() {
    if (_expiresAt == null) return 'No expiry set';
    final d = _expiresAt!;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _pickExpiry() async {
    final initial = _expiresAt ?? DateTime.now().add(const Duration(days: 30));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked == null) return;

    setState(() {
      // CHANGED: expiry is now optional and date-based instead of forcing EOD.
      _expiresAt = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _clearExpiry() async {
    setState(() {
      // CHANGED: allow the permission to remain open-ended.
      _expiresAt = null;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      await _service.updateGrantPermission(
        grantId: widget.grantId,
        permission: _permission,
        expiresAt: _expiresAt,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        patientId: widget.patientId,
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
                'Change the active grant for this ${_roleLabel(widget.granteeRole)}. '
                    'Grant-only editor: permission, expiry, and notes.',
              ),
            ),
          ),
          const SizedBox(height: 16),

          // CHANGED: the permission editor now stays focused on grant fields only.
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
              title: Text(_labelFor(value)),
              subtitle: Text(value),
            ),
          ),

          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_outlined),
              title: const Text('Expiry date'),
              subtitle: Text(_expiryLabel()),
              trailing: Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: _saving ? null : _pickExpiry,
                    child: const Text('Set'),
                  ),
                  TextButton(
                    onPressed: _saving ? null : _clearExpiry,
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Optional internal note about this access grant',
              border: OutlineInputBorder(),
            ),
            enabled: !_saving,
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