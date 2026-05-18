import 'package:flutter/material.dart';

import '../models/family_history_model.dart';
import '../services/family_history_service.dart';
import '../services/patient_session_service.dart';
import '../widgets/medical_save_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? _resolvePatientId() =>
      widget.patientId ?? PatientSessionService.instance.current?.patientId;

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

  Future<void> _openEditor({FamilyHistoryModel? initial}) async {
    if (!widget.canEdit) return;
    final patientId = _patientId;
    if (patientId == null) return;

    final relationController = TextEditingController(
      text: initial?.relation ?? '',
    );
    final conditionController = TextEditingController(
      text: initial?.conditionName ?? '',
    );
    final categoryController = TextEditingController(
      text: initial?.category ?? '',
    );
    final notesController = TextEditingController(text: initial?.notes ?? '');
    bool? isGenetic = initial?.isGenetic;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return MedicalSaveDialog(
          title: initial == null ? 'Add family history' : 'Edit family history',
          validate: () => conditionController.text.trim().isEmpty
              ? 'Condition name is required.'
              : null,
          onSave: () async {
            final model = FamilyHistoryModel(
              id: initial?.id,
              patientId: patientId,
              relation: relationController.text.trim().isEmpty
                  ? null
                  : relationController.text.trim(),
              conditionName: conditionController.text.trim(),
              category: categoryController.text.trim().isEmpty
                  ? null
                  : categoryController.text.trim(),
              isGenetic: isGenetic,
              notes: notesController.text.trim().isEmpty
                  ? null
                  : notesController.text.trim(),
            );

            await _service.save(familyHistory: model, patientId: patientId);
          },
          contentBuilder: (_, saving) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: relationController,
                  enabled: !saving,
                  decoration: const InputDecoration(labelText: 'Relation'),
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
                TextField(
                  controller: categoryController,
                  enabled: !saving,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<bool?>(
                  initialValue: isGenetic,
                  decoration: const InputDecoration(labelText: 'Genetic'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Unknown')),
                    DropdownMenuItem(value: true, child: Text('Yes')),
                    DropdownMenuItem(value: false, child: Text('No')),
                  ],
                  onChanged: saving ? null : (v) => isGenetic = v,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  enabled: !saving,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                ),
              ],
            );
          },
        );
      },
    );

    relationController.dispose();
    conditionController.dispose();
    categoryController.dispose();
    notesController.dispose();

    if (saved == true) await _load();
  }

  Future<void> _deleteItem(FamilyHistoryModel item) async {
    if (!widget.canEdit) return;
    final patientId = _patientId;
    if (patientId == null || item.id == null) return;

    await _service.delete(patientId: patientId, id: item.id!);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family history'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          if (widget.canEdit)
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
                          if ((item.category ?? '').isNotEmpty)
                            'Category: ${item.category}',
                          if (item.isGenetic != null)
                            'Genetic: ${item.isGenetic}',
                          if ((item.notes ?? '').isNotEmpty)
                            'Notes: ${item.notes}',
                        ].join('\n'),
                      ),
                      trailing: widget.canEdit
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
