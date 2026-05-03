import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/audit_service.dart';
import '../services/patient_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  final _patientService = PatientService();
  final _audit = AuditService();

  final _firstNameController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _sexController = TextEditingController();
  final _dobController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _insurancePlanController = TextEditingController();
  final _covidVaccineController = TextEditingController();

  bool _loading = true;
  String? _profileId;
  String? _patientId;
  String? _appUserId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final identity = await _patientService.resolveIdentity();
    _appUserId = identity?.appUserId ?? await _patientService.getAppUserId();

    if (_appUserId == null) {
      setState(() => _loading = false);
      return;
    }

    final row = await _supabase
        .from('patient_profiles')
        .select()
        .eq('user_id', _appUserId!)
        .maybeSingle();

    if (row != null) {
      _profileId = row['id'] as String;
      _patientId = _profileId;

      _firstNameController.text = row['first_name']?.toString() ?? '';
      _familyNameController.text = row['family_name']?.toString() ?? '';
      _sexController.text = row['sex']?.toString() ?? 'unknown';
      _dobController.text = row['date_of_birth']?.toString() ?? '';
      _bloodTypeController.text = row['blood_type']?.toString() ?? '';
      _phoneController.text = row['phone']?.toString() ?? '';
      _emergencyNameController.text = row['emergency_contact_name']?.toString() ?? '';
      _emergencyPhoneController.text = row['emergency_contact_phone']?.toString() ?? '';
      _insurancePlanController.text = row['insurance_plan']?.toString() ?? '';
      _covidVaccineController.text = row['covid_vaccine_type']?.toString() ?? '';
    }

    setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    if (_appUserId == null) return;

    final payload = {
      'user_id': _appUserId,
      'first_name': _firstNameController.text.trim(),
      'family_name': _familyNameController.text.trim(),
      'sex': _sexController.text.trim().isEmpty ? 'unknown' : _sexController.text.trim(),
      'date_of_birth': _dobController.text.trim().isEmpty ? null : _dobController.text.trim(),
      'blood_type': _bloodTypeController.text.trim(),
      'phone': _phoneController.text.trim(),
      'emergency_contact_name': _emergencyNameController.text.trim(),
      'emergency_contact_phone': _emergencyPhoneController.text.trim(),
      'insurance_plan': _insurancePlanController.text.trim(),
      'covid_vaccine_type': _covidVaccineController.text.trim(),
    };

    if (_profileId == null) {
      final inserted = await _supabase
          .from('patient_profiles')
          .insert(payload)
          .select('id')
          .single();

      _profileId = inserted['id'] as String;
      _patientId = _profileId;

      await _audit.log(
        patientId: _patientId!,
        performedByUserId: _appUserId!,
        action: 'create',
        entityType: 'patient_profiles',
        entityId: _profileId,
        fieldName: 'first_name',
        newValue: _firstNameController.text.trim(),
      );
    } else {
      await _supabase
          .from('patient_profiles')
          .update(payload)
          .eq('id', _profileId!);

      await _audit.log(
        patientId: _profileId!,
        performedByUserId: _appUserId!,
        action: 'update',
        entityType: 'patient_profiles',
        entityId: _profileId,
        fieldName: 'first_name',
        newValue: _firstNameController.text.trim(),
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved')),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _familyNameController.dispose();
    _sexController.dispose();
    _dobController.dispose();
    _bloodTypeController.dispose();
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _insurancePlanController.dispose();
    _covidVaccineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _firstNameController, decoration: const InputDecoration(labelText: 'First name')),
          const SizedBox(height: 12),
          TextField(controller: _familyNameController, decoration: const InputDecoration(labelText: 'Family name')),
          const SizedBox(height: 12),
          TextField(controller: _sexController, decoration: const InputDecoration(labelText: 'Sex')),
          const SizedBox(height: 12),
          TextField(controller: _dobController, decoration: const InputDecoration(labelText: 'Date of birth (YYYY-MM-DD)')),
          const SizedBox(height: 12),
          TextField(controller: _bloodTypeController, decoration: const InputDecoration(labelText: 'Blood type')),
          const SizedBox(height: 12),
          TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
          const SizedBox(height: 12),
          TextField(controller: _emergencyNameController, decoration: const InputDecoration(labelText: 'Emergency contact name')),
          const SizedBox(height: 12),
          TextField(controller: _emergencyPhoneController, decoration: const InputDecoration(labelText: 'Emergency contact phone')),
          const SizedBox(height: 12),
          TextField(controller: _insurancePlanController, decoration: const InputDecoration(labelText: 'Insurance plan')),
          const SizedBox(height: 12),
          TextField(controller: _covidVaccineController, decoration: const InputDecoration(labelText: 'COVID vaccine type')),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveProfile,
            child: const Text('Save profile'),
          ),
        ],
      ),
    );
  }
}