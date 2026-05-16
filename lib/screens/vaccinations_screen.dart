import 'package:flutter/material.dart';

import '../models/vaccination_model.dart';
import '../services/patient_session_service.dart';
import '../services/vaccination_service.dart';

class VaccinationsScreen extends StatefulWidget {
  final String? patientId;
  final bool canEdit;
  final bool isEmergencyOnly;

  const VaccinationsScreen({
    super.key,
    this.patientId,
    this.canEdit = false,
    this.isEmergencyOnly = false,
  });

  @override
  State<VaccinationsScreen> createState() => _VaccinationsScreenState();
}

class _VaccinationsScreenState extends State<VaccinationsScreen> {
  final VaccinationService _service = VaccinationService();

  bool _loading = true;
  String? _patientId;
  List<VaccinationModel> _items = [];

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

  Future<void> _openEditor({VaccinationModel? initial}) async {
    if (!widget.canEdit) return;

    final nameController = TextEditingController(text: initial?.vaccineName ?? '');
    final doseController = TextEditingController(text: initial?.doseNumber?.toString() ?? '');
    final dateController = TextEditingController(
      text: initial?.dateAdministered?.toIso8601String().split('T').first ?? '',
    );
    final notesController = TextEditingController(text: initial?.notes ?? '');
    String category = initial?.category ?? 'other';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(initial == null ? 'Add vaccination' : 'Edit vaccination'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Vaccinations are standalone rows in public.vaccinations.
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Vaccine name'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'covid', child: Text('COVID')),
                    DropdownMenuItem(value: 'pnv', child: Text('PNV')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => category = v ?? 'other',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: doseController,
                  decoration: const InputDecoration(labelText: 'Dose number'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(labelText: 'Date administered', hintText: 'YYYY-MM-DD'),
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
      doseController.dispose();
      dateController.dispose();
      notesController.dispose();
      return;
    }

    final patientId = _patientId;
    if (patientId == null) return;

    final model = VaccinationModel(
      id: initial?.id,
      patientId: patientId,
      vaccineName: nameController.text.trim(),
      category: category,
      doseNumber: int.tryParse(doseController.text.trim()),
      dateAdministered: dateController.text.trim().isEmpty
          ? null
          : DateTime.tryParse(dateController.text.trim()),
      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
    );

    await _service.save(vaccination: model, patientId: patientId);

    nameController.dispose();
    doseController.dispose();
    dateController.dispose();
    notesController.dispose();

    await _load();
  }

  Future<void> _deleteItem(VaccinationModel item) async {
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
        title: const Text('Vaccinations'),
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
                title: Text(item.vaccineName),
                subtitle: Text([
                  'Category: ${item.category}',
                  if (item.doseNumber != null) 'Dose: ${item.doseNumber}',
                  if (item.dateAdministered != null)
                    'Date: ${item.dateAdministered!.toIso8601String().split('T').first}',
                  if ((item.notes ?? '').isNotEmpty) 'Notes: ${item.notes}',
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