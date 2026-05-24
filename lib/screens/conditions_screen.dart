import 'package:flutter/material.dart';

import '../models/medical_condition_model.dart';
import '../services/medical_condition_service.dart';
import '../services/patient_session_service.dart';
import '../utils/patient_access_context.dart';
import '../utils/section_screen_access.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/medical_save_dialog.dart';

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
    if (!_access.allowMutations) return;
    final patientId = _patientId;
    if (patientId == null) return;

    final nameController =
    TextEditingController(text: initial?.conditionName ?? '');
    final diagnosisPlaceController =
    TextEditingController(text: initial?.diagnosisPlace ?? '');
    final followUpDoctorController =
    TextEditingController(text: initial?.followUpDoctor ?? '');
    final treatmentController =
    TextEditingController(text: initial?.treatment ?? '');
    final notesController = TextEditingController(text: initial?.notes ?? '');

    DateTime? diagnosisDate = initial?.diagnosisDate;
    String type = initial?.type ?? 'chronic';

    final saved = await showDialog(
      context: context,
      builder: (dialogContext) {
        return MedicalSaveDialog(
          title: initial == null ? 'Add condition' : 'Edit condition',
          validate: () => nameController.text.trim().isEmpty
              ? 'Condition name is required.'
              : null,
          onSave: () async {
            final model = MedicalConditionModel(
              id: initial?.id,
              patientId: patientId,
              conditionName: nameController.text.trim(),
              type: type,
              diagnosisDate: diagnosisDate,
              diagnosisPlace: diagnosisPlaceController.text.trim().isEmpty
                  ? null
                  : diagnosisPlaceController.text.trim(),
              followUpDoctor: followUpDoctorController.text.trim().isEmpty
                  ? null
                  : followUpDoctorController.text.trim(),
              treatment: treatmentController.text.trim().isEmpty
                  ? null
                  : treatmentController.text.trim(),
              notes: notesController.text.trim().isEmpty
                  ? null
                  : notesController.text.trim(),
            );
            await _service.save(condition: model, patientId: patientId);
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
                        labelText: 'Condition name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(
                          value: 'chronic',
                          child: Text('Chronic'),
                        ),
                        DropdownMenuItem(value: 'acute', child: Text('Acute')),
                      ],
                      onChanged: saving ? null : (v) => type = v ?? 'chronic',
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Diagnosis date'),
                      subtitle: Text(
                        diagnosisDate == null
                            ? 'Not set'
                            : diagnosisDate!.toIso8601String().split('T').first,
                      ),
                      trailing: IconButton(
                        onPressed: saving
                            ? null
                            : () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                            initialDate: diagnosisDate ?? DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => diagnosisDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_month),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: diagnosisPlaceController,
                      enabled: !saving,
                      decoration: const InputDecoration(
                        labelText: 'Diagnosis place',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: followUpDoctorController,
                      enabled: !saving,
                      decoration: const InputDecoration(
                        labelText: 'Follow up doctor',
                        hintText: "doctor's name",
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: treatmentController,
                      enabled: !saving,
                      decoration: const InputDecoration(labelText: 'Treatment'),
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
      },
    );

    nameController.dispose();
    diagnosisPlaceController.dispose();
    followUpDoctorController.dispose();
    treatmentController.dispose();
    notesController.dispose();

    if (saved == true) await _load();
  }

  Future<void> _deleteItem(MedicalConditionModel item) async {
    if (!_access.allowMutations) return;
    final patientId = _patientId;
    if (patientId == null || item.id == null) return;

    final confirmed = await showDeleteConfirmDialog(
      context: context,
      title: 'Delete condition?',
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
        title: const Text('Conditions'),
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
                    'Type: ${item.type}',
                    if (item.diagnosisDate != null)
                      'Diagnosis date: ${item.diagnosisDate!.toIso8601String().split('T').first}',
                    if ((item.diagnosisPlace ?? '').isNotEmpty)
                      'Place: ${item.diagnosisPlace}',
                    if ((item.followUpDoctor ?? '').isNotEmpty)
                      'Doctor: ${item.followUpDoctor}',
                    if ((item.treatment ?? '').isNotEmpty)
                      'Treatment: ${item.treatment}',
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