import 'package:flutter/material.dart';
import '../services/clinician_profile_service.dart';
import '../services/patient_service.dart';

class ClinicianProfileScreen extends StatefulWidget {
  const ClinicianProfileScreen({super.key});

  @override
  State<ClinicianProfileScreen> createState() => _ClinicianProfileScreenState();
}

class _ClinicianProfileScreenState extends State<ClinicianProfileScreen> {
  final PatientService _patientService = PatientService();
  final ClinicianProfileService _service = ClinicianProfileService();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressIdController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _facilityController = TextEditingController();
  final TextEditingController _workPhoneController = TextEditingController();
  final TextEditingController _verificationNoteController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _isVerified = false;
  String? _userId;
  String? _profileId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressIdController.dispose();
    _licenseController.dispose();
    _specializationController.dispose();
    _facilityController.dispose();
    _workPhoneController.dispose();
    _verificationNoteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = await _patientService.ensureAppUserId();
    if (userId == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final row = await _service.fetchMyProfile(userId);

    if (row != null) {
      _profileId = row['id']?.toString();
      _fullNameController.text = row['full_name']?.toString() ?? '';
      _phoneController.text = row['phone']?.toString() ?? '';
      _addressIdController.text = row['address_id']?.toString() ?? '';
      _licenseController.text = row['license_number']?.toString() ?? '';
      _specializationController.text = row['specialization']?.toString() ?? '';
      _facilityController.text = row['facility_name']?.toString() ?? '';
      _workPhoneController.text = row['work_phone']?.toString() ?? '';
      _verificationNoteController.text = row['verification_note']?.toString() ?? '';
      _notesController.text = row['notes']?.toString() ?? '';
      _isVerified = row['is_verified'] == true;
    }

    if (!mounted) return;
    setState(() {
      _userId = userId;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_userId == null) return;

    setState(() => _saving = true);
    try {
      final row = await _service.saveMyProfile(
        userId: _userId!,
        fullName: _fullNameController.text,
        phone: _phoneController.text,
        addressId: _addressIdController.text,
        licenseNumber: _licenseController.text,
        specialization: _specializationController.text,
        facilityName: _facilityController.text,
        workPhone: _workPhoneController.text,
        isVerified: _isVerified,
        verificationNote: _verificationNoteController.text,
        notes: _notesController.text,
      );
      _profileId = row['id']?.toString();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clinician profile saved')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinician profile'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _fullNameController,
            decoration: const InputDecoration(labelText: 'Full name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressIdController,
            decoration: const InputDecoration(labelText: 'Address ID (optional)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _licenseController,
            decoration: const InputDecoration(labelText: 'License number'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _specializationController,
            decoration: const InputDecoration(labelText: 'Specialization'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _facilityController,
            decoration: const InputDecoration(labelText: 'Facility / workplace'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _workPhoneController,
            decoration: const InputDecoration(labelText: 'Work phone'),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _isVerified,
            onChanged: (value) => setState(() => _isVerified = value),
            title: const Text('Verified'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _verificationNoteController,
            decoration: const InputDecoration(labelText: 'Verification note'),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes'),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save clinician profile'),
          ),
        ],
      ),
    );
  }
}