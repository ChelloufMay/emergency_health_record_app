import 'package:flutter/material.dart';

import '../models/hospitalization_model.dart';
import '../services/hospitalization_service.dart';
import '../services/patient_session_service.dart';

class HospitalizationsScreen extends StatefulWidget {
  final String? patientId;
  final bool canEdit;
  final bool isEmergencyOnly;

  const HospitalizationsScreen({
    super.key,
    this.patientId,
    this.canEdit = false,
    this.isEmergencyOnly = false,
  });

  @override
  State<HospitalizationsScreen> createState() => _HospitalizationsScreenState();
}

class _HospitalizationsScreenState extends State<HospitalizationsScreen> {
  final HospitalizationService _service = HospitalizationService();

  bool _loading = true;
  String? _patientId;
  List<HospitalizationModel> _items = [];

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

  Future<void> _deleteItem(HospitalizationModel item) async {
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
        title: const Text('Hospitalizations'),
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
                title: Text(item.hospitalName ?? 'Hospitalization'),
                subtitle: Text([
                  if (item.admissionDate != null) 'Admission: ${item.admissionDate!.toIso8601String().split('T').first}',
                  if (item.dischargeDate != null) 'Discharge: ${item.dischargeDate!.toIso8601String().split('T').first}',
                  if ((item.reason ?? '').isNotEmpty) 'Reason: ${item.reason}',
                  if ((item.notes ?? '').isNotEmpty) 'Notes: ${item.notes}',
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