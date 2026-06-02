// Managing and viewing a patient's medications.
import 'package:flutter/material.dart';

import '../models/medication_model.dart';
import '../services/medication_service.dart';
import '../services/patient_session_service.dart';
import '../utils/patient_access_context.dart';
import '../utils/section_screen_access.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/medical_save_dialog.dart';

// Screen for displaying and editing patient medications.
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
  late SectionScreenAccess _access;

  @override
  void initState() {
    // Listen for global permission changes.
    super.initState();

    PatientAccessContext.instance.addListener(_rebuildOnPermissionChange);

    _access = SectionScreenAccess(
      widgetCanEdit: widget.canEdit,
      widgetIsEmergencyOnly: widget.isEmergencyOnly,
    );

    _load();
  }

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
    PatientAccessContext.instance.removeListener(_rebuildOnPermissionChange);

    super.dispose();
  }

  String? _resolvePatientId() =>
      widget.patientId ?? PatientSessionService.instance.current?.patientId;

  /// Loads medications from the service.
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

  /// Helper to pick a date from a date picker.
  Future<void> _pickDate({
    required BuildContext context,
    required DateTime? initialDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDate: initialDate ?? DateTime.now(),
    );
    if (picked != null) onPicked(picked);
  }

  /// Opens a dialog to create or update a medication entry.
  Future<void> _openEditor({MedicationModel? initial}) async {
    if (!_access.allowMutations) return;
    final patientId = _patientId;
    if (patientId == null) return;

    final nameController = TextEditingController(
      text: initial?.medicationName ?? '',
    );
    final dosageController = TextEditingController(text: initial?.dosage ?? '');
    final frequencyController = TextEditingController(
      text: initial?.frequency ?? '',
    );
    final purposeController = TextEditingController(
      text: initial?.purpose ?? '',
    );

    DateTime? startDate = initial?.startDate;
    DateTime? endDate = initial?.endDate;
    String source = initial?.source ?? 'user';

    final saved = await showDialog(
      context: context,
      builder: (dialogContext) {
        return MedicalSaveDialog(
          title: initial == null ? 'Add medication' : 'Edit medication',
          validate: () => nameController.text.trim().isEmpty
              ? 'Medication name is required.'
              : null,
          onSave: () async {
            final model = MedicationModel(
              id: initial?.id,
              patientId: patientId,
              medicationName: nameController.text.trim(),
              dosage: dosageController.text.trim().isEmpty
                  ? null
                  : dosageController.text.trim(),
              frequency: frequencyController.text.trim().isEmpty
                  ? null
                  : frequencyController.text.trim(),
              purpose: purposeController.text.trim().isEmpty
                  ? null
                  : purposeController.text.trim(),
              startDate: startDate,
              endDate: endDate,
              source: source,
            );
            await _service.save(medication: model, patientId: patientId);
          },
          contentBuilder: (context, saving) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      enabled: !saving,
                      decoration: const InputDecoration(
                        labelText: 'Medication name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dosageController,
                      enabled: !saving,
                      decoration: const InputDecoration(labelText: 'Dosage'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: frequencyController,
                      enabled: !saving,
                      decoration: const InputDecoration(labelText: 'Frequency'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: purposeController,
                      enabled: !saving,
                      decoration: const InputDecoration(labelText: 'Purpose'),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Start date'),
                      subtitle: Text(
                        startDate == null
                            ? 'Not set'
                            : startDate!.toIso8601String().split('T').first,
                      ),
                      trailing: IconButton(
                        onPressed: saving
                            ? null
                            : () => _pickDate(
                                context: context,
                                initialDate: startDate,
                                onPicked: (d) {
                                  setDialogState(() => startDate = d);
                                },
                              ),
                        icon: const Icon(Icons.calendar_month),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('End date'),
                      subtitle: Text(
                        endDate == null
                            ? 'Not set'
                            : endDate!.toIso8601String().split('T').first,
                      ),
                      trailing: IconButton(
                        onPressed: saving
                            ? null
                            : () => _pickDate(
                                context: context,
                                initialDate: endDate,
                                onPicked: (d) {
                                  setDialogState(() => endDate = d);
                                },
                              ),
                        icon: const Icon(Icons.calendar_month),
                      ),
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
      },
    );

    nameController.dispose();
    dosageController.dispose();
    frequencyController.dispose();
    purposeController.dispose();

    if (saved == true) await _load();
  }

  /// Deletes a specific medication record.
  Future<void> _deleteItem(MedicationModel item) async {
    if (!_access.allowMutations) return;
    final patientId = _patientId;
    if (patientId == null || item.id == null) return;

    final confirmed = await showDeleteConfirmDialog(
      context: context,
      title: 'Delete medication?',
      message: 'This action cannot be undone.',
    );

    if (!confirmed || !mounted) return;

    await _service.delete(patientId: patientId, id: item.id!);
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    // Builds the list of medications or a loading indicator.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
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
                      title: Text(item.medicationName),

                      subtitle: Text(
                        [
                          if ((item.dosage ?? '').isNotEmpty)
                            'Dosage: ${item.dosage}',
                          if ((item.frequency ?? '').isNotEmpty)
                            'Frequency: ${item.frequency}',
                          if ((item.purpose ?? '').isNotEmpty)
                            'Purpose: ${item.purpose}',
                          if (item.startDate != null)
                            'Start: ${item.startDate!.toIso8601String().split('T').first}',
                          if (item.endDate != null)
                            'End: ${item.endDate!.toIso8601String().split('T').first}',
                          if ((item.source).isNotEmpty)
                            'Source: ${item.source}',
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
