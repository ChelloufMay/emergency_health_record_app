import 'package:flutter/material.dart';

import '../models/verification_label_model.dart';
import '../services/patient_service.dart';
import '../services/patient_session_service.dart';
import '../services/verification_label_service.dart';

class VerificationLabelsScreen extends StatefulWidget {
  final String? patientId;

  const VerificationLabelsScreen({super.key, this.patientId});

  @override
  State<VerificationLabelsScreen> createState() =>
      _VerificationLabelsScreenState();
}

class _VerificationLabelsScreenState extends State<VerificationLabelsScreen> {
  final VerificationLabelService _service = VerificationLabelService();
  final PatientService _patientService = PatientService();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _entityTypeController = TextEditingController();
  final TextEditingController _entityIdController = TextEditingController();
  final TextEditingController _fieldNameController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _enteredByRoleController =
  TextEditingController();
  final TextEditingController _enteredByCredentialsController =
  TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _canEdit = false;
  String? _error;
  String? _patientId;
  String? _editingId;
  String? _currentRole;
  String _status = 'unverified';
  List<VerificationLabelModel> _labels = [];

  static const Map<String, String> _statusLabels = {
    'unverified': 'Unverified',
    'user_entered': 'User entered',
    'caregiver_entered': 'Caregiver entered',
    'guardian_edited': 'Guardian edited',
    'clinician_verified': 'Clinician verified',
  };

  static const Map<String, String> _defaultStatusByRole = {
    'owner': 'user_entered',
    'patient': 'user_entered',
    'caregiver': 'caregiver_entered',
    'guardian': 'guardian_edited',
    'clinician': 'clinician_verified',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _entityTypeController.dispose();
    _entityIdController.dispose();
    _fieldNameController.dispose();
    _commentController.dispose();
    _enteredByRoleController.dispose();
    _enteredByCredentialsController.dispose();
    super.dispose();
  }

  String _normalizeRole(String? role) {
    return role == null ? '' : role.trim().toLowerCase();
  }

  bool get _isClinician => _normalizeRole(_currentRole) == 'clinician';

  String _defaultStatusForRole(String? role) {
    return _defaultStatusByRole[_normalizeRole(role)] ?? 'unverified';
  }

  bool _roleCanUseStatus(String? role, String status) {
    final normalizedRole = _normalizeRole(role);
    if (normalizedRole == 'clinician') {
      return true;
    }

    final defaultStatus = _defaultStatusForRole(normalizedRole);
    return status == 'unverified' || status == defaultStatus;
  }

  Future<String?> _resolvePatientId() async {
    if (widget.patientId != null && widget.patientId!.trim().isNotEmpty) {
      return widget.patientId!.trim();
    }

    // Prefer the current patient session first, then fall back to the
    // authenticated user's own patient profile.
    final session = PatientSessionService.instance.current;
    if (session?.patientId.isNotEmpty == true) return session!.patientId;

    final identity = await _patientService.resolveIdentity();
    return identity?.patientProfileId;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final patientId = await _resolvePatientId();
      if (patientId == null || patientId.isEmpty) {
        setState(() {
          _error = 'No patient selected.';
          _loading = false;
        });
        return;
      }

      final currentUser = await _patientService.fetchCurrentAppUserRow();
      final currentRole = currentUser?['role']?.toString().trim().toLowerCase();

      final canEdit = await _patientService.canAccessPatientSection(
        patientId,
        'verification_labels',
        'edit',
      );

      final list = await _service.fetchByPatient(patientId);
      if (!mounted) return;
      setState(() {
        _patientId = patientId;
        _currentRole = currentRole;
        _canEdit = canEdit;
        _labels = list;
        if (_editingId == null) {
          _status = _defaultStatusForRole(currentRole);
        } else if (!_roleCanUseStatus(currentRole, _status)) {
          _status = _defaultStatusForRole(currentRole);
        }
        if (_enteredByRoleController.text.trim().isEmpty) {
          _enteredByRoleController.text = currentRole ?? '';
        }
        if (_enteredByCredentialsController.text.trim().isEmpty) {
          _enteredByCredentialsController.text = currentRole ?? '';
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load verification labels: $e';
        _loading = false;
      });
    }
  }

  void _startEdit(VerificationLabelModel label) {
    setState(() {
      _editingId = label.id;
      _entityTypeController.text = label.entityType;
      _entityIdController.text = label.entityId;
      _fieldNameController.text = label.fieldName;
      _status = label.status;
      _commentController.text = label.comment ?? '';
      _enteredByRoleController.text = label.enteredByRole ?? '';
      _enteredByCredentialsController.text = label.enteredByCredentials ?? '';
    });
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    setState(() {
      _editingId = null;
      _entityTypeController.clear();
      _entityIdController.clear();
      _fieldNameController.clear();
      _commentController.clear();
      _enteredByRoleController.text = _currentRole ?? '';
      _enteredByCredentialsController.clear();
      _status = _defaultStatusForRole(_currentRole);
    });
  }

  String? _trimToNull(String value) {
    final v = value.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _save() async {
    final patientId = _patientId;
    if (patientId == null || patientId.isEmpty) return;
    if (!_canEdit) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final currentRole = _normalizeRole(_currentRole);
    final selectedStatus = _status.trim().isEmpty ? 'unverified' : _status.trim();

    if (!_roleCanUseStatus(currentRole, selectedStatus)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentRole.isEmpty
                ? 'Unable to determine your role for this label.'
                : 'Your role cannot set "$selectedStatus".',
          ),
        ),
      );
      return;
    }

    // Only clinicians can submit the clinician_verified state.
    if (selectedStatus == 'clinician_verified' && currentRole != 'clinician') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Only a clinician can mark a label as clinician verified.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final currentUser = await _patientService.fetchCurrentAppUserRow();
      final userId = currentUser?['id']?.toString();
      final roleFromUser = currentUser?['role']?.toString().trim().toLowerCase();

      final enteredByRoleText = _enteredByRoleController.text.trim();
      final effectiveEnteredByRole =
      enteredByRoleText.isEmpty ? roleFromUser : enteredByRoleText;

      final enteredByCredentialsText =
      _enteredByCredentialsController.text.trim();
      final effectiveEnteredByCredentials = enteredByCredentialsText.isEmpty
          ? (effectiveEnteredByRole ?? '')
          : enteredByCredentialsText;

      final effectiveStatus = _roleCanUseStatus(
        effectiveEnteredByRole,
        selectedStatus,
      )
          ? selectedStatus
          : _defaultStatusForRole(effectiveEnteredByRole);

      final label = VerificationLabelModel(
        id: _editingId,
        patientId: patientId,
        entityType: _entityTypeController.text.trim(),
        entityId: _entityIdController.text.trim(),
        fieldName: _fieldNameController.text.trim(),
        status: effectiveStatus,
        comment: _trimToNull(_commentController.text),
        enteredByRole: _trimToNull(effectiveEnteredByRole ?? ''),
        enteredByCredentials: _trimToNull(effectiveEnteredByCredentials),
        enteredByUserId: userId,
        // This field is only set when the label is truly clinician verified.
        verifiedByUserId:
        effectiveStatus == 'clinician_verified' ? userId : null,
        verifiedAt:
        effectiveStatus == 'clinician_verified' ? DateTime.now() : null,
      );

      await _service.save(label);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editingId == null ? 'Label created.' : 'Label updated.',
          ),
        ),
      );
      _clearForm();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteLabel(String id) async {
    try {
      await _service.delete(patientId: _patientId!, id: id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Label deleted.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Widget _buildRow(VerificationLabelModel label) {
    final labelId = label.id;

    return Card(
      child: ListTile(
        title: Text('${label.entityType} / ${label.fieldName}'),
        subtitle: Text(
          [
            'Entity: ${label.entityId}',
            'Status: ${label.status}',
            if ((label.comment ?? '').trim().isNotEmpty)
              'Comment: ${label.comment}',
            if ((label.enteredByRole ?? '').trim().isNotEmpty)
              'Entered by: ${label.enteredByRole}',
            if ((label.enteredByCredentials ?? '').trim().isNotEmpty)
              'Credentials: ${label.enteredByCredentials}',
            if ((label.verifiedByUserId ?? '').trim().isNotEmpty)
              'Verified by user: ${label.verifiedByUserId}',
          ].join('\n'),
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 8,
          children: [
            if (_canEdit)
              IconButton(
                onPressed: () => _startEdit(label),
                icon: const Icon(Icons.edit),
                tooltip: 'Edit',
              ),
            if (_canEdit)
              IconButton(
                onPressed: labelId == null ? null : () => _deleteLabel(labelId),
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification labels'),
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
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_canEdit) ...[
              Text(
                _editingId == null ? 'Add label' : 'Edit label',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _currentRole == null || _currentRole!.trim().isEmpty
                    ? 'Your role could not be determined.'
                    : 'Editing as: ${_currentRole!.trim()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _entityTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Entity type',
                        hintText:
                        'allergies, medications, diagnoses...',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _entityIdController,
                      decoration: const InputDecoration(
                        labelText: 'Entity ID',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fieldNameController,
                      decoration: const InputDecoration(
                        labelText: 'Field name',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        helperText: _isClinician
                            ? 'Clinicians can choose any status.'
                            : 'Your role only allows a role-specific status or unverified.',
                      ),
                      items: _statusLabels.entries.map((entry) {
                        final status = entry.key;
                        final enabled = _roleCanUseStatus(
                          _currentRole,
                          status,
                        );
                        final suffix = enabled
                            ? ''
                            : ' (not allowed for your role)';
                        return DropdownMenuItem(
                          value: status,
                          enabled: enabled,
                          child: Text('${entry.value}$suffix'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        if (!_roleCanUseStatus(_currentRole, value)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'That status is not allowed for your role.',
                              ),
                            ),
                          );
                          return;
                        }
                        setState(() => _status = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _commentController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Comment',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _enteredByRoleController,
                      decoration: const InputDecoration(
                        labelText: 'Entered by role',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _enteredByCredentialsController,
                      decoration: const InputDecoration(
                        labelText: 'Entered by credentials',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: const Icon(Icons.save),
                            label: Text(
                              _editingId == null ? 'Create' : 'Update',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: _clearForm,
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'You can view verification labels, but edits are disabled for this patient section.',
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Existing labels',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text('${_labels.length} total'),
              ],
            ),
            const SizedBox(height: 12),
            if (_labels.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Text('No verification labels yet.'),
                ),
              )
            else
              ..._labels.map(_buildRow),
          ],
        ),
      ),
    );
  }
}
