import 'package:flutter/material.dart';
import '../services/guardian_profile_service.dart';
import '../services/patient_service.dart';

class GuardianProfileScreen extends StatefulWidget {
  const GuardianProfileScreen({super.key});

  @override
  State<GuardianProfileScreen> createState() => _GuardianProfileScreenState();
}

class _GuardianProfileScreenState extends State<GuardianProfileScreen> {
  final PatientService _patientService = PatientService();
  final GuardianProfileService _service = GuardianProfileService();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();
  final TextEditingController _authorityController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressIdController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
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
    _relationshipController.dispose();
    _authorityController.dispose();
    _phoneController.dispose();
    _addressIdController.dispose();
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
      _relationshipController.text = row['relationship_to_patient']?.toString() ?? '';
      _authorityController.text = row['legal_authority_note']?.toString() ?? '';
      _phoneController.text = row['phone']?.toString() ?? '';
      _addressIdController.text = row['address_id']?.toString() ?? '';
      _notesController.text = row['notes']?.toString() ?? '';
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
        relationshipToPatient: _relationshipController.text,
        legalAuthorityNote: _authorityController.text,
        phone: _phoneController.text,
        addressId: _addressIdController.text,
        notes: _notesController.text,
      );
      _profileId = row['id']?.toString();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guardian profile saved')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian profile'),
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
            controller: _relationshipController,
            decoration: const InputDecoration(labelText: 'Relationship to patient'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _authorityController,
            decoration: const InputDecoration(labelText: 'Legal authority note'),
            maxLines: 3,
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
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes'),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save guardian profile'),
          ),
        ],
      ),
    );
  }
}