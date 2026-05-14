import 'package:flutter/material.dart';

import '../models/allergy_model.dart';
import '../services/allergy_service.dart';
import '../services/patient_session_service.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? _resolvePatientId() {
    return widget.patientId ?? PatientSessionService.instance.current?.patientId;
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
    if (!widget.canEdit) return;

    final allergenController = TextEditingController(text: initial?.allergenName ?? '');
    final reactionController = TextEditingController(text: initial?.reaction ?? '');
    final severityController = TextEditingController(text: initial?.severity ?? '');
    String allergyType = initial?.allergyType ?? 'other';
    String source = initial?.source ?? 'user';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(initial == null ? 'Add allergy' : 'Edit allergy'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: allergenController, decoration: const InputDecoration(labelText: 'Allergen')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: allergyType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'food', child: Text('Food')),
                    DropdownMenuItem(value: 'medication', child: Text('Medication')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => allergyType = v ?? 'other',
                ),
                const SizedBox(height: 12),
                TextField(controller: reactionController, decoration: const InputDecoration(labelText: 'Reaction')),
                const SizedBox(height: 12),
                TextField(controller: severityController, decoration: const InputDecoration(labelText: 'Severity')),
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
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save')),
          ],
        );
      },
    );

    allergenController.dispose();
    reactionController.dispose();
    severityController.dispose();

    if (saved != true) return;

    final patientId = _patientId;
    if (patientId == null) return;

    final model = AllergyModel(
      id: initial?.id,
      patientId: patientId,
      allergenName: allergenController.text.trim().isEmpty ? (initial?.allergenName ?? '') : allergenController.text.trim(),
      allergyType: allergyType,
      reaction: reactionController.text.trim().isEmpty ? null : reactionController.text.trim(),
      severity: severityController.text.trim().isEmpty ? null : severityController.text.trim(),
      source: source,
    );

    await _service.save(
      allergy: model,
      patientId: patientId,
      performedByUserId: 'current',
    );

    await _load();
  }

  Future<void> _deleteItem(AllergyModel item) async {
    if (!widget.canEdit) return;
    final patientId = _patientId;
    if (patientId == null || item.id == null) return;

    await _service.delete(
      patientId: patientId,
      id: item.id!,
      performedByUserId: 'current',
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Allergies'),
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
                title: Text(item.allergenName),
                subtitle: Text([
                  'Type: ${item.allergyType}',
                  if ((item.reaction ?? '').isNotEmpty) 'Reaction: ${item.reaction}',
                  if ((item.severity ?? '').isNotEmpty) 'Severity: ${item.severity}',
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