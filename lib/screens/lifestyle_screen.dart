import 'package:flutter/material.dart';

import '../models/lifestyle_model.dart';
import '../services/lifestyle_service.dart';
import '../services/patient_session_service.dart';

class LifestyleScreen extends StatefulWidget {
  final String? patientId;
  final bool canEdit;
  final bool isEmergencyOnly;

  const LifestyleScreen({
    super.key,
    this.patientId,
    this.canEdit = false,
    this.isEmergencyOnly = false,
  });

  @override
  State<LifestyleScreen> createState() => _LifestyleScreenState();
}

class _LifestyleScreenState extends State<LifestyleScreen> {
  final LifestyleService _service = LifestyleService();

  bool _loading = true;
  String? _patientId;
  LifestyleModel? _item;

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

    final workStatusController = TextEditingController(text: current?.workStatus ?? '');
    final drugTypeController = TextEditingController(text: current?.drugType ?? '');
    final drugQuantityController = TextEditingController(text: current?.drugQuantity ?? '');
    final alcoholController = TextEditingController(text: current?.alcoholFrequency ?? '');
    final foodQualityController = TextEditingController(text: current?.foodQuality ?? '');
    final milkTypeController = TextEditingController(text: current?.milkType ?? '');
    final waterTypeController = TextEditingController(text: current?.waterType ?? '');
    final packsController = TextEditingController(text: current?.packsPerDay?.toString() ?? '');
    final smokingYearsController = TextEditingController(text: current?.smokingYears?.toString() ?? '');
    final chichaYearsController = TextEditingController(text: current?.chichaYears?.toString() ?? '');

    bool? livesAlone = current?.livesAlone;
    bool? hasCaregiver = current?.hasCaregiver;
    bool? stairsInHome = current?.stairsInHome;
    bool? smoking = current?.smoking;
    bool? drugs = current?.drugs;
    bool? chicha = current?.chicha;
    String socioeconomicClass = current?.socioeconomicClass ?? 'unknown';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit lifestyle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // This screen is a singleton row: one patient, one lifestyle row.
                DropdownButtonFormField<String>(
                  initialValue: socioeconomicClass,
                  decoration: const InputDecoration(labelText: 'Socioeconomic class'),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'middle', child: Text('Middle')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(value: 'unknown', child: Text('Unknown')),
                  ],
                  onChanged: (v) => socioeconomicClass = v ?? 'unknown',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<bool?>(
                  initialValue: livesAlone,
                  decoration: const InputDecoration(labelText: 'Lives alone'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Unknown')),
                    DropdownMenuItem(value: true, child: Text('Yes')),
                    DropdownMenuItem(value: false, child: Text('No')),
                  ],
                  onChanged: (v) => livesAlone = v,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<bool?>(
                  initialValue: hasCaregiver,
                  decoration: const InputDecoration(labelText: 'Has caregiver'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Unknown')),
                    DropdownMenuItem(value: true, child: Text('Yes')),
                    DropdownMenuItem(value: false, child: Text('No')),
                  ],
                  onChanged: (v) => hasCaregiver = v,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<bool?>(
                  initialValue: stairsInHome,
                  decoration: const InputDecoration(labelText: 'Stairs in home'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Unknown')),
                    DropdownMenuItem(value: true, child: Text('Yes')),
                    DropdownMenuItem(value: false, child: Text('No')),
                  ],
                  onChanged: (v) => stairsInHome = v,
                ),
                const SizedBox(height: 12),
                TextField(controller: workStatusController, decoration: const InputDecoration(labelText: 'Work status')),
                const SizedBox(height: 12),
                DropdownButtonFormField<bool?>(
                  initialValue: smoking,
                  decoration: const InputDecoration(labelText: 'Smoking'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Unknown')),
                    DropdownMenuItem(value: true, child: Text('Yes')),
                    DropdownMenuItem(value: false, child: Text('No')),
                  ],
                  onChanged: (v) => smoking = v,
                ),
                const SizedBox(height: 12),
                TextField(controller: packsController, decoration: const InputDecoration(labelText: 'Packs/day')),
                const SizedBox(height: 12),
                TextField(controller: smokingYearsController, decoration: const InputDecoration(labelText: 'Smoking years')),
                const SizedBox(height: 12),
                DropdownButtonFormField<bool?>(
                  initialValue: drugs,
                  decoration: const InputDecoration(labelText: 'Drugs'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Unknown')),
                    DropdownMenuItem(value: true, child: Text('Yes')),
                    DropdownMenuItem(value: false, child: Text('No')),
                  ],
                  onChanged: (v) => drugs = v,
                ),
                const SizedBox(height: 12),
                TextField(controller: drugTypeController, decoration: const InputDecoration(labelText: 'Drug type')),
                const SizedBox(height: 12),
                TextField(controller: drugQuantityController, decoration: const InputDecoration(labelText: 'Drug quantity')),
                const SizedBox(height: 12),
                DropdownButtonFormField<bool?>(
                  initialValue: chicha,
                  decoration: const InputDecoration(labelText: 'Chicha'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Unknown')),
                    DropdownMenuItem(value: true, child: Text('Yes')),
                    DropdownMenuItem(value: false, child: Text('No')),
                  ],
                  onChanged: (v) => chicha = v,
                ),
                const SizedBox(height: 12),
                TextField(controller: chichaYearsController, decoration: const InputDecoration(labelText: 'Chicha years')),
                const SizedBox(height: 12),
                TextField(controller: alcoholController, decoration: const InputDecoration(labelText: 'Alcohol frequency')),
                const SizedBox(height: 12),
                TextField(controller: foodQualityController, decoration: const InputDecoration(labelText: 'Food quality')),
                const SizedBox(height: 12),
                TextField(controller: milkTypeController, decoration: const InputDecoration(labelText: 'Milk type')),
                const SizedBox(height: 12),
                TextField(controller: waterTypeController, decoration: const InputDecoration(labelText: 'Water type')),
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
      workStatusController.dispose();
      drugTypeController.dispose();
      drugQuantityController.dispose();
      alcoholController.dispose();
      foodQualityController.dispose();
      milkTypeController.dispose();
      waterTypeController.dispose();
      packsController.dispose();
      smokingYearsController.dispose();
      chichaYearsController.dispose();
      return;
    }

    final patientId = _patientId;
    if (patientId == null) return;

    final model = LifestyleModel(
      id: current?.id,
      patientId: patientId,
      livesAlone: livesAlone,
      hasCaregiver: hasCaregiver,
      stairsInHome: stairsInHome,
      socioeconomicClass: socioeconomicClass,
      workStatus: workStatusController.text.trim().isEmpty ? null : workStatusController.text.trim(),
      smoking: smoking,
      packsPerDay: double.tryParse(packsController.text.trim()),
      smokingYears: double.tryParse(smokingYearsController.text.trim()),
      drugs: drugs,
      drugType: drugTypeController.text.trim().isEmpty ? null : drugTypeController.text.trim(),
      drugQuantity: drugQuantityController.text.trim().isEmpty ? null : drugQuantityController.text.trim(),
      chicha: chicha,
      chichaYears: double.tryParse(chichaYearsController.text.trim()),
      alcoholFrequency: alcoholController.text.trim().isEmpty ? null : alcoholController.text.trim(),
      foodQuality: foodQualityController.text.trim().isEmpty ? null : foodQualityController.text.trim(),
      milkType: milkTypeController.text.trim().isEmpty ? null : milkTypeController.text.trim(),
      waterType: waterTypeController.text.trim().isEmpty ? null : waterTypeController.text.trim(),
    );

    await _service.save(lifestyle: model, patientId: patientId);

    workStatusController.dispose();
    drugTypeController.dispose();
    drugQuantityController.dispose();
    alcoholController.dispose();
    foodQualityController.dispose();
    milkTypeController.dispose();
    waterTypeController.dispose();
    packsController.dispose();
    smokingYearsController.dispose();
    chichaYearsController.dispose();

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
        title: const Text('Lifestyle'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          if (widget.canEdit && item != null)
            IconButton(onPressed: _edit, icon: const Icon(Icons.edit)),
          if (widget.canEdit && item != null)
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
              title: const Text('Lifestyle factors'),
              subtitle: Text(
                item == null
                    ? 'No record'
                    : [
                  'Lives alone: ${item.livesAlone ?? '-'}',
                  'Has caregiver: ${item.hasCaregiver ?? '-'}',
                  'Stairs in home: ${item.stairsInHome ?? '-'}',
                  'Socioeconomic class: ${item.socioeconomicClass}',
                  if ((item.workStatus ?? '').isNotEmpty) 'Work status: ${item.workStatus}',
                  if (item.smoking != null) 'Smoking: ${item.smoking}',
                  if (item.packsPerDay != null) 'Packs/day: ${item.packsPerDay}',
                  if (item.smokingYears != null) 'Smoking years: ${item.smokingYears}',
                  if (item.drugs != null) 'Drugs: ${item.drugs}',
                  if ((item.drugType ?? '').isNotEmpty) 'Drug type: ${item.drugType}',
                  if ((item.drugQuantity ?? '').isNotEmpty) 'Drug quantity: ${item.drugQuantity}',
                  if (item.chicha != null) 'Chicha: ${item.chicha}',
                  if (item.chichaYears != null) 'Chicha years: ${item.chichaYears}',
                  if ((item.alcoholFrequency ?? '').isNotEmpty) 'Alcohol frequency: ${item.alcoholFrequency}',
                  if ((item.foodQuality ?? '').isNotEmpty) 'Food quality: ${item.foodQuality}',
                  if ((item.milkType ?? '').isNotEmpty) 'Milk type: ${item.milkType}',
                  if ((item.waterType ?? '').isNotEmpty) 'Water type: ${item.waterType}',
                ].join('\n'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}