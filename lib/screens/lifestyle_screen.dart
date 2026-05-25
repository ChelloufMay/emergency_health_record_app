import 'package:flutter/material.dart';

import '../models/lifestyle_model.dart';
import '../services/lifestyle_service.dart';
import '../services/patient_session_service.dart';
import '../utils/patient_access_context.dart';
import '../utils/section_screen_access.dart';
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

    final item = await _service.fetchByPatient(patientId);
    if (!mounted) return;

    setState(() {
      _patientId = patientId;
      _item = item;
      _loading = false;
    });
  }

  Future<void> _edit() async {
    if (!_access.allowMutations) return;
    final patientId = _patientId;
    if (patientId == null) return;

    final current = _item;

    String workStatus = current?.workStatus ?? 'unemployed';
    if (!['unemployed', 'employed', 'retired', 'student'].contains(workStatus)) {
      workStatus = 'unemployed';
    }
    final drugTypeController = TextEditingController(text: current?.drugType ?? '');
    final drugQuantityController = TextEditingController(text: current?.drugQuantity ?? '');
    String alcoholFrequency = current?.alcoholFrequency ?? 'never';
    if (!['never', 'rarely', 'monthly', 'weekly', 'daily'].contains(alcoholFrequency)) {
      alcoholFrequency = 'never';
    }
    String foodQuality = current?.foodQuality ?? 'average';
    if (!['good', 'average', 'poor'].contains(foodQuality)) {
      foodQuality = 'average';
    }
    String milkType = current?.milkType ?? 'fresh';
    if (!['fresh', 'powdered', 'none'].contains(milkType)) {
      milkType = 'fresh';
    }
    String waterType = current?.waterType ?? 'filtered';
    if (!['tap', 'bottled', 'filtered'].contains(waterType)) {
      waterType = 'filtered';
    }
    final packsController = TextEditingController(text: current?.packsPerDay?.toString() ?? '');
    final smokingYearsController = TextEditingController(text: current?.smokingYears?.toString() ?? '');
    final chichaYearsController = TextEditingController(text: current?.chichaYears?.toString() ?? '');

    bool livesAlone = current?.livesAlone ?? false;
    bool hasCaregiver = current?.hasCaregiver ?? false;
    bool stairsInHome = current?.stairsInHome ?? false;
    bool smoking = current?.smoking ?? false;
    bool drugs = current?.drugs ?? false;
    bool chicha = current?.chicha ?? false;
    String socioeconomicClass = current?.socioeconomicClass ?? 'middle';
    if (socioeconomicClass == 'unknown') {
      socioeconomicClass = 'middle';
    }

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
              socioeconomicClass: socioeconomicClass,
              workStatus: workStatus,
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
              alcoholFrequency: alcoholFrequency,
              foodQuality: foodQuality,
              milkType: milkType,
              waterType: waterType,
            );
            await _service.save(lifestyle: model, patientId: patientId);
          },
          contentBuilder: (_, saving) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                Widget boolDropdown(
                  String label,
                  bool value,
                  void Function(bool) onChanged,
                ) {
                  return DropdownButtonFormField<bool>(
                    initialValue: value,
                    decoration: InputDecoration(labelText: label),
                    items: const [
                      DropdownMenuItem<bool>(
                        value: true,
                        child: Text('Yes'),
                      ),
                      DropdownMenuItem<bool>(
                        value: false,
                        child: Text('No'),
                      ),
                    ],
                    onChanged: saving ? null : (v) => onChanged(v!),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: socioeconomicClass,
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
                        ],
                        onChanged: saving
                            ? null
                            : (v) => setDialogState(
                              () => socioeconomicClass = v ?? 'middle',
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
                      DropdownButtonFormField<String>(
                        initialValue: workStatus,
                        decoration: const InputDecoration(labelText: 'Work status'),
                        items: const [
                          DropdownMenuItem(value: 'unemployed', child: Text('Unemployed')),
                          DropdownMenuItem(value: 'employed', child: Text('Employed')),
                          DropdownMenuItem(value: 'retired', child: Text('Retired')),
                          DropdownMenuItem(value: 'student', child: Text('Student')),
                        ],
                        onChanged: saving ? null : (v) => setDialogState(() => workStatus = v ?? 'unemployed'),
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
                      DropdownButtonFormField<String>(
                        initialValue: alcoholFrequency,
                        decoration: const InputDecoration(labelText: 'Alcohol frequency'),
                        items: const [
                          DropdownMenuItem(value: 'never', child: Text('Never')),
                          DropdownMenuItem(value: 'rarely', child: Text('Rarely')),
                          DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                          DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                          DropdownMenuItem(value: 'daily', child: Text('Daily')),
                        ],
                        onChanged: saving ? null : (v) => setDialogState(() => alcoholFrequency = v ?? 'never'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: foodQuality,
                        decoration: const InputDecoration(labelText: 'Food quality'),
                        items: const [
                          DropdownMenuItem(value: 'good', child: Text('Good')),
                          DropdownMenuItem(value: 'average', child: Text('Average')),
                          DropdownMenuItem(value: 'poor', child: Text('Poor')),
                        ],
                        onChanged: saving ? null : (v) => setDialogState(() => foodQuality = v ?? 'average'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: milkType,
                        decoration: const InputDecoration(labelText: 'Milk type'),
                        items: const [
                          DropdownMenuItem(value: 'fresh', child: Text('Fresh')),
                          DropdownMenuItem(value: 'powdered', child: Text('Powdered')),
                          DropdownMenuItem(value: 'none', child: Text('No milk')),
                        ],
                        onChanged: saving ? null : (v) => setDialogState(() => milkType = v ?? 'fresh'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: waterType,
                        decoration: const InputDecoration(labelText: 'Water type'),
                        items: const [
                          DropdownMenuItem(value: 'tap', child: Text('Tap')),
                          DropdownMenuItem(value: 'bottled', child: Text('Bottled')),
                          DropdownMenuItem(value: 'filtered', child: Text('Filtered')),
                        ],
                        onChanged: saving ? null : (v) => setDialogState(() => waterType = v ?? 'filtered'),
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

    drugTypeController.dispose();
    drugQuantityController.dispose();
    packsController.dispose();
    smokingYearsController.dispose();
    chichaYearsController.dispose();

    if (saved == true) {
      await _load();
    }
  }

  Future<void> _delete() async {
    if (!_access.allowMutations) return;
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
