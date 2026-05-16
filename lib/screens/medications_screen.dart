import 'package:flutter/material.dart';

import '../models/medication_model.dart';
import '../services/medication_service.dart';
import '../services/patient_session_service.dart';

class MedicationsScreen extends StatefulWidget {
  final String? patientId;
  final bool canEdit;
  final bool isEmergencyOnly;

  const MedicationsScreen({
    super.key,
    this.patientId,
    this.canEdit = false,
    this.isEmergencyOnly = false,
  });

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final MedicationService _service = MedicationService();

  bool _loading = true;
  String? _patientId;
  List<MedicationModel> _items = [];

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

  Future<void> _openEditor({MedicationModel? initial}) async {
    if (!widget.canEdit) return;

    final nameController = TextEditingController(text: initial?.medicationName ?? '');
    final dosageController = TextEditingController(text: initial?.dosage ?? '');
    final frequencyController = TextEditingController(text: initial?.frequency ?? '');
    final purposeController = TextEditingController(text: initial?.purpose ?? '');
    final startDateController = TextEditingController(
      text: initial?.startDate?.toIso8601String().split('T').first ?? '',
    );
    final endDateController = TextEditingController(
      text: initial?.endDate?.toIso8601String().split('T').first ?? '',
    );
    String source = initial?.source ?? 'user';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(initial == null ? 'Add medication' : 'Edit medication'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // The medication editor matches public.medications exactly.
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Medication name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dosageController,
                  decoration: const InputDecoration(labelText: 'Dosage'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: frequencyController,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: purposeController,
                  decoration: const InputDecoration(labelText: 'Purpose'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: startDateController,
                  decoration: const InputDecoration(labelText: 'Start date', hintText: 'YYYY-MM-DD'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endDateController,
                  decoration: const InputDecoration(labelText: 'End date', hintText: 'YYYY-MM-DD'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: source,
                  decoration: const InputDecoration(labelText: 'Source'),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('User')),
                    DropdownMenuItem(value: 'caregiver', child: Text('Caregiver')),
                    DropdownMenuItem(value: 'clinician', child: Text('Clinician')),
                  ],
                  onChanged: (v) => source = v ?? 'user',
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
      dosageController.dispose();
      frequencyController.dispose();
      purposeController.dispose();
      startDateController.dispose();
      endDateController.dispose();
      return;
    }

    final patientId = _patientId;
    if (patientId == null) return;

    final model = MedicationModel(
      id: initial?.id,
      patientId: patientId,
      medicationName: nameController.text.trim(),
      dosage: dosageController.text.trim().isEmpty ? null : dosageController.text.trim(),
      frequency: frequencyController.text.trim().isEmpty ? null : frequencyController.text.trim(),
      purpose: purposeController.text.trim().isEmpty ? null : purposeController.text.trim(),
      startDate: startDateController.text.trim().isEmpty
          ? null
          : DateTime.tryParse(startDateController.text.trim()),
      endDate: endDateController.text.trim().isEmpty
          ? null
          : DateTime.tryParse(endDateController.text.trim()),
      source: source,
    );

    await _service.save(medication: model, patientId: patientId);

    nameController.dispose();
    dosageController.dispose();
    frequencyController.dispose();
    purposeController.dispose();
    startDateController.dispose();
    endDateController.dispose();

    await _load();
  }

  Future<void> _deleteItem(MedicationModel item) async {
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
        title: const Text('Medications'),
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
                title: Text(item.medicationName),
                subtitle: Text([
                  if ((item.dosage ?? '').isNotEmpty) 'Dosage: ${item.dosage}',
                  if ((item.frequency ?? '').isNotEmpty) 'Frequency: ${item.frequency}',
                  if ((item.purpose ?? '').isNotEmpty) 'Purpose: ${item.purpose}',
                  if (item.startDate != null)
                    'Start: ${item.startDate!.toIso8601String().split('T').first}',
                  if (item.endDate != null)
                    'End: ${item.endDate!.toIso8601String().split('T').first}',
                  if ((item.source).isNotEmpty) 'Source: ${item.source}',
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