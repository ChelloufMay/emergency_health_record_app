import 'package:flutter/material.dart';

import '../models/family_doctor_model.dart';
import '../models/family_doctor_with_address_model.dart';
import '../services/family_doctor_service.dart';
import '../services/patient_session_service.dart';
import '../utils/section_screen_access.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/medical_save_dialog.dart';

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
  FamilyDoctorWithAddressModel? _item;
  late SectionScreenAccess _access;

  @override
  void initState() {
    super.initState();
    _access = SectionScreenAccess(
      widgetCanEdit: widget.canEdit,
      widgetIsEmergencyOnly: widget.isEmergencyOnly,
    );
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

    final item = await _service.fetchForPatient(patientId);
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

    final fullNameController = TextEditingController(text: current?.fullName ?? '');
    final phoneController = TextEditingController(text: current?.phone ?? '');
    final licenseController =
    TextEditingController(text: current?.medicalLicenseNumber ?? '');
    final notesController = TextEditingController(text: current?.notes ?? '');

    final countryController =
    TextEditingController(text: current?.country ?? 'Tunisia');
    final governorateController =
    TextEditingController(text: current?.governorate ?? '');
    final cityController = TextEditingController(text: current?.city ?? '');
    final avenueController = TextEditingController(text: current?.avenue ?? '');
    final streetController = TextEditingController(text: current?.street ?? '');
    final postalCodeController =
    TextEditingController(text: current?.postalCode ?? '');
    final extraDetailsController =
    TextEditingController(text: current?.extraDetails ?? '');

    DateTime? firstSeenDate = current?.firstSeenDate;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return MedicalSaveDialog(
          title: current == null ? 'Add family doctor' : 'Edit family doctor',
          validate: () {
            if (fullNameController.text.trim().isEmpty) {
              return 'Doctor name is required.';
            }
            return null;
          },
          onSave: () async {
            final doctor = FamilyDoctorModel(
              id: current?.id,
              fullName: fullNameController.text.trim(),
              phone: phoneController.text.trim().isEmpty
                  ? null
                  : phoneController.text.trim(),
              addressId: current?.addressId,
              medicalLicenseNumber: licenseController.text.trim().isEmpty
                  ? null
                  : licenseController.text.trim(),
              firstSeenDate: firstSeenDate,
              notes: notesController.text.trim().isEmpty
                  ? null
                  : notesController.text.trim(),
              createdByUserId: current?.createdByUserId,
            );

            final addressFields = <String, dynamic>{
              'country': countryController.text.trim(),
              'governorate': governorateController.text.trim(),
              'city': cityController.text.trim(),
              'avenue': avenueController.text.trim(),
              'street': streetController.text.trim(),
              'postal_code': postalCodeController.text.trim(),
              'extra_details': extraDetailsController.text.trim(),
            };

            final performedByUserId = current?.createdByUserId ??
                PatientSessionService.instance.current?.patientId ??
                '';
            await _service.saveForPatient(
              patientId: patientId,
              doctor: doctor,
              addressFields: addressFields,
              performedByUserId: performedByUserId,
            );
          },
          contentBuilder: (_, saving) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: fullNameController,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Doctor full name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        enabled: !saving,
                        decoration: const InputDecoration(labelText: 'Phone'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: licenseController,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Medical license number',
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('First seen date'),
                        subtitle: Text(
                          firstSeenDate == null
                              ? 'Not set'
                              : firstSeenDate!.toIso8601String().split('T').first,
                        ),
                        trailing: IconButton(
                          onPressed: saving
                              ? null
                              : () async {
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                              initialDate: firstSeenDate ?? DateTime.now(),
                            );
                            if (picked != null) {
                              setDialogState(() => firstSeenDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_month),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesController,
                        enabled: !saving,
                        decoration: const InputDecoration(labelText: 'Notes'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Address',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: countryController,
                        enabled: !saving,
                        decoration: const InputDecoration(labelText: 'Country'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: governorateController,
                        enabled: !saving,
                        decoration:
                        const InputDecoration(labelText: 'Governorate'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: cityController,
                        enabled: !saving,
                        decoration: const InputDecoration(labelText: 'City'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: avenueController,
                        enabled: !saving,
                        decoration: const InputDecoration(labelText: 'Avenue'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: streetController,
                        enabled: !saving,
                        decoration: const InputDecoration(labelText: 'Street'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: postalCodeController,
                        enabled: !saving,
                        decoration:
                        const InputDecoration(labelText: 'Postal code'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: extraDetailsController,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Extra details',
                        ),
                        maxLines: 3,
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

    fullNameController.dispose();
    phoneController.dispose();
    licenseController.dispose();
    notesController.dispose();
    countryController.dispose();
    governorateController.dispose();
    cityController.dispose();
    avenueController.dispose();
    streetController.dispose();
    postalCodeController.dispose();
    extraDetailsController.dispose();

    if (saved == true) {
      await _load();
    }
  }

  Future<void> _delete() async {
    if (!_access.allowMutations) return;
    final patientId = _patientId;
    final doctorId = _item?.id;
    if (patientId == null || doctorId == null) return;

    // CHANGED: confirmation before delete
    final confirmed = await showDeleteConfirmDialog(
      context: context,
      title: 'Delete family doctor?',
      message: 'This action cannot be undone.',
    );

    if (!confirmed || !mounted) return;

    final performedByUserId =
        PatientSessionService.instance.current?.patientId ?? '';
    await _service.deleteForPatient(
      patientId: patientId,
      doctorId: doctorId,
      performedByUserId: performedByUserId,
    );

    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family doctor'),
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
              title: Text(item?.fullName ?? 'No doctor set'),
              subtitle: Text(
                item == null
                    ? 'No record'
                    : [
                  if ((item.phone ?? '').isNotEmpty)
                    'Phone: ${item.phone}',
                  if ((item.medicalLicenseNumber ?? '').isNotEmpty)
                    'License: ${item.medicalLicenseNumber}',
                  if (item.firstSeenDate != null)
                    'First seen: ${item.firstSeenDate!.toIso8601String().split('T').first}',
                  if ((item.country ?? '').isNotEmpty)
                    'Country: ${item.country}',
                  if ((item.governorate ?? '').isNotEmpty)
                    'Governorate: ${item.governorate}',
                  if ((item.city ?? '').isNotEmpty)
                    'City: ${item.city}',
                  if ((item.avenue ?? '').isNotEmpty)
                    'Avenue: ${item.avenue}',
                  if ((item.street ?? '').isNotEmpty)
                    'Street: ${item.street}',
                  if ((item.postalCode ?? '').isNotEmpty)
                    'Postal code: ${item.postalCode}',
                  if ((item.extraDetails ?? '').isNotEmpty)
                    'Extra details: ${item.extraDetails}',
                  if ((item.notes ?? '').isNotEmpty)
                    'Notes: ${item.notes}',
                ].join('\n'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}