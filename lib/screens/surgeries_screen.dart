import 'package:flutter/material.dart';

import '../models/surgery_model.dart';
import '../services/surgery_service.dart';
import '../services/patient_session_service.dart';

class SurgeriesScreen extends StatefulWidget {
  final String? patientId;
  final bool canEdit;
  final bool isEmergencyOnly;

  const SurgeriesScreen({
    super.key,
    this.patientId,
    this.canEdit = false,
    this.isEmergencyOnly = false,
  });

  @override
  State<SurgeriesScreen> createState() => _SurgeriesScreenState();
}

class _SurgeriesScreenState extends State<SurgeriesScreen> {
  final SurgeryService _service = SurgeryService();

  bool _loading = true;
  String? _patientId;
  List<SurgeryModel> _items = [];

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

  Future<void> _deleteItem(SurgeryModel item) async {
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
        title: const Text('Surgeries'),
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
                title: Text(item.surgeryName),
                subtitle: Text([
                  if (item.surgeryDate != null) 'Date: ${item.surgeryDate!.toIso8601String().split('T').first}',
                  if ((item.place ?? '').isNotEmpty) 'Place: ${item.place}',
                  if ((item.prostheticOrImplant ?? '').isNotEmpty) 'Implant: ${item.prostheticOrImplant}',
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