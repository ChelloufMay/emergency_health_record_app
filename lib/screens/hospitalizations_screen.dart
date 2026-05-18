import 'package:flutter/material.dart';

import '../models/hospitalization_model.dart';
import '../services/hospitalization_service.dart';
import '../services/patient_session_service.dart';
import '../widgets/medical_save_dialog.dart';

class HospitalizationsScreen extends StatefulWidget {
  final String? patientId;
  final bool canEdit;
  final bool isEmergencyOnly;

  const HospitalizationsScreen({
    super.key,
    this.patientId,
    this.canEdit = false,
    this.isEmergencyOnly = false,
  });

  @override
  State<HospitalizationsScreen> createState() => _HospitalizationsScreenState();
}

class _HospitalizationsScreenState extends State<HospitalizationsScreen> {
  final HospitalizationService _service = HospitalizationService();

  bool _loading = true;
  String? _patientId;
  List<HospitalizationModel> _items = [];

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

  Future<void> _openEditor({HospitalizationModel? initial}) async {
    if (!widget.canEdit) return;
    final patientId = _patientId;
    if (patientId == null) return;

    final hospitalNameController = TextEditingController(
      text: initial?.hospitalName ?? '',
    );
    final admissionDateController = TextEditingController(
      text: initial?.admissionDate?.toIso8601String().split('T').first ?? '',
    );
    final dischargeDateController = TextEditingController(
      text: initial?.dischargeDate?.toIso8601String().split('T').first ?? '',
    );
    final reasonController = TextEditingController(text: initial?.reason ?? '');
    final notesController = TextEditingController(text: initial?.notes ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return MedicalSaveDialog(
          title: initial == null
              ? 'Add hospitalization'
              : 'Edit hospitalization',
          validate: () => null,
          onSave: () async {
            final model = HospitalizationModel(
              id: initial?.id,
              patientId: patientId,
              hospitalName: hospitalNameController.text.trim().isEmpty
                  ? null
                  : hospitalNameController.text.trim(),
              admissionDate: admissionDateController.text.trim().isEmpty
                  ? null
                  : DateTime.tryParse(admissionDateController.text.trim()),
              dischargeDate: dischargeDateController.text.trim().isEmpty
                  ? null
                  : DateTime.tryParse(dischargeDateController.text.trim()),
              reason: reasonController.text.trim().isEmpty
                  ? null
                  : reasonController.text.trim(),
              notes: notesController.text.trim().isEmpty
                  ? null
                  : notesController.text.trim(),
            );

            await _service.save(hospitalization: model, patientId: patientId);
          },
          contentBuilder: (_, saving) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: hospitalNameController,
                  enabled: !saving,
                  decoration: const InputDecoration(labelText: 'Hospital name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: admissionDateController,
                  enabled: !saving,
                  decoration: const InputDecoration(
                    labelText: 'Admission date',
                    hintText: 'YYYY-MM-DD',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dischargeDateController,
                  enabled: !saving,
                  decoration: const InputDecoration(
                    labelText: 'Discharge date',
                    hintText: 'YYYY-MM-DD',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  enabled: !saving,
                  decoration: const InputDecoration(labelText: 'Reason'),
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

    hospitalNameController.dispose();
    admissionDateController.dispose();
    dischargeDateController.dispose();
    reasonController.dispose();
    notesController.dispose();

    if (saved == true) await _load();
  }

  Future<void> _deleteItem(HospitalizationModel item) async {
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
        title: const Text('Hospitalizations'),
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
                      title: Text(item.hospitalName ?? 'Hospitalization'),
                      subtitle: Text(
                        [
                          if (item.admissionDate != null)
                            'Admission: ${item.admissionDate!.toIso8601String().split('T').first}',
                          if (item.dischargeDate != null)
                            'Discharge: ${item.dischargeDate!.toIso8601String().split('T').first}',
                          if ((item.reason ?? '').isNotEmpty)
                            'Reason: ${item.reason}',
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
