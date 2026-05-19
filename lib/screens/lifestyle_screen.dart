import 'package:flutter/material.dart';

import '../models/lifestyle_model.dart';
import '../services/lifestyle_service.dart';
import '../services/patient_session_service.dart';
import '../utils/field_helpers.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/medical_save_dialog.dart';

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

  String? _resolvePatientId() =>
      widget.patientId ?? PatientSessionService.instance.current?.patientId;

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
    final patientId = _patientId;
    if (patientId == null) return;

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
    // CHANGED: use None in UI, store unknown in DB
    String socioeconomicClass = current?.socioeconomicClass ?? 'unknown';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return MedicalSaveDialog(
          title: current == null ? 'Add lifestyle' : 'Edit lifestyle',
          validate: () {
            if (socioeconomicClass.trim().isEmpty) {
              return 'Socioeconomic class is required.';
            }
            return null;
          },
          onSave: () async {
            final model = LifestyleModel(
              id: current?.id,
              patientId: patientId,
              livesAlone: livesAlone,
              hasCaregiver: hasCaregiver,
              stairsInHome: stairsInHome,
              socioeconomicClass: socioeconomicClass.trim() == 'none'
                  ? 'unknown'
                  : socioeconomicClass.trim(),
              workStatus: workStatusController.text.trim().isEmpty
                  ? null
                  : workStatusController.text.trim(),
              smoking: smoking,
              packsPerDay: double.tryParse(packsController.text.trim()),
              smokingYears: double.tryParse(smokingYearsController.text.trim()),
              drugs: drugs,
              drugType: drugTypeController.text.trim().isEmpty
                  ? null
                  : drugTypeController.text.trim(),
              drugQuantity: drugQuantityController.text.trim().isEmpty
                  ? null
                  : drugQuantityController.text.trim(),
              chicha: chicha,
              chichaYears: double.tryParse(chichaYearsController.text.trim()),
              alcoholFrequency: alcoholController.text.trim().isEmpty
                  ? null
                  : alcoholController.text.trim(),
              foodQuality: foodQualityController.text.trim().isEmpty
                  ? null
                  : foodQualityController.text.trim(),
              milkType: milkTypeController.text.trim().isEmpty
                  ? null
                  : milkTypeController.text.trim(),
              waterType: waterTypeController.text.trim().isEmpty
                  ? null
                  : waterTypeController.text.trim(),
            );
            await _service.save(lifestyle: model, patientId: patientId);
          },
          contentBuilder: (_, saving) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                DropdownButtonFormField<bool?> boolDropdown(
                    String label,
                    bool? value,
                    void Function(bool?) onChanged,
                    ) {
                  return DropdownButtonFormField<bool?>(
                    initialValue: value,
                    decoration: InputDecoration(labelText: label),
                    items: const [
                      DropdownMenuItem<bool?>(
                        value: null,
                        child: Text('None'),
                      ),
                      DropdownMenuItem<bool?>(
                        value: true,
                        child: Text('Yes'),
                      ),
                      DropdownMenuItem<bool?>(
                        value: false,
                        child: Text('No'),
                      ),
                    ],
                    onChanged: saving ? null : onChanged,
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        // CHANGED: unknown is shown as None
                        initialValue: socioeconomicClass == 'unknown'
                            ? 'unknown'
                            : socioeconomicClass,
                        decoration: const InputDecoration(
                          labelText: 'Socioeconomic class',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'low',
                            child: Text('Low'),
                          ),
                          DropdownMenuItem(
                            value: 'middle',
                            child: Text('Middle'),
                          ),
                          DropdownMenuItem(
                            value: 'high',
                            child: Text('High'),
                          ),
                          DropdownMenuItem(
                            value: 'unknown',
                            child: Text('None'),
                          ),
                        ],
                        onChanged: saving
                            ? null
                            : (v) => setDialogState(
                              () => socioeconomicClass = v ?? 'unknown',
                        ),
                      ),
                      const SizedBox(height: 12),
                      boolDropdown('Lives alone', livesAlone, (v) {
                        setDialogState(() => livesAlone = v);
                      }),
                      const SizedBox(height: 12),
                      boolDropdown('Has caregiver', hasCaregiver, (v) {
                        setDialogState(() => hasCaregiver = v);
                      }),
                      const SizedBox(height: 12),
                      boolDropdown('Stairs in home', stairsInHome, (v) {
                        setDialogState(() => stairsInHome = v);
                      }),
                      const SizedBox(height: 12),
                      TextField(
                        controller: workStatusController,
                        enabled: !saving,
                        decoration: const InputDecoration(labelText: 'Work status'),
                      ),
                      const SizedBox(height: 12),
                      boolDropdown('Smoking', smoking, (v) {
                        setDialogState(() => smoking = v);
                      }),
                      const SizedBox(height: 12),
                      TextField(
                        controller: packsController,
                        enabled: !saving,
                        decoration: const InputDecoration(labelText: 'Packs/day'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: smokingYearsController,
                        enabled: !saving,
                        decoration: const InputDecoration(labelText: 'Smoking years'),
                      ),
                      const SizedBox(height: 12),
                      boolDropdown('Drugs', drugs, (v) {
                        setDialogState(() => drugs = v);
                      }),
                      const SizedBox(height: 12),
                      TextField(
                        controller: drugTypeController,
                        enabled: !saving,
                        decoration: const InputDecoration(labelText: 'Drug type'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: drugQuantityController,
                        enabled: !saving,
                        decoration: const InputDecoration(labelText: 'Drug quantity'),
                      ),
                      const SizedBox(height: 12),
                      boolDropdown('Chicha', chicha, (v) {
                        setDialogState(() => chicha = v);
                      }),
                      const SizedBox(height: 12),
                      TextField(
                        controller: chichaYearsController,
                        enabled: !saving,
                        decoration: const InputDecoration(labelText: 'Chicha years'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: alcoholController,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Alcohol frequency',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: foodQualityController,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Food quality',
                          hintText: 'e.g. good / average / poor',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: milkTypeController,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Milk type',
                          hintText: 'e.g. fresh / powdered / none',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: waterTypeController,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Water type',
                          hintText: 'e.g. tap / bottled / filtered',
                        ),
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

    if (saved == true) {
      await _load();
    }
  }

  Future<void> _delete() async {
    if (!widget.canEdit) return;
    final patientId = _patientId;
    if (patientId == null) return;

    // CHANGED: confirmation before delete
    final confirmed = await showDeleteConfirmDialog(
      context: context,
      title: 'Delete lifestyle record?',
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
        title: const Text('Lifestyle'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          if (widget.canEdit)
            IconButton(
              onPressed: _edit,
              icon: Icon(item == null ? Icons.add : Icons.edit),
            ),
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
                  'Lives alone: ${yesNo(item.livesAlone)}',
                  'Has caregiver: ${yesNo(item.hasCaregiver)}',
                  'Stairs in home: ${yesNo(item.stairsInHome)}',
                  'Socioeconomic class: ${displayUnknownAsNone(item.socioeconomicClass)}',
                  if ((item.workStatus ?? '').isNotEmpty)
                    'Work status: ${item.workStatus}',
                  'Smoking: ${yesNo(item.smoking)}',
                  if (item.packsPerDay != null)
                    'Packs/day: ${item.packsPerDay}',
                  if (item.smokingYears != null)
                    'Smoking years: ${item.smokingYears}',
                  'Drugs: ${yesNo(item.drugs)}',
                  if ((item.drugType ?? '').isNotEmpty)
                    'Drug type: ${item.drugType}',
                  if ((item.drugQuantity ?? '').isNotEmpty)
                    'Drug quantity: ${item.drugQuantity}',
                  'Chicha: ${yesNo(item.chicha)}',
                  if (item.chichaYears != null)
                    'Chicha years: ${item.chichaYears}',
                  if ((item.alcoholFrequency ?? '').isNotEmpty)
                    'Alcohol frequency: ${item.alcoholFrequency}',
                  if ((item.foodQuality ?? '').isNotEmpty)
                    'Food quality: ${displayUnknownAsNone(item.foodQuality)}',
                  if ((item.milkType ?? '').isNotEmpty)
                    'Milk type: ${displayUnknownAsNone(item.milkType)}',
                  if ((item.waterType ?? '').isNotEmpty)
                    'Water type: ${displayUnknownAsNone(item.waterType)}',
                ].join('\n'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}