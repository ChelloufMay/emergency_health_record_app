import 'package:flutter/material.dart';
import '../models/family_doctor_model.dart';
import '../services/family_doctor_service.dart';
import '../services/patient_service.dart';

class FamilyDoctorScreen extends StatefulWidget {
  const FamilyDoctorScreen({super.key});

  @override
  State<FamilyDoctorScreen> createState() => _FamilyDoctorScreenState();
}

class _FamilyDoctorScreenState extends State<FamilyDoctorScreen> {
  final _service = FamilyDoctorService();
  final _patientService = PatientService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();
  final _governorateController = TextEditingController();
  final _cityController = TextEditingController();
  final _avenueController = TextEditingController();
  final _streetController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _extraDetailsController = TextEditingController();
  final _licenseController = TextEditingController();
  final _firstSeenController = TextEditingController();
  final _notesController = TextEditingController();

  bool _loading = true;
  String? _patientId;
  String? _userId;
  String? _doctorId;
  DateTime? _firstSeenDate;
  FamilyDoctorModel? _doctor;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _formatDate(DateTime date) {
    return date.toIso8601String().split('T').first;
  }

  Future<void> _pickFirstSeenDate() async {
    final initial = _firstSeenDate ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _firstSeenDate = picked;
      _firstSeenController.text = _formatDate(picked);
    });
  }

  Future<void> _load() async {
    final identity = await _patientService.resolveIdentity();
    if (identity == null) {
      setState(() => _loading = false);
      return;
    }

    _patientId = identity.patientId;
    _userId = identity.appUserId;

    _doctor = await _service.fetchForPatient(_patientId!);

    if (_doctor != null) {
      _doctorId = _doctor!.id;
      _nameController.text = _doctor!.fullName;
      _phoneController.text = _doctor!.phone ?? '';
      _countryController.text = _doctor!.country ?? '';
      _governorateController.text = _doctor!.governorate ?? '';
      _cityController.text = _doctor!.city ?? '';
      _avenueController.text = _doctor!.avenue ?? '';
      _streetController.text = _doctor!.street ?? '';
      _postalCodeController.text = _doctor!.postalCode ?? '';
      _extraDetailsController.text = _doctor!.extraDetails ?? '';
      _licenseController.text = _doctor!.medicalLicenseNumber ?? '';
      _firstSeenDate = _doctor!.firstSeenDate;
      _firstSeenController.text = _doctor!.firstSeenDate != null
          ? _formatDate(_doctor!.firstSeenDate!)
          : '';
      _notesController.text = _doctor!.notes ?? '';
    }

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_patientId == null || _userId == null) return;

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor name is required')),
      );
      return;
    }

    if (_countryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor office country is required')),
      );
      return;
    }

    final doctor = FamilyDoctorModel(
      id: _doctorId,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      addressId: _doctor?.addressId,
      country: _countryController.text.trim(),
      governorate: _governorateController.text.trim().isEmpty
          ? null
          : _governorateController.text.trim(),
      city: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      avenue: _avenueController.text.trim().isEmpty
          ? null
          : _avenueController.text.trim(),
      street: _streetController.text.trim().isEmpty
          ? null
          : _streetController.text.trim(),
      postalCode: _postalCodeController.text.trim().isEmpty
          ? null
          : _postalCodeController.text.trim(),
      extraDetails: _extraDetailsController.text.trim().isEmpty
          ? null
          : _extraDetailsController.text.trim(),
      medicalLicenseNumber: _licenseController.text.trim().isEmpty
          ? null
          : _licenseController.text.trim(),
      firstSeenDate: _firstSeenDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: _doctor?.createdAt,
      updatedAt: _doctor?.updatedAt,
    );

    try {
      final savedDoctorId = await _service.saveForPatient(
        patientId: _patientId!,
        doctor: doctor,
        performedByUserId: _userId!,
      );

      _doctorId = savedDoctorId;
      _doctor = await _service.fetchForPatient(_patientId!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Family doctor saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _governorateController.dispose();
    _cityController.dispose();
    _avenueController.dispose();
    _streetController.dispose();
    _postalCodeController.dispose();
    _extraDetailsController.dispose();
    _licenseController.dispose();
    _firstSeenController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Widget _buildAddressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Doctor office address',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _countryController,
              decoration: const InputDecoration(labelText: 'Country'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _governorateController,
              decoration: const InputDecoration(labelText: 'Governorate'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _avenueController,
              decoration: const InputDecoration(labelText: 'Avenue'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _streetController,
              decoration: const InputDecoration(labelText: 'Street'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _postalCodeController,
              decoration: const InputDecoration(labelText: 'Postal code'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _extraDetailsController,
              decoration: const InputDecoration(labelText: 'Extra details'),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family doctor')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Doctor name',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          const SizedBox(height: 12),

          // Address is stored in the separate addresses table.
          _buildAddressSection(),
          const SizedBox(height: 12),

          TextField(
            controller: _licenseController,
            decoration: const InputDecoration(
              labelText: 'Medical license number',
            ),
          ),
          const SizedBox(height: 12),

          // Calendar picker for first_seen_date.
          TextField(
            controller: _firstSeenController,
            readOnly: true,
            onTap: _pickFirstSeenDate,
            decoration: const InputDecoration(
              labelText: 'First seen date',
              hintText: 'Pick a date from the calendar',
              suffixIcon: Icon(Icons.calendar_today),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes'),
            maxLines: 3,
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _save,
            child: const Text('Save family doctor'),
          ),
        ],
      ),
    );
  }
}