import 'package:flutter/material.dart';

import '../models/medication_model.dart';
import '../services/medication_service.dart';
import '../services/patient_session_service.dart';

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

  Future<void> _deleteItem(MedicationModel item) async {
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
        title: const Text('Medications'),
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
                title: Text(item.medicationName),
                subtitle: Text([
                  if ((item.dosage ?? '').isNotEmpty) 'Dosage: ${item.dosage}',
                  if ((item.frequency ?? '').isNotEmpty) 'Frequency: ${item.frequency}',
                  if ((item.purpose ?? '').isNotEmpty) 'Purpose: ${item.purpose}',
                  if (item.startDate != null) 'Start: ${item.startDate!.toIso8601String().split('T').first}',
                  if (item.endDate != null) 'End: ${item.endDate!.toIso8601String().split('T').first}',
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