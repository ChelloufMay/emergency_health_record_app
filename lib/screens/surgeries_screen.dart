import 'package:flutter/material.dart';

import '../models/surgery_model.dart';
import '../services/patient_session_service.dart';
import '../services/surgery_service.dart';
import '../widgets/medical_save_dialog.dart';

class SurgeriesScreen extends StatefulWidget {
  final String? patientId;
  final bool canEdit;
  final bool isEmergencyOnly;

  const SurgeriesScreen({
    super.key,
    this.patientId,
    this.canEdit = false,
    this.isEmergencyOnly = false,
  });

  @override
  State<SurgeriesScreen> createState() => _SurgeriesScreenState();
}

class _SurgeriesScreenState extends State<SurgeriesScreen> {
  final SurgeryService _service = SurgeryService();

  bool _loading = true;
  String? _patientId;
  List<SurgeryModel> _items = [];

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

  Future<void> _openEditor({SurgeryModel? initial}) async {
    if (!widget.canEdit) return;
    final patientId = _patientId;
    if (patientId == null) return;

    final nameController = TextEditingController(
      text: initial?.surgeryName ?? '',
    );
    final dateController = TextEditingController(
      text: initial?.surgeryDate?.toIso8601String().split('T').first ?? '',
    );
    final placeController = TextEditingController(text: initial?.place ?? '');
    final implantController = TextEditingController(
      text: initial?.prostheticOrImplant ?? '',
    );
    final notesController = TextEditingController(text: initial?.notes ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return MedicalSaveDialog(
          title: initial == null ? 'Add surgery' : 'Edit surgery',
          validate: () => nameController.text.trim().isEmpty
              ? 'Surgery name is required.'
              : null,
          onSave: () async {
            final model = SurgeryModel(
              id: initial?.id,
              patientId: patientId,
              surgeryName: nameController.text.trim(),
              surgeryDate: dateController.text.trim().isEmpty
                  ? null
                  : DateTime.tryParse(dateController.text.trim()),
              place: placeController.text.trim().isEmpty
                  ? null
                  : placeController.text.trim(),
              prostheticOrImplant: implantController.text.trim().isEmpty
                  ? null
                  : implantController.text.trim(),
              notes: notesController.text.trim().isEmpty
                  ? null
                  : notesController.text.trim(),
            );

            await _service.save(surgery: model, patientId: patientId);
          },
          contentBuilder: (_, saving) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  enabled: !saving,
                  decoration: const InputDecoration(labelText: 'Surgery name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dateController,
                  enabled: !saving,
                  decoration: const InputDecoration(
                    labelText: 'Surgery date',
                    hintText: 'YYYY-MM-DD',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: placeController,
                  enabled: !saving,
                  decoration: const InputDecoration(labelText: 'Place'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: implantController,
                  enabled: !saving,
                  decoration: const InputDecoration(
                    labelText: 'Prosthetic / implant',
                  ),
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

    nameController.dispose();
    dateController.dispose();
    placeController.dispose();
    implantController.dispose();
    notesController.dispose();

    if (saved == true) await _load();
  }

  Future<void> _deleteItem(SurgeryModel item) async {
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
        title: const Text('Surgeries'),
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
                      title: Text(item.surgeryName),
                      subtitle: Text(
                        [
                          if (item.surgeryDate != null)
                            'Date: ${item.surgeryDate!.toIso8601String().split('T').first}',
                          if ((item.place ?? '').isNotEmpty)
                            'Place: ${item.place}',
                          if ((item.prostheticOrImplant ?? '').isNotEmpty)
                            'Implant: ${item.prostheticOrImplant}',
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
