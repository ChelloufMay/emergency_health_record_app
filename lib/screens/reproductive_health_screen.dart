import 'package:flutter/material.dart';

import '../models/reproductive_health_model.dart';
import '../services/patient_session_service.dart';
import '../services/reproductive_health_service.dart';

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
  State<ReproductiveHealthScreen> createState() => _ReproductiveHealthScreenState();
}

class _ReproductiveHealthScreenState extends State<ReproductiveHealthScreen> {
  final ReproductiveHealthService _service = ReproductiveHealthService();

  bool _loading = true;
  String? _patientId;
  ReproductiveHealthModel? _item;

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

    final item = await _service.fetchByPatient(patientId);

    if (!mounted) return;
    setState(() {
      _patientId = patientId;
      _item = item;
      _loading = false;
    });
  }

  Future<void> _edit() async {
    if (!widget.canEdit) return;

    final current = _item;

    final painLevelController = TextEditingController(text: current?.painLevel ?? '');
    final lastPeriodStartController = TextEditingController(
      text: current?.lastPeriodStart?.toIso8601String().split('T').first ?? '',
    );
    final lastPeriodEndController = TextEditingController(
      text: current?.lastPeriodEnd?.toIso8601String().split('T').first ?? '',
    );
    final pregnancyTermController = TextEditingController(text: current?.pregnancyTermWeeks?.toString() ?? '');
    final gestityController = TextEditingController(text: current?.gestity?.toString() ?? '');
    final parityController = TextEditingController(text: current?.parity?.toString() ?? '');
    final abortionsController = TextEditingController(text: current?.abortions?.toString() ?? '');
    final pubertyAgeController = TextEditingController(text: current?.pubertyAge?.toString() ?? '');
    final breastExamController = TextEditingController(text: current?.breastExamNotes ?? '');
    final pregnancyHistoryController = TextEditingController(text: current?.pregnancyHistory ?? '');
    final birthHistoryController = TextEditingController(text: current?.birthHistory ?? '');
    final abortionHistoryController = TextEditingController(text: current?.abortionHistory ?? '');

    bool? hasMenstrualCycle = current?.hasMenstrualCycle;
    bool? cycleRegular = current?.cycleRegular;
    bool? cyclePainful = current?.cyclePainful;
    bool? currentlyPregnant = current?.currentlyPregnant;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit reproductive health'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // This screen is a singleton row in public.reproductive_health.
                DropdownButtonFormField<bool?>(
                  initialValue: hasMenstrualCycle,
                  decoration: const InputDecoration(labelText: 'Has menstrual cycle'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Unknown')),
                    DropdownMenuItem(value: true, child: Text('Yes')),
                    DropdownMenuItem(value: false, child: Text('No')),
                  ],
                  onChanged: (v) => hasMenstrualCycle = v,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<bool?>(
                  initialValue: cycleRegular,
                  decoration: const InputDecoration(labelText: 'Cycle regular'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Unknown')),
                    DropdownMenuItem(value: true, child: Text('Yes')),
                    DropdownMenuItem(value: false, child: Text('No')),
                  ],
                  onChanged: (v) => cycleRegular = v,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<bool?>(
                  initialValue: cyclePainful,
                  decoration: const InputDecoration(labelText: 'Cycle painful'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Unknown')),
                    DropdownMenuItem(value: true, child: Text('Yes')),
                    DropdownMenuItem(value: false, child: Text('No')),
                  ],
                  onChanged: (v) => cyclePainful = v,
                ),
                const SizedBox(height: 12),
                TextField(controller: painLevelController, decoration: const InputDecoration(labelText: 'Pain level')),
                const SizedBox(height: 12),
                TextField(controller: lastPeriodStartController, decoration: const InputDecoration(labelText: 'Last period start', hintText: 'YYYY-MM-DD')),
                const SizedBox(height: 12),
                TextField(controller: lastPeriodEndController, decoration: const InputDecoration(labelText: 'Last period end', hintText: 'YYYY-MM-DD')),
                const SizedBox(height: 12),
                DropdownButtonFormField<bool?>(
                  initialValue: currentlyPregnant,
                  decoration: const InputDecoration(labelText: 'Currently pregnant'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Unknown')),
                    DropdownMenuItem(value: true, child: Text('Yes')),
                    DropdownMenuItem(value: false, child: Text('No')),
                  ],
                  onChanged: (v) => currentlyPregnant = v,
                ),
                const SizedBox(height: 12),
                TextField(controller: pregnancyTermController, decoration: const InputDecoration(labelText: 'Pregnancy term weeks')),
                const SizedBox(height: 12),
                TextField(controller: gestityController, decoration: const InputDecoration(labelText: 'Gestity')),
                const SizedBox(height: 12),
                TextField(controller: parityController, decoration: const InputDecoration(labelText: 'Parity')),
                const SizedBox(height: 12),
                TextField(controller: abortionsController, decoration: const InputDecoration(labelText: 'Abortions')),
                const SizedBox(height: 12),
                TextField(controller: pubertyAgeController, decoration: const InputDecoration(labelText: 'Puberty age')),
                const SizedBox(height: 12),
                TextField(controller: breastExamController, decoration: const InputDecoration(labelText: 'Breast exam notes'), maxLines: 2),
                const SizedBox(height: 12),
                TextField(controller: pregnancyHistoryController, decoration: const InputDecoration(labelText: 'Pregnancy history'), maxLines: 2),
                const SizedBox(height: 12),
                TextField(controller: birthHistoryController, decoration: const InputDecoration(labelText: 'Birth history'), maxLines: 2),
                const SizedBox(height: 12),
                TextField(controller: abortionHistoryController, decoration: const InputDecoration(labelText: 'Abortion history'), maxLines: 2),
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

    if (saved != true) {
      painLevelController.dispose();
      lastPeriodStartController.dispose();
      lastPeriodEndController.dispose();
      pregnancyTermController.dispose();
      gestityController.dispose();
      parityController.dispose();
      abortionsController.dispose();
      pubertyAgeController.dispose();
      breastExamController.dispose();
      pregnancyHistoryController.dispose();
      birthHistoryController.dispose();
      abortionHistoryController.dispose();
      return;
    }

    final patientId = _patientId;
    if (patientId == null) return;

    final model = ReproductiveHealthModel(
      id: current?.id,
      patientId: patientId,
      hasMenstrualCycle: hasMenstrualCycle,
      cycleRegular: cycleRegular,
      cyclePainful: cyclePainful,
      painLevel: painLevelController.text.trim().isEmpty ? null : painLevelController.text.trim(),
      lastPeriodStart: lastPeriodStartController.text.trim().isEmpty
          ? null
          : DateTime.tryParse(lastPeriodStartController.text.trim()),
      lastPeriodEnd: lastPeriodEndController.text.trim().isEmpty
          ? null
          : DateTime.tryParse(lastPeriodEndController.text.trim()),
      currentlyPregnant: currentlyPregnant,
      pregnancyTermWeeks: int.tryParse(pregnancyTermController.text.trim()),
      gestity: int.tryParse(gestityController.text.trim()),
      parity: int.tryParse(parityController.text.trim()),
      abortions: int.tryParse(abortionsController.text.trim()),
      pubertyAge: int.tryParse(pubertyAgeController.text.trim()),
      breastExamNotes: breastExamController.text.trim().isEmpty ? null : breastExamController.text.trim(),
      pregnancyHistory: pregnancyHistoryController.text.trim().isEmpty ? null : pregnancyHistoryController.text.trim(),
      birthHistory: birthHistoryController.text.trim().isEmpty ? null : birthHistoryController.text.trim(),
      abortionHistory: abortionHistoryController.text.trim().isEmpty ? null : abortionHistoryController.text.trim(),
    );

    await _service.save(reproductiveHealth: model, patientId: patientId);

    painLevelController.dispose();
    lastPeriodStartController.dispose();
    lastPeriodEndController.dispose();
    pregnancyTermController.dispose();
    gestityController.dispose();
    parityController.dispose();
    abortionsController.dispose();
    pubertyAgeController.dispose();
    breastExamController.dispose();
    pregnancyHistoryController.dispose();
    birthHistoryController.dispose();
    abortionHistoryController.dispose();

    await _load();
  }

  Future<void> _delete() async {
    if (!widget.canEdit) return;
    final patientId = _patientId;
    if (patientId == null) return;

    await _service.delete(patientId: patientId);
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
          if (widget.canEdit && item != null) IconButton(onPressed: _edit, icon: const Icon(Icons.edit)),
          if (widget.canEdit && item != null) IconButton(onPressed: _delete, icon: const Icon(Icons.delete)),
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
              title: const Text('Reproductive health record'),
              subtitle: Text(
                item == null
                    ? 'No record'
                    : [
                  if (item.hasMenstrualCycle != null) 'Has menstrual cycle: ${item.hasMenstrualCycle}',
                  if (item.cycleRegular != null) 'Cycle regular: ${item.cycleRegular}',
                  if (item.cyclePainful != null) 'Cycle painful: ${item.cyclePainful}',
                  if ((item.painLevel ?? '').isNotEmpty) 'Pain level: ${item.painLevel}',
                  if (item.lastPeriodStart != null)
                    'Last period start: ${item.lastPeriodStart!.toIso8601String().split('T').first}',
                  if (item.lastPeriodEnd != null)
                    'Last period end: ${item.lastPeriodEnd!.toIso8601String().split('T').first}',
                  if (item.currentlyPregnant != null) 'Currently pregnant: ${item.currentlyPregnant}',
                  if (item.pregnancyTermWeeks != null) 'Pregnancy term weeks: ${item.pregnancyTermWeeks}',
                  if (item.gestity != null) 'Gestity: ${item.gestity}',
                  if (item.parity != null) 'Parity: ${item.parity}',
                  if (item.abortions != null) 'Abortions: ${item.abortions}',
                  if (item.pubertyAge != null) 'Puberty age: ${item.pubertyAge}',
                  if ((item.breastExamNotes ?? '').isNotEmpty) 'Breast exam notes: ${item.breastExamNotes}',
                ].join('\n'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}