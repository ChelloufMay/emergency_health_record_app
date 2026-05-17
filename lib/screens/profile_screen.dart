import 'package:flutter/material.dart';

import '../models/patient_profile_model.dart';
import '../services/patient_service.dart';
import '../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final PatientService _patientService = PatientService();

  final _formKey = GlobalKey<FormState>();

  final _legalIdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _insuranceController = TextEditingController();
  final _covidVaccineController = TextEditingController();

  final _countryController = TextEditingController();
  final _governorateController = TextEditingController();
  final _cityController = TextEditingController();
  final _avenueController = TextEditingController();
  final _streetController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _extraDetailsController = TextEditingController();

  DateTime? _dateOfBirth;
  bool _loading = true;
  bool _saving = false;
  String _sex = 'unknown';
  String? _profileId;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _legalIdController.dispose();
    _firstNameController.dispose();
    _familyNameController.dispose();
    _bloodTypeController.dispose();
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _insuranceController.dispose();
    _covidVaccineController.dispose();
    _countryController.dispose();
    _governorateController.dispose();
    _cityController.dispose();
    _avenueController.dispose();
    _streetController.dispose();
    _postalCodeController.dispose();
    _extraDetailsController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // This screen binds to the owner profile tables only:
    // - patient_profiles via ProfileService
    // - users via PatientService.ensureAppUserId
    final profile = await _profileService.fetchProfile();
    final identity = await _patientService.resolveIdentity();

    if (profile != null) {
      _profileId = profile.id;
      _userId = profile.userId;
      _legalIdController.text = profile.legalId ?? '';
      _firstNameController.text = profile.firstName;
      _familyNameController.text = profile.familyName;
      _sex = profile.sex;
      _dateOfBirth = profile.dateOfBirth;
      _bloodTypeController.text = profile.bloodType ?? '';
      _phoneController.text = profile.phone ?? '';
      _emergencyNameController.text = profile.emergencyContactName ?? '';
      _emergencyPhoneController.text = profile.emergencyContactPhone ?? '';
      _insuranceController.text = profile.insurancePlan ?? '';
      _covidVaccineController.text = profile.covidVaccineType ?? '';
    } else {
      _userId = identity?.appUserId;
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDate: _dateOfBirth ?? DateTime(1990),
    );

    if (picked != null && mounted) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final userId = _userId ?? await _patientService.ensureAppUserId();
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to resolve user id.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // The DB owns the actual patient row. The screen only prepares a model
      // that matches the patient_profiles columns and lets the service do the
      // insert/update work.
      final profile = PatientProfileModel(
        id: _profileId,
        userId: userId,
        legalId: _legalIdController.text.trim().isEmpty
            ? null
            : _legalIdController.text.trim(),
        firstName: _firstNameController.text.trim(),
        familyName: _familyNameController.text.trim(),
        sex: _sex,
        dateOfBirth: _dateOfBirth,
        bloodType: _bloodTypeController.text.trim().isEmpty
            ? null
            : _bloodTypeController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        emergencyContactName: _emergencyNameController.text.trim().isEmpty
            ? null
            : _emergencyNameController.text.trim(),
        emergencyContactPhone: _emergencyPhoneController.text.trim().isEmpty
            ? null
            : _emergencyPhoneController.text.trim(),
        insurancePlan: _insuranceController.text.trim().isEmpty
            ? null
            : _insuranceController.text.trim(),
        covidVaccineType: _covidVaccineController.text.trim().isEmpty
            ? null
            : _covidVaccineController.text.trim(),
      );

      // Address is saved through the profile service so the profile + address
      // relationship stays consistent with the DB foreign keys.
      final addressFields = <String, dynamic>{
        'country': _countryController.text.trim(),
        'governorate': _governorateController.text.trim(),
        'city': _cityController.text.trim(),
        'avenue': _avenueController.text.trim(),
        'street': _streetController.text.trim(),
        'postal_code': _postalCodeController.text.trim(),
        'extra_details': _extraDetailsController.text.trim(),
      };

      final savedId = await _profileService.saveProfile(
        profile: profile,
        performedByUserId: userId,
        addressFields: addressFields,
      );

      if (!mounted) return;
      setState(() => _profileId = savedId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved.')),
      );

      Navigator.of(context).pushNamedAndRemoveUntil('/entry', (route) => false);
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
      appBar: AppBar(
        title: const Text('My profile'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // These fields are the direct owner profile fields from
            // patient_profiles_enriched / patient_profiles.
            DropdownButtonFormField<String>(
              initialValue: _sex,
              decoration: const InputDecoration(labelText: 'Sex'),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
                DropdownMenuItem(value: 'unknown', child: Text('Unknown')),
              ],
              onChanged: (value) =>
                  setState(() => _sex = value ?? 'unknown'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _legalIdController,
              decoration: const InputDecoration(labelText: 'Legal ID'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First name'),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _familyNameController,
              decoration: const InputDecoration(labelText: 'Family name'),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date of birth'),
              subtitle: Text(
                _dateOfBirth == null
                    ? 'Not set'
                    : _dateOfBirth!.toIso8601String().split('T').first,
              ),
              trailing: IconButton(
                onPressed: _pickBirthDate,
                icon: const Icon(Icons.calendar_month),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bloodTypeController,
              decoration: const InputDecoration(labelText: 'Blood type'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emergencyNameController,
              decoration: const InputDecoration(
                labelText: 'Emergency contact name',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emergencyPhoneController,
              decoration: const InputDecoration(
                labelText: 'Emergency contact phone',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _insuranceController,
              decoration: const InputDecoration(
                labelText: 'Insurance plan',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _covidVaccineController,
              decoration: const InputDecoration(
                labelText: 'COVID vaccine type',
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Address',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _countryController,
              decoration: const InputDecoration(labelText: 'Country'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _governorateController,
              decoration: const InputDecoration(labelText: 'Governorate'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _avenueController,
              decoration: const InputDecoration(labelText: 'Avenue'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(labelText: 'Street'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _postalCodeController,
              decoration: const InputDecoration(labelText: 'Postal code'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _extraDetailsController,
              decoration: const InputDecoration(labelText: 'Extra details'),
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
                  : const Text('Save profile'),
            ),
          ],
        ),
      ),
    );
  }
}