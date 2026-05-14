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

  Future<void> _deleteItem() async {
    if (!widget.canEdit) return;
    final patientId = _patientId;
    if (patientId == null) return;
    await _service.delete(patientId: patientId, performedByUserId: 'current');
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
            IconButton(onPressed: _deleteItem, icon: const Icon(Icons.delete)),
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