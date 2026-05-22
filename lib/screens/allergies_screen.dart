import 'package:flutter/material.dart';

import '../models/allergy_model.dart';
import '../services/allergy_service.dart';
import '../services/patient_session_service.dart';
import '../utils/patient_access_context.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/medical_save_dialog.dart';

class AllergiesScreen extends StatefulWidget {
  final String? patientId;
  final bool canEdit;
  final bool isEmergencyOnly;

  const AllergiesScreen({
    super.key,
    this.patientId,
    this.canEdit = false,
    this.isEmergencyOnly = false,
  });

  @override
  State<AllergiesScreen> createState() => _AllergiesScreenState();
}

class _AllergiesScreenState extends State<AllergiesScreen> {
  final AllergyService _service = AllergyService();

  bool _loading = true;
  String? _patientId;
  List<AllergyModel> _items = [];
  late bool _canEdit;
  late bool _isEmergencyOnly;

  @override
  void initState() {
    super.initState();
    final session = PatientSessionService.instance.current;
    _canEdit = widget.canEdit || (session?.canEdit ?? false);
    _isEmergencyOnly =
        widget.isEmergencyOnly || (session?.isEmergencyOnly ?? false);
    _load();
  }

  String? _resolvePatientId() {
    if (widget.patientId != null && widget.patientId!.isNotEmpty) {
      return widget.patientId;
    }
    return PatientSessionService.instance.current?.patientId;
  }

  Future<void> _load() async {
    final patientId = _resolvePatientId();
    if (patientId == null || patientId.isEmpty) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final items = await _service.fetchByPatient(patientId);

    if (!mounted) return;
    setState(() {
      _patientId = patientId;
      _items = items;
      _loading = false;
    });
  }

  Future<void> _openEditor({AllergyModel? initial}) async {
    if (!_canEdit || _isEmergencyOnly) return;
    final patientId = _patientId;
    if (patientId == null) return;

    final allergenController =
    TextEditingController(text: initial?.allergenName ?? '');
    final reactionController =
    TextEditingController(text: initial?.reaction ?? '');
    final severityController =
    TextEditingController(text: initial?.severity ?? '');
    String allergyType = initial?.allergyType ?? 'other';
    String source = initial?.source ?? 'user';

    final saved = await showDialog(
      context: context,
      builder: (dialogContext) {
        return MedicalSaveDialog(
          title: initial == null ? 'Add allergy' : 'Edit allergy',
          validate: () => allergenController.text.trim().isEmpty
              ? 'Allergen is required.'
              : null,
          onSave: () async {
            final model = AllergyModel(
              id: initial?.id,
              patientId: patientId,
              allergenName: allergenController.text.trim(),
              allergyType: allergyType,
              reaction: reactionController.text.trim().isEmpty
                  ? null
                  : reactionController.text.trim(),
              // CHANGED: severity is now chosen from a list in the UI.
              severity: severityController.text.trim().isEmpty
                  ? null
                  : severityController.text.trim(),
              source: source,
            );
            final access = resolveScreenAccess(
              context: dialogContext,
              widgetPatientId: widget.patientId,
              widgetCanEdit: widget.canEdit,
              widgetIsEmergencyOnly: widget.isEmergencyOnly,
            );
            await _service.save(
              allergy: model,
              patientId: patientId,
              actorUserId: access.actorUserId,
              actorRole: access.actorRole,
            );
          },
          contentBuilder: (_, saving) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: allergenController,
                  enabled: !saving,
                  decoration: const InputDecoration(labelText: 'Allergen'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: allergyType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'food', child: Text('Food')),
                    DropdownMenuItem(
                      value: 'medication',
                      child: Text('Medication'),
                    ),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: saving ? null : (v) => allergyType = v ?? 'other',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reactionController,
                  enabled: !saving,
                  decoration: const InputDecoration(labelText: 'Reaction'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  // CHANGED: severity uses a list instead of free text.
                  initialValue: severityController.text.trim().isEmpty
                      ? null
                      : severityController.text.trim(),
                  decoration: const InputDecoration(labelText: 'Severity'),
                  items: const [
                    DropdownMenuItem(value: 'mild', child: Text('Mild')),
                    DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                    DropdownMenuItem(value: 'severe', child: Text('Severe')),
                  ],
                  onChanged: saving
                      ? null
                      : (v) => severityController.text = v ?? '',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: source,
                  decoration: const InputDecoration(labelText: 'Source'),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('User')),
                    DropdownMenuItem(
                      value: 'caregiver',
                      child: Text('Caregiver'),
                    ),
                    DropdownMenuItem(
                      value: 'clinician',
                      child: Text('Clinician'),
                    ),
                  ],
                  onChanged: saving ? null : (v) => source = v ?? 'user',
                ),
              ],
            );
          },
        );
      },
    );

    allergenController.dispose();
    reactionController.dispose();
    severityController.dispose();

    if (saved == true) await _load();
  }

  Future<void> _deleteItem(AllergyModel item) async {
    if (!_canEdit || _isEmergencyOnly) return;
    final patientId = _patientId;
    if (patientId == null || item.id == null) return;

    final confirmed = await showDeleteConfirmDialog(
      context: context,
      title: 'Delete allergy?',
      message: 'This action cannot be undone.',
    );

    if (!confirmed || !mounted) return;

    final access = resolveScreenAccess(
      context: context,
      widgetPatientId: widget.patientId,
      widgetCanEdit: widget.canEdit,
      widgetIsEmergencyOnly: widget.isEmergencyOnly,
    );
    await _service.delete(
      patientId: patientId,
      id: item.id!,
      actorUserId: access.actorUserId,
      actorRole: access.actorRole,
    );
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Allergies'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          if (_canEdit && !_isEmergencyOnly)
            IconButton(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patientId == null
          ? const Center(child: Text('No patient selected.'))
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            return Card(
              child: ListTile(
                title: Text(item.allergenName),
                subtitle: Text(
                  [
                    'Type: ${item.allergyType}',
                    if ((item.reaction ?? '').isNotEmpty)
                      'Reaction: ${item.reaction}',
                    if ((item.severity ?? '').isNotEmpty)
                      'Severity: ${item.severity}',
                    if ((item.source).isNotEmpty)
                      'Source: ${item.source}',
                  ].join('\n'),
                ),
                trailing: _canEdit && !_isEmergencyOnly
                    ? PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await _openEditor(initial: item);
                    } else if (value == 'delete') {
                      await _deleteItem(item);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}