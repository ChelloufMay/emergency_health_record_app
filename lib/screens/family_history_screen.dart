import 'package:flutter/material.dart';

import '../models/family_history_model.dart';
import '../services/family_history_service.dart';
import '../services/patient_session_service.dart';
import '../utils/patient_access_context.dart';
import '../utils/section_screen_access.dart';
import '../utils/field_helpers.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/medical_save_dialog.dart';

// Viewing and managing family medical history for a patient.
class FamilyHistoryScreen extends StatefulWidget {
  final String? patientId;
  final bool canEdit;
  final bool isEmergencyOnly;

  const FamilyHistoryScreen({
    super.key,
    this.patientId,
    this.canEdit = false,
    this.isEmergencyOnly = false,
  });

  @override
  State<FamilyHistoryScreen> createState() => _FamilyHistoryScreenState();
}

class _FamilyHistoryScreenState extends State<FamilyHistoryScreen> {
  final FamilyHistoryService _service = FamilyHistoryService();

  bool _loading = true;
  String? _patientId;
  List<FamilyHistoryModel> _items = [];

  static const List<String> _categories = <String>[
    'hereditary',
    'cardiovascular',
    'metabolic',
    'neurological',
    'respiratory',
    'cancer',
    'other',
  ];

  late SectionScreenAccess _access;

  @override
  void initState() {
    super.initState();

    PatientAccessContext.instance.addListener(
      _rebuildOnPermissionChange,
    );

    _access = SectionScreenAccess(
      widgetCanEdit: widget.canEdit,
      widgetIsEmergencyOnly: widget.isEmergencyOnly,
    );
    _load();
  }

  // Reloads the screen data when the patient access permissions change.
  void _rebuildOnPermissionChange() {
    if (!mounted) return;

    setState(() {
      _access = SectionScreenAccess(
        widgetCanEdit: widget.canEdit,
        widgetIsEmergencyOnly: widget.isEmergencyOnly,
      );
    });
  }

  @override
  void dispose() {
    PatientAccessContext.instance.removeListener(
      _rebuildOnPermissionChange,
    );
    super.dispose();
  }

  String? _resolvePatientId() =>
      widget.patientId ?? PatientSessionService.instance.current?.patientId;

  // Fetches the family history records for the current patient.
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

  // Opens a dialog to add or edit a family history entry.
  Future<void> _openEditor({FamilyHistoryModel? initial}) async {
    if (!_access.allowMutations) return;
    final patientId = _patientId;
    if (patientId == null) return;

    final relationController = TextEditingController(text: initial?.relation ?? '');
    final conditionController =
    TextEditingController(text: initial?.conditionName ?? '');
    final notesController = TextEditingController(text: initial?.notes ?? '');

    String category = initial?.category ?? 'unknown';
    bool? isGenetic = initial?.isGenetic;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return MedicalSaveDialog(
          title: initial == null ? 'Add family history' : 'Edit family history',
          validate: () {
            if (conditionController.text.trim().isEmpty) {
              return 'Condition name is required.';
            }
            return null;
          },
          onSave: () async {
            final model = FamilyHistoryModel(
              id: initial?.id,
              patientId: patientId,
              relation: relationController.text.trim().isEmpty
                  ? null
                  : relationController.text.trim(),
              conditionName: conditionController.text.trim(),
              category: category.trim().isEmpty ? 'unknown' : category.trim(),
              isGenetic: isGenetic,
              notes: notesController.text.trim().isEmpty
                  ? null
                  : notesController.text.trim(),
            );
            await _service.save(familyHistory: model, patientId: patientId);
          },
          contentBuilder: (_, saving) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: relationController,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Relation',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: conditionController,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Condition name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: [
                          const DropdownMenuItem(
                            value: 'unknown',
                            child: Text('None'),
                          ),
                          ..._categories.map(
                                (c) => DropdownMenuItem(value: c, child: Text(c)),
                          ),
                        ],
                        onChanged: saving
                            ? null
                            : (v) => setDialogState(() => category = v ?? 'unknown'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<bool?>(
                        initialValue: isGenetic,
                        decoration: const InputDecoration(labelText: 'Genetic'),
                        items: const [
                          DropdownMenuItem<bool?>(
                            value: null,
                            child: Text('None'),
                          ),
                          DropdownMenuItem<bool?>(
                            value: true,
                            child: Text('Yes'),
                          ),
                          DropdownMenuItem<bool?>(
                            value: false,
                            child: Text('No'),
                          ),
                        ],
                        onChanged: saving
                            ? null
                            : (v) => setDialogState(() => isGenetic = v),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesController,
                        enabled: !saving,
                        decoration: const InputDecoration(labelText: 'Notes'),
                        maxLines: 3,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    relationController.dispose();
    conditionController.dispose();
    notesController.dispose();

    if (saved == true) {
      await _load();
    }
  }

  // Deletes a specific family history entry after user confirmation.
  Future<void> _deleteItem(FamilyHistoryModel item) async {
    if (!_access.allowMutations) return;
    final patientId = _patientId;
    if (patientId == null || item.id == null) return;

    // Confirmation before delete
    final confirmed = await showDeleteConfirmDialog(
      context: context,
      title: 'Delete family history item?',
      message: 'This action cannot be undone.',
    );

    if (!confirmed || !mounted) return;

    await _service.delete(patientId: patientId, id: item.id!);
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family history'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          if (_access.allowMutations)
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
                title: Text(item.conditionName),
                subtitle: Text(
                  [
                    if ((item.relation ?? '').isNotEmpty)
                      'Relation: ${item.relation}',
                    'Category: ${displayUnknownAsNone(item.category)}',
                    'Genetic: ${yesNo(item.isGenetic)}',
                    if ((item.notes ?? '').isNotEmpty)
                      'Notes: ${item.notes}',
                  ].join('\n'),
                ),
                trailing: _access.allowMutations
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