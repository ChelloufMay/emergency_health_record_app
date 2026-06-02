import 'package:flutter/material.dart';

import '../models/reproductive_health_model.dart';
import '../services/patient_session_service.dart';
import '../services/reproductive_health_service.dart';
import '../utils/patient_access_context.dart';
import '../utils/section_screen_access.dart';
import '../utils/field_helpers.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/medical_save_dialog.dart';

// Viewing and managing reproductive health information for a patient.
class ReproductiveHealthScreen extends StatefulWidget {
  final String? patientId;
  final bool canEdit;
  final bool isEmergencyOnly;

  const ReproductiveHealthScreen({
    super.key,
    this.patientId,
    this.canEdit = false,
    this.isEmergencyOnly = false,
  });

  @override
  State<ReproductiveHealthScreen> createState() =>
      _ReproductiveHealthScreenState();
}

class _ReproductiveHealthScreenState extends State<ReproductiveHealthScreen> {
  final ReproductiveHealthService _service = ReproductiveHealthService();

  bool _loading = true;
  String? _patientId;
  ReproductiveHealthModel? _item;
  late SectionScreenAccess _access;

  @override
  void initState() {
    super.initState();

    PatientAccessContext.instance.addListener(_rebuildOnPermissionChange);

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
    PatientAccessContext.instance.removeListener(_rebuildOnPermissionChange);

    super.dispose();
  }

  String? _resolvePatientId() =>
      widget.patientId ?? PatientSessionService.instance.current?.patientId;

  // Fetches the reproductive health record for the current patient
  Future<void> _load() async {
    final patientId = _resolvePatientId();
    if (patientId == null || patientId.isEmpty) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final item = await _service.fetchByPatient(patientId);
    if (!mounted) return;

    setState(() {
      _patientId = patientId;
      _item = item;
      _loading = false;
    });
  }

  // Opens a dialog to add or edit the reproductive health record
  Future<void> _edit() async {
    if (!_access.allowMutations) return;
    final patientId = _patientId;
    if (patientId == null) return;

    final current = _item;

    bool? hasMenstrualCycle = current?.hasMenstrualCycle;
    bool? cycleRegular = current?.cycleRegular;
    bool? cyclePainful = current?.cyclePainful;
    bool? currentlyPregnant = current?.currentlyPregnant;

    final painLevelValue = double.tryParse(current?.painLevel ?? '') ?? 0;
    double painLevel = painLevelValue.clamp(0, 10).toDouble();

    DateTime? lastPeriodStart = current?.lastPeriodStart;
    DateTime? lastPeriodEnd = current?.lastPeriodEnd;

    final pregnancyTermWeeksController = TextEditingController(
      text: current?.pregnancyTermWeeks?.toString() ?? '',
    );
    final gestityController = TextEditingController(
      text: current?.gestity?.toString() ?? '',
    );
    final parityController = TextEditingController(
      text: current?.parity?.toString() ?? '',
    );
    final abortionsController = TextEditingController(
      text: current?.abortions?.toString() ?? '',
    );
    final pubertyAgeController = TextEditingController(
      text: current?.pubertyAge?.toString() ?? '',
    );
    final breastExamNotesController = TextEditingController(
      text: current?.breastExamNotes ?? '',
    );
    final pregnancyHistoryController = TextEditingController(
      text: current?.pregnancyHistory ?? '',
    );
    final birthHistoryController = TextEditingController(
      text: current?.birthHistory ?? '',
    );
    final abortionHistoryController = TextEditingController(
      text: current?.abortionHistory ?? '',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return MedicalSaveDialog(
          title: current == null
              ? 'Add reproductive health'
              : 'Edit reproductive health',
          validate: () => null,
          onSave: () async {
            final model = ReproductiveHealthModel(
              id: current?.id,
              patientId: patientId,
              hasMenstrualCycle: hasMenstrualCycle,
              cycleRegular: cycleRegular,
              cyclePainful: cyclePainful,
              painLevel: painLevel.round().toString(),
              lastPeriodStart: lastPeriodStart,
              lastPeriodEnd: lastPeriodEnd,
              currentlyPregnant: currentlyPregnant,
              pregnancyTermWeeks: int.tryParse(
                pregnancyTermWeeksController.text.trim(),
              ),
              gestity: int.tryParse(gestityController.text.trim()),
              parity: int.tryParse(parityController.text.trim()),
              abortions: int.tryParse(abortionsController.text.trim()),
              pubertyAge: int.tryParse(pubertyAgeController.text.trim()),
              breastExamNotes: breastExamNotesController.text.trim().isEmpty
                  ? null
                  : breastExamNotesController.text.trim(),
              pregnancyHistory: pregnancyHistoryController.text.trim().isEmpty
                  ? null
                  : pregnancyHistoryController.text.trim(),
              birthHistory: birthHistoryController.text.trim().isEmpty
                  ? null
                  : birthHistoryController.text.trim(),
              abortionHistory: abortionHistoryController.text.trim().isEmpty
                  ? null
                  : abortionHistoryController.text.trim(),
            );
            await _service.save(
              reproductiveHealth: model,
              patientId: patientId,
            );
          },
          contentBuilder: (_, saving) {
            DropdownButtonFormField<bool?> boolField(
              String label,
              bool? value,
              void Function(bool?) onChanged,
            ) {
              return DropdownButtonFormField<bool?>(
                initialValue: value,
                decoration: InputDecoration(labelText: label),
                items: const [
                  DropdownMenuItem<bool?>(value: null, child: Text('None')),
                  DropdownMenuItem<bool?>(value: true, child: Text('Yes')),
                  DropdownMenuItem<bool?>(value: false, child: Text('No')),
                ],
                onChanged: saving ? null : onChanged,
              );
            }

            return StatefulBuilder(
              builder: (context, setDialogState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      boolField('Has menstrual cycle', hasMenstrualCycle, (v) {
                        setDialogState(() => hasMenstrualCycle = v);
                      }),
                      const SizedBox(height: 12),
                      boolField('Cycle regular', cycleRegular, (v) {
                        setDialogState(() => cycleRegular = v);
                      }),
                      const SizedBox(height: 12),
                      boolField('Cycle painful', cyclePainful, (v) {
                        setDialogState(() => cyclePainful = v);
                      }),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(child: Text('Pain level')),
                          Text(painLevel.round().toString()),
                        ],
                      ),
                      Slider(
                        value: painLevel,
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: painLevel.round().toString(),
                        onChanged: saving
                            ? null
                            : (v) => setDialogState(() => painLevel = v),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Last period start'),
                        subtitle: Text(
                          lastPeriodStart == null
                              ? 'Not set'
                              : lastPeriodStart!
                                    .toIso8601String()
                                    .split('T')
                                    .first,
                        ),
                        trailing: IconButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                    initialDate:
                                        lastPeriodStart ?? DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setDialogState(
                                      () => lastPeriodStart = picked,
                                    );
                                  }
                                },
                          icon: const Icon(Icons.calendar_month),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Last period end'),
                        subtitle: Text(
                          lastPeriodEnd == null
                              ? 'Not set'
                              : lastPeriodEnd!
                                    .toIso8601String()
                                    .split('T')
                                    .first,
                        ),
                        trailing: IconButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                    initialDate:
                                        lastPeriodEnd ?? DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setDialogState(
                                      () => lastPeriodEnd = picked,
                                    );
                                  }
                                },
                          icon: const Icon(Icons.calendar_month),
                        ),
                      ),
                      const SizedBox(height: 12),
                      boolField('Currently pregnant', currentlyPregnant, (v) {
                        setDialogState(() => currentlyPregnant = v);
                      }),
                      const SizedBox(height: 12),
                      TextField(
                        controller: pregnancyTermWeeksController,
                        enabled: !saving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Pregnancy term weeks',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: gestityController,
                        enabled: !saving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Gestity',
                          hintText: 'Total number of pregnancies',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: parityController,
                        enabled: !saving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Parity',
                          hintText: 'Number of births after viability',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: abortionsController,
                        enabled: !saving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Abortions',
                          hintText: 'Number of pregnancy losses',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: pubertyAgeController,
                        enabled: !saving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Puberty age',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: breastExamNotesController,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Breast exam notes',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: pregnancyHistoryController,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Pregnancy history',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: birthHistoryController,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Birth history',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: abortionHistoryController,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Abortion history',
                        ),
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

    pregnancyTermWeeksController.dispose();
    gestityController.dispose();
    parityController.dispose();
    abortionsController.dispose();
    pubertyAgeController.dispose();
    breastExamNotesController.dispose();
    pregnancyHistoryController.dispose();
    birthHistoryController.dispose();
    abortionHistoryController.dispose();

    if (saved == true) {
      await _load();
    }
  }

  // Deletes the reproductive health record after user confirmation.
  Future<void> _delete() async {
    if (!_access.allowMutations) return;
    final patientId = _patientId;
    if (patientId == null) return;

    // CHANGED: confirmation before delete
    final confirmed = await showDeleteConfirmDialog(
      context: context,
      title: 'Delete reproductive health record?',
      message: 'This action cannot be undone.',
    );

    if (!confirmed || !mounted) return;

    await _service.delete(patientId: patientId);
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reproductive health'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          if (_access.allowMutations)
            IconButton(
              onPressed: _edit,
              icon: Icon(item == null ? Icons.add : Icons.edit),
            ),
          if (_access.allowMutations && item != null)
            IconButton(onPressed: _delete, icon: const Icon(Icons.delete)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patientId == null
          ? const Center(child: Text('No patient selected.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    title: const Text('Reproductive health'),
                    subtitle: Text(
                      item == null
                          ? 'No record'
                          : [
                              'Has menstrual cycle: ${yesNo(item.hasMenstrualCycle)}',
                              'Cycle regular: ${yesNo(item.cycleRegular)}',
                              'Cycle painful: ${yesNo(item.cyclePainful)}',
                              'Pain level: ${displayUnknownAsNone(item.painLevel)}',
                              if (item.lastPeriodStart != null)
                                'Last period start: ${item.lastPeriodStart!.toIso8601String().split('T').first}',
                              if (item.lastPeriodEnd != null)
                                'Last period end: ${item.lastPeriodEnd!.toIso8601String().split('T').first}',
                              'Currently pregnant: ${yesNo(item.currentlyPregnant)}',
                              if (item.pregnancyTermWeeks != null)
                                'Pregnancy term weeks: ${item.pregnancyTermWeeks}',
                              if (item.gestity != null)
                                'Gestity: ${item.gestity}',
                              if (item.parity != null) 'Parity: ${item.parity}',
                              if (item.abortions != null)
                                'Abortions: ${item.abortions}',
                              if (item.pubertyAge != null)
                                'Puberty age: ${item.pubertyAge}',
                              if ((item.breastExamNotes ?? '').isNotEmpty)
                                'Breast exam notes: ${item.breastExamNotes}',
                              if ((item.pregnancyHistory ?? '').isNotEmpty)
                                'Pregnancy history: ${item.pregnancyHistory}',
                              if ((item.birthHistory ?? '').isNotEmpty)
                                'Birth history: ${item.birthHistory}',
                              if ((item.abortionHistory ?? '').isNotEmpty)
                                'Abortion history: ${item.abortionHistory}',
                            ].join('\n'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
