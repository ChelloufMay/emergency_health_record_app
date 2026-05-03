import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/family_doctor_model.dart';
import '../services/patient_service.dart';

class FamilyDoctorScreen extends StatefulWidget {
  const FamilyDoctorScreen({super.key});

  @override
  State<FamilyDoctorScreen> createState() => _FamilyDoctorScreenState();
}

class _FamilyDoctorScreenState extends State<FamilyDoctorScreen> {
  final _supabase = Supabase.instance.client;
  final _patientService = PatientService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _notesController = TextEditingController();

  bool _loading = true;
  String? _patientId;
  String? _userId;
  String? _doctorId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final identity = await _patientService.resolveIdentity();
    if (identity == null) {
      setState(() => _loading = false);
      return;
    }

    _patientId = identity.patientId;
    _userId = identity.appUserId;

    final profileRow = await _supabase
        .from('patient_profiles')
        .select('family_doctor_id')
        .eq('id', _patientId!)
        .maybeSingle();

    _doctorId = profileRow?['family_doctor_id'] as String?;

    if (_doctorId != null) {
      final doctorRow = await _supabase
          .from('family_doctors')
          .select()
          .eq('id', _doctorId!)
          .maybeSingle();

      if (doctorRow != null) {
        final doctor = FamilyDoctorModel.fromMap(doctorRow);
        _nameController.text = doctor.fullName;
        _phoneController.text = doctor.phone ?? '';
        _licenseController.text = doctor.medicalLicenseNumber ?? '';
        _notesController.text = doctor.notes ?? '';
      }
    }

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_patientId == null || _userId == null) return;

    String doctorId = _doctorId ?? '';

    if (_doctorId == null) {
      final inserted = await _supabase
          .from('family_doctors')
          .insert({
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'medical_license_number': _licenseController.text.trim(),
        'notes': _notesController.text.trim(),
      })
          .select('id')
          .single();

      doctorId = inserted['id'] as String;
    } else {
      await _supabase.from('family_doctors').update({
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'medical_license_number': _licenseController.text.trim(),
        'notes': _notesController.text.trim(),
      }).eq('id', _doctorId!);
    }

    await _supabase.from('patient_profiles').update({
      'family_doctor_id': doctorId,
    }).eq('id', _patientId!);

    _doctorId = doctorId;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Family doctor saved')),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _notesController.dispose();
    super.dispose();
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
            decoration: const InputDecoration(labelText: 'Doctor name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _licenseController,
            decoration: const InputDecoration(labelText: 'Medical license number'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes'),
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