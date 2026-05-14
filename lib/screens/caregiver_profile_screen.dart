import 'package:flutter/material.dart';

import '../models/caregiver_profile_model.dart';
import '../services/caregiver_profile_service.dart';

class CaregiverProfileScreen extends StatefulWidget {
  const CaregiverProfileScreen({super.key});

  @override
  State<CaregiverProfileScreen> createState() => _CaregiverProfileScreenState();
}

class _CaregiverProfileScreenState extends State<CaregiverProfileScreen> {
  final CaregiverProfileService _service = CaregiverProfileService();
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  String _proximity = 'near';
  String _attendance = 'phone_checkups';
  String _mobility = 'independent';
  bool _canDrive = false;
  bool _loading = true;
  bool _saving = false;
  String? _profileId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _relationshipController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profile = await _service.fetchMine();
    if (profile != null) {
      _profileId = profile.id;
      _fullNameController.text = profile.fullName;
      _relationshipController.text = profile.relationshipToPatient ?? '';
      _phoneController.text = profile.phone ?? '';
      _addressController.text = profile.addressId ?? '';
      _proximity = profile.proximity ?? 'near';
      _attendance = profile.attendance ?? 'phone_checkups';
      _mobility = profile.mobility;
      _canDrive = profile.canDrive ?? false;
      _notesController.text = '';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      final model = CaregiverProfileModel(
        id: _profileId,
        userId: '',
        fullName: _fullNameController.text.trim(),
        relationshipToPatient: _relationshipController.text.trim().isEmpty ? null : _relationshipController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        addressId: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        proximity: _proximity,
        attendance: _attendance,
        canDrive: _canDrive,
        mobility: _mobility,
      );

      final id = await _service.saveMine(model);
      if (!mounted) return;
      setState(() => _profileId = id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caregiver profile saved.')),
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
      appBar: AppBar(title: const Text('Caregiver profile')),
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
              controller: _relationshipController,
              decoration: const InputDecoration(labelText: 'Relationship to patient'),
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
            DropdownButtonFormField<String>(
              initialValue: _proximity,
              decoration: const InputDecoration(labelText: 'Proximity'),
              items: const [
                DropdownMenuItem(value: 'cohabitant', child: Text('Cohabitant')),
                DropdownMenuItem(value: 'near', child: Text('Near')),
                DropdownMenuItem(value: 'far', child: Text('Far')),
              ],
              onChanged: (v) => setState(() => _proximity = v ?? 'near'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _attendance,
              decoration: const InputDecoration(labelText: 'Attendance'),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'doctor_visits_only', child: Text('Doctor visits only')),
                DropdownMenuItem(value: 'phone_checkups', child: Text('Phone checkups')),
                DropdownMenuItem(value: 'long_periods_between_visits', child: Text('Long periods between visits')),
              ],
              onChanged: (v) => setState(() => _attendance = v ?? 'phone_checkups'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _mobility,
              decoration: const InputDecoration(labelText: 'Mobility'),
              items: const [
                DropdownMenuItem(value: 'independent', child: Text('Independent')),
                DropdownMenuItem(value: 'cane', child: Text('Cane')),
                DropdownMenuItem(value: 'wheelchair', child: Text('Wheelchair')),
                DropdownMenuItem(value: 'needs_help', child: Text('Needs help')),
              ],
              onChanged: (v) => setState(() => _mobility = v ?? 'independent'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Can drive'),
              value: _canDrive,
              onChanged: (v) => setState(() => _canDrive = v),
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