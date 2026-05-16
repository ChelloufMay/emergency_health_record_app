import 'package:flutter/material.dart';

import '../models/family_doctor_model.dart';
import '../models/family_doctor_with_address_model.dart';
import '../services/family_doctor_service.dart';
import '../services/patient_service.dart';
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
  final PatientService _patientService = PatientService();

  bool _loading = true;
  String? _patientId;
  FamilyDoctorWithAddressModel? _doctor;

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

  Future<void> _edit() async {
    if (!widget.canEdit) return;
    final patientId = _patientId;
    if (patientId == null) return;

    final current = _doctor;

    final fullNameController = TextEditingController(text: current?.fullName ?? '');
    final phoneController = TextEditingController(text: current?.phone ?? '');
    final licenseController = TextEditingController(text: current?.medicalLicenseNumber ?? '');
    final firstSeenController = TextEditingController(
      text: current?.firstSeenDate?.toIso8601String().split('T').first ?? '',
    );
    final notesController = TextEditingController(text: current?.notes ?? '');

    final countryController = TextEditingController(text: current?.country ?? '');
    final governorateController = TextEditingController(text: current?.governorate ?? '');
    final cityController = TextEditingController(text: current?.city ?? '');
    final avenueController = TextEditingController(text: current?.avenue ?? '');
    final streetController = TextEditingController(text: current?.street ?? '');
    final postalCodeController = TextEditingController(text: current?.postalCode ?? '');
    final extraDetailsController = TextEditingController(text: current?.extraDetails ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Family doctor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Family doctor is split across family_doctors + addresses,
                // so the editor keeps both sides visible and editable together.
                TextField(controller: fullNameController, decoration: const InputDecoration(labelText: 'Full name')),
                const SizedBox(height: 12),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
                const SizedBox(height: 12),
                TextField(controller: licenseController, decoration: const InputDecoration(labelText: 'Medical license number')),
                const SizedBox(height: 12),
                TextField(controller: firstSeenController, decoration: const InputDecoration(labelText: 'First seen date', hintText: 'YYYY-MM-DD')),
                const SizedBox(height: 12),
                TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
                const Divider(height: 32),
                TextField(controller: countryController, decoration: const InputDecoration(labelText: 'Country')),
                const SizedBox(height: 12),
                TextField(controller: governorateController, decoration: const InputDecoration(labelText: 'Governorate')),
                const SizedBox(height: 12),
                TextField(controller: cityController, decoration: const InputDecoration(labelText: 'City')),
                const SizedBox(height: 12),
                TextField(controller: avenueController, decoration: const InputDecoration(labelText: 'Avenue')),
                const SizedBox(height: 12),
                TextField(controller: streetController, decoration: const InputDecoration(labelText: 'Street')),
                const SizedBox(height: 12),
                TextField(controller: postalCodeController, decoration: const InputDecoration(labelText: 'Postal code')),
                const SizedBox(height: 12),
                TextField(controller: extraDetailsController, decoration: const InputDecoration(labelText: 'Extra details')),
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
      fullNameController.dispose();
      phoneController.dispose();
      licenseController.dispose();
      firstSeenController.dispose();
      notesController.dispose();
      countryController.dispose();
      governorateController.dispose();
      cityController.dispose();
      avenueController.dispose();
      streetController.dispose();
      postalCodeController.dispose();
      extraDetailsController.dispose();
      return;
    }

    final performedByUserId = await _patientService.ensureAppUserId();
    if (performedByUserId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to resolve current app user.')),
      );
      return;
    }

    final model = FamilyDoctorModel(
      id: current?.id,
      fullName: fullNameController.text.trim(),
      phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
      addressId: current?.addressId,
      medicalLicenseNumber: licenseController.text.trim().isEmpty ? null : licenseController.text.trim(),
      firstSeenDate: firstSeenController.text.trim().isEmpty
          ? null
          : DateTime.tryParse(firstSeenController.text.trim()),
      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      createdByUserId: performedByUserId,
    );

    await _service.saveForPatient(
      patientId: patientId,
      doctor: model,
      addressFields: {
        'country': countryController.text.trim(),
        'governorate': governorateController.text.trim(),
        'city': cityController.text.trim(),
        'avenue': avenueController.text.trim(),
        'street': streetController.text.trim(),
        'postal_code': postalCodeController.text.trim(),
        'extra_details': extraDetailsController.text.trim(),
      },
      performedByUserId: performedByUserId,
    );

    fullNameController.dispose();
    phoneController.dispose();
    licenseController.dispose();
    firstSeenController.dispose();
    notesController.dispose();
    countryController.dispose();
    governorateController.dispose();
    cityController.dispose();
    avenueController.dispose();
    streetController.dispose();
    postalCodeController.dispose();
    extraDetailsController.dispose();

    await _load();
  }

  Future<void> _delete() async {
    if (!widget.canEdit) return;
    final patientId = _patientId;
    final doctorId = _doctor?.id;
    if (patientId == null || doctorId == null) return;

    final performedByUserId = await _patientService.ensureAppUserId();
    if (performedByUserId == null) return;

    await _service.deleteForPatient(
      patientId: patientId,
      doctorId: doctorId,
      performedByUserId: performedByUserId,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final doctor = _doctor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family doctor'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          if (widget.canEdit && doctor != null) IconButton(onPressed: _edit, icon: const Icon(Icons.edit)),
          if (widget.canEdit && doctor != null) IconButton(onPressed: _delete, icon: const Icon(Icons.delete)),
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
              title: Text(doctor?.fullName ?? 'No family doctor'),
              subtitle: Text(
                doctor == null
                    ? 'No linked doctor'
                    : [
                  if ((doctor.phone ?? '').isNotEmpty) 'Phone: ${doctor.phone}',
                  if ((doctor.medicalLicenseNumber ?? '').isNotEmpty)
                    'License: ${doctor.medicalLicenseNumber}',
                  if ((doctor.firstSeenDate?.toIso8601String() ?? '').isNotEmpty)
                    'First seen: ${doctor.firstSeenDate!.toIso8601String().split('T').first}',
                  if ((doctor.country ?? '').isNotEmpty) 'Country: ${doctor.country}',
                  if ((doctor.governorate ?? '').isNotEmpty) 'Governorate: ${doctor.governorate}',
                  if ((doctor.city ?? '').isNotEmpty) 'City: ${doctor.city}',
                  if ((doctor.avenue ?? '').isNotEmpty) 'Avenue: ${doctor.avenue}',
                  if ((doctor.street ?? '').isNotEmpty) 'Street: ${doctor.street}',
                  if ((doctor.postalCode ?? '').isNotEmpty) 'Postal code: ${doctor.postalCode}',
                  if ((doctor.extraDetails ?? '').isNotEmpty) 'Extra details: ${doctor.extraDetails}',
                  if ((doctor.notes ?? '').isNotEmpty) 'Notes: ${doctor.notes}',
                ].join('\n'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}