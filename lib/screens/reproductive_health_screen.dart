import 'package:flutter/material.dart';

import '../models/reproductive_health_model.dart';
import '../services/reproductive_health_service.dart';
import '../services/patient_session_service.dart';

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
        title: const Text('Reproductive health'),
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
              title: const Text('Reproductive health record'),
              subtitle: Text(
                item == null
                    ? 'No record'
                    : [
                  if (item.hasMenstrualCycle != null) 'Has menstrual cycle: ${item.hasMenstrualCycle}',
                  if (item.cycleRegular != null) 'Cycle regular: ${item.cycleRegular}',
                  if (item.cyclePainful != null) 'Cycle painful: ${item.cyclePainful}',
                  if ((item.painLevel ?? '').isNotEmpty) 'Pain level: ${item.painLevel}',
                  if (item.lastPeriodStart != null) 'Last period start: ${item.lastPeriodStart!.toIso8601String().split('T').first}',
                  if (item.lastPeriodEnd != null) 'Last period end: ${item.lastPeriodEnd!.toIso8601String().split('T').first}',
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