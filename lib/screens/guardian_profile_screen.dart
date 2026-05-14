import 'package:flutter/material.dart';

import '../models/guardian_profile_model.dart';
import '../services/guardian_profile_service.dart';

class GuardianProfileScreen extends StatefulWidget {
  const GuardianProfileScreen({super.key});

  @override
  State<GuardianProfileScreen> createState() => _GuardianProfileScreenState();
}

class _GuardianProfileScreenState extends State<GuardianProfileScreen> {
  final GuardianProfileService _service = GuardianProfileService();
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _legalNoteController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

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
    _legalNoteController.dispose();
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
      _legalNoteController.text = profile.legalAuthorityNote ?? '';
      _phoneController.text = profile.phone ?? '';
      _addressController.text = profile.addressId ?? '';
      _notesController.text = profile.notes ?? '';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      final model = GuardianProfileModel(
        id: _profileId,
        userId: '',
        fullName: _fullNameController.text.trim(),
        relationshipToPatient: _relationshipController.text.trim().isEmpty ? null : _relationshipController.text.trim(),
        legalAuthorityNote: _legalNoteController.text.trim().isEmpty ? null : _legalNoteController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        addressId: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      final id = await _service.saveMine(model);
      if (!mounted) return;
      setState(() => _profileId = id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guardian profile saved.')),
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
      appBar: AppBar(title: const Text('Guardian profile')),
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
              controller: _legalNoteController,
              decoration: const InputDecoration(labelText: 'Legal authority note'),
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