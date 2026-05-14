import 'package:flutter/material.dart';

import '../models/family_doctor_model.dart';
import '../services/family_doctor_service.dart';
import '../services/patient_session_service.dart';

class FamilyDoctorScreen extends StatefulWidget {
  final String? patientId;
  final bool canEdit;
  final bool isEmergencyOnly;

  const FamilyDoctorScreen({
    super.key,
    this.patientId,
    this.canEdit = false,
    this.isEmergencyOnly = false,
  });

  @override
  State<FamilyDoctorScreen> createState() => _FamilyDoctorScreenState();
}

class _FamilyDoctorScreenState extends State<FamilyDoctorScreen> {
  final FamilyDoctorService _service = FamilyDoctorService();

  bool _loading = true;
  String? _patientId;
  FamilyDoctorModel? _doctor;

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

    final doctor = await _service.fetchForPatient(patientId);
    if (!mounted) return;
    setState(() {
      _patientId = patientId;
      _doctor = doctor;
      _loading = false;
    });
  }

  Future<void> _deleteDoctor() async {
    if (!widget.canEdit) return;
    final patientId = _patientId;
    final doctorId = _doctor?.id;
    if (patientId == null || doctorId == null) return;

    await _service.deleteForPatient(
      patientId: patientId,
      doctorId: doctorId,
      performedByUserId: 'current',
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final d = _doctor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family doctor'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
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
              leading: const Icon(Icons.person_search),
              title: Text(d?.fullName ?? 'No doctor linked'),
              subtitle: Text([
                if ((d?.phone ?? '').isNotEmpty) 'Phone: ${d?.phone}',
                if ((d?.medicalLicenseNumber ?? '').isNotEmpty) 'License: ${d?.medicalLicenseNumber}',
                if ((d?.notes ?? '').isNotEmpty) 'Notes: ${d?.notes}',
              ].join('\n')),
              trailing: widget.canEdit && d != null
                  ? IconButton(
                onPressed: _deleteDoctor,
                icon: const Icon(Icons.delete),
              )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}