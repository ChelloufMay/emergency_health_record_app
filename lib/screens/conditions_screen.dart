import 'package:flutter/material.dart';

import '../models/medical_condition_model.dart';
import '../services/medical_condition_service.dart';
import '../services/patient_session_service.dart';

class ConditionsScreen extends StatefulWidget {
  final String? patientId;
  final bool canEdit;
  final bool isEmergencyOnly;

  const ConditionsScreen({
    super.key,
    this.patientId,
    this.canEdit = false,
    this.isEmergencyOnly = false,
  });

  @override
  State<ConditionsScreen> createState() => _ConditionsScreenState();
}

class _ConditionsScreenState extends State<ConditionsScreen> {
  final MedicalConditionService _service = MedicalConditionService();

  bool _loading = true;
  String? _patientId;
  List<MedicalConditionModel> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? _resolvePatientId() => widget.patientId ?? PatientSessionService.instance.current?.patientId;

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

  Future<void> _openEditor({MedicalConditionModel? initial}) async {
    if (!widget.canEdit) return;

    final nameController = TextEditingController(text: initial?.conditionName ?? '');
    final diagnosisPlaceController = TextEditingController(text: initial?.diagnosisPlace ?? '');
    final followUpDoctorController = TextEditingController(text: initial?.followUpDoctor ?? '');
    final treatmentController = TextEditingController(text: initial?.treatment ?? '');
    final notesController = TextEditingController(text: initial?.notes ?? '');
    final diagnosisDateController = TextEditingController(
      text: initial?.diagnosisDate?.toIso8601String().split('T').first ?? '',
    );
    String type = initial?.type ?? 'chronic';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(initial == null ? 'Add condition' : 'Edit condition'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // This form maps directly to public.medical_conditions.
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Condition name'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'chronic', child: Text('Chronic')),
                    DropdownMenuItem(value: 'acute', child: Text('Acute')),
                  ],
                  onChanged: (v) => type = v ?? 'chronic',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: diagnosisDateController,
                  decoration: const InputDecoration(labelText: 'Diagnosis date', hintText: 'YYYY-MM-DD'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: diagnosisPlaceController,
                  decoration: const InputDecoration(labelText: 'Diagnosis place'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: followUpDoctorController,
                  decoration: const InputDecoration(labelText: 'Follow-up doctor'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: treatmentController,
                  decoration: const InputDecoration(labelText: 'Treatment'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved != true) {
      nameController.dispose();
      diagnosisPlaceController.dispose();
      followUpDoctorController.dispose();
      treatmentController.dispose();
      notesController.dispose();
      diagnosisDateController.dispose();
      return;
    }

    final patientId = _patientId;
    if (patientId == null) return;

    final model = MedicalConditionModel(
      id: initial?.id,
      patientId: patientId,
      conditionName: nameController.text.trim(),
      type: type,
      diagnosisDate: diagnosisDateController.text.trim().isEmpty
          ? null
          : DateTime.tryParse(diagnosisDateController.text.trim()),
      diagnosisPlace: diagnosisPlaceController.text.trim().isEmpty ? null : diagnosisPlaceController.text.trim(),
      followUpDoctor: followUpDoctorController.text.trim().isEmpty ? null : followUpDoctorController.text.trim(),
      treatment: treatmentController.text.trim().isEmpty ? null : treatmentController.text.trim(),
      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
    );

    await _service.save(condition: model, patientId: patientId);

    nameController.dispose();
    diagnosisPlaceController.dispose();
    followUpDoctorController.dispose();
    treatmentController.dispose();
    notesController.dispose();
    diagnosisDateController.dispose();

    await _load();
  }

  Future<void> _deleteItem(MedicalConditionModel item) async {
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
        title: const Text('Conditions'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          if (widget.canEdit)
            IconButton(onPressed: () => _openEditor(), icon: const Icon(Icons.add)),
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
                subtitle: Text([
                  'Type: ${item.type}',
                  if (item.diagnosisDate != null)
                    'Diagnosis date: ${item.diagnosisDate!.toIso8601String().split('T').first}',
                  if ((item.diagnosisPlace ?? '').isNotEmpty) 'Place: ${item.diagnosisPlace}',
                  if ((item.followUpDoctor ?? '').isNotEmpty) 'Doctor: ${item.followUpDoctor}',
                  if ((item.treatment ?? '').isNotEmpty) 'Treatment: ${item.treatment}',
                ].join('\n')),
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
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
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