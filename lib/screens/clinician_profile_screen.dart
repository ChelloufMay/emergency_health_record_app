import 'package:flutter/material.dart';

import '../models/clinician_profile_model.dart';
import '../services/clinician_profile_service.dart';

class ClinicianProfileScreen extends StatefulWidget {
  const ClinicianProfileScreen({super.key});

  @override
  State<ClinicianProfileScreen> createState() => _ClinicianProfileScreenState();
}

class _ClinicianProfileScreenState extends State<ClinicianProfileScreen> {
  final ClinicianProfileService _service = ClinicianProfileService();
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _licenseController = TextEditingController();
  final _specializationController = TextEditingController();
  final _facilityController = TextEditingController();
  final _workPhoneController = TextEditingController();
  final _verificationNoteController = TextEditingController();
  final _notesController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _isVerified = false;
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
    _addressController.dispose();
    _licenseController.dispose();
    _specializationController.dispose();
    _facilityController.dispose();
    _workPhoneController.dispose();
    _verificationNoteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profile = await _service.fetchMine();
    if (profile != null) {
      _profileId = profile.id;
      _fullNameController.text = profile.fullName;
      _phoneController.text = profile.phone ?? '';
      _addressController.text = profile.addressId ?? '';
      _licenseController.text = profile.licenseNumber ?? '';
      _specializationController.text = profile.specialization ?? '';
      _facilityController.text = profile.facilityName ?? '';
      _workPhoneController.text = profile.workPhone ?? '';
      _verificationNoteController.text = profile.verificationNote ?? '';
      _notesController.text = profile.notes ?? '';
      _isVerified = profile.isVerified;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      final model = ClinicianProfileModel(
        id: _profileId,
        userId: '',
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        addressId: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        licenseNumber: _licenseController.text.trim().isEmpty ? null : _licenseController.text.trim(),
        specialization: _specializationController.text.trim().isEmpty ? null : _specializationController.text.trim(),
        facilityName: _facilityController.text.trim().isEmpty ? null : _facilityController.text.trim(),
        workPhone: _workPhoneController.text.trim().isEmpty ? null : _workPhoneController.text.trim(),
        isVerified: _isVerified,
        verificationNote: _verificationNoteController.text.trim().isEmpty ? null : _verificationNoteController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      final id = await _service.saveMine(model);
      if (!mounted) return;
      setState(() => _profileId = id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clinician profile saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clinician profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address ID'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _licenseController,
              decoration: const InputDecoration(labelText: 'License number'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _specializationController,
              decoration: const InputDecoration(labelText: 'Specialization'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _facilityController,
              decoration: const InputDecoration(labelText: 'Facility name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _workPhoneController,
              decoration: const InputDecoration(labelText: 'Work phone'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isVerified,
              onChanged: (value) => setState(() => _isVerified = value),
              title: const Text('Verified'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _verificationNoteController,
              decoration: const InputDecoration(labelText: 'Verification note'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}