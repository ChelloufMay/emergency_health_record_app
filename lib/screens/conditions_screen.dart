import 'package:flutter/material.dart';

import '../models/medical_condition_model.dart';
import '../services/medical_condition_service.dart';
import '../services/patient_session_service.dart';

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

  Future<void> _deleteItem(MedicalConditionModel item) async {
    if (!widget.canEdit) return;
    final patientId = _patientId;
    if (patientId == null || item.id == null) return;
    await _service.delete(patientId: patientId, id: item.id!, performedByUserId: 'current');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conditions'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
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
                subtitle: Text([
                  'Type: ${item.type}',
                  if (item.diagnosisDate != null) 'Diagnosis date: ${item.diagnosisDate!.toIso8601String().split('T').first}',
                  if ((item.diagnosisPlace ?? '').isNotEmpty) 'Place: ${item.diagnosisPlace}',
                  if ((item.followUpDoctor ?? '').isNotEmpty) 'Doctor: ${item.followUpDoctor}',
                ].join('\n')),
                trailing: widget.canEdit
                    ? IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteItem(item),
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