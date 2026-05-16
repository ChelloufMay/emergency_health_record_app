import 'package:flutter/material.dart';

import '../models/verification_label_model.dart';
import '../services/patient_service.dart';
import '../services/patient_session_service.dart';
import '../services/verification_label_service.dart';

class VerificationLabelsScreen extends StatefulWidget {
  final String? patientId;

  const VerificationLabelsScreen({
    super.key,
    this.patientId,
  });

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
  String _status = 'unverified';
  List<VerificationLabelModel> _labels = [];

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

  Future<String?> _resolvePatientId() async {
    if (widget.patientId != null && widget.patientId!.trim().isNotEmpty) {
      return widget.patientId!.trim();
    }

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

      final canEdit = await _patientService.canAccessPatientSection(
        patientId,
        'verification_labels',
        'edit',
      );

      final list = await _service.fetchByPatient(patientId);
      if (!mounted) return;
      setState(() {
        _patientId = patientId;
        _canEdit = canEdit;
        _labels = list;
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
      _enteredByRoleController.clear();
      _enteredByCredentialsController.clear();
      _status = 'unverified';
    });
  }

  Future<void> _save() async {
    final patientId = _patientId;
    if (patientId == null || patientId.isEmpty) return;
    if (!_canEdit) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      final currentUser = await _patientService.fetchCurrentAppUserRow();
      final userId = currentUser?['id']?.toString();

      final label = VerificationLabelModel(
        id: _editingId,
        patientId: patientId,
        entityType: _entityTypeController.text.trim(),
        entityId: _entityIdController.text.trim(),
        fieldName: _fieldNameController.text.trim(),
        status: _status,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        enteredByRole: _enteredByRoleController.text.trim().isEmpty
            ? null
            : _enteredByRoleController.text.trim(),
        enteredByCredentials: _enteredByCredentialsController.text.trim().isEmpty
            ? null
            : _enteredByCredentialsController.text.trim(),
        enteredByUserId: userId,
        verifiedByUserId: _status == 'clinician_verified' ? userId : null,
        verifiedAt: _status == 'clinician_verified' ? DateTime.now() : null,
      );

      await _service.save(label);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text(_editingId == null ? 'Label created.' : 'Label updated.'),
        ),
      );
      _clearForm();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteLabel(String id) async {
    try {
      await _service.delete(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Label deleted.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Widget _buildRow(VerificationLabelModel label) {
    final labelId = label.id; // nullable in the model, so guard before use.

    return Card(
      child: ListTile(
        title: Text('${label.entityType} / ${label.fieldName}'),
        subtitle: Text(
          [
            'Entity: ${label.entityId}',
            'Status: ${label.status}',
            if ((label.comment ?? '').trim().isNotEmpty) 'Comment: ${label.comment}',
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
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _entityTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Entity type',
                        hintText: 'allergies, medications, diagnoses...',
                      ),
                      validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _entityIdController,
                      decoration: const InputDecoration(
                        labelText: 'Entity ID',
                      ),
                      validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fieldNameController,
                      decoration: const InputDecoration(
                        labelText: 'Field name',
                      ),
                      validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'unverified',
                          child: Text('Unverified'),
                        ),
                        DropdownMenuItem(
                          value: 'user_entered',
                          child: Text('User entered'),
                        ),
                        DropdownMenuItem(
                          value: 'caregiver_entered',
                          child: Text('Caregiver entered'),
                        ),
                        DropdownMenuItem(
                          value: 'clinician_verified',
                          child: Text('Clinician verified'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _status = value ?? 'unverified'),
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
