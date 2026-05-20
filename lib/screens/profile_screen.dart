import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/patient_profile_model.dart';
import '../services/patient_service.dart';
import '../services/patient_session_service.dart';
import '../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final PatientService _patientService = PatientService();
  final SupabaseClient _supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();

  final _legalIdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  final _countryController = TextEditingController(text: 'Tunisia');
  final _governorateController = TextEditingController();
  final _cityController = TextEditingController();
  final _avenueController = TextEditingController();
  final _streetController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _extraDetailsController = TextEditingController();

  DateTime? _dateOfBirth;
  bool _loading = true;
  bool _saving = false;

  // CHANGED: sex only shows male/female in the UI.
  String? _sex;
  String? _bloodType;
  String? _insurancePlan;
  String? _covidVaccineType;

  String? _profileId;
  String? _addressId;
  String? _userId;

  static const List<String> _bloodTypes = <String>[
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  static const List<String> _insurancePlans = <String>['CNAM', 'CNSS', 'CNRPS'];

  // CHANGED: short labels to avoid overflow; stored value remains the long DB value.
  static const Map<String, String> _covidVaccines = <String, String>{
    'Pfizer': 'Pfizer-BioNTech (Comirnaty / Tozinameran)',
    'Moderna': 'Moderna (Spikevax / mRNA-1273)',
    'AstraZeneca': 'Oxford-AstraZeneca (Vaxzevria / Covishield / AZD1222)',
    'J&J': 'Johnson & Johnson (Janssen / Ad26.COV2.S)',
    'Sputnik V': 'Sputnik V (Gam-COVID-Vac)',
    'CoronaVac': 'Sinovac (CoronaVac)',
    'Sinopharm': 'Sinopharm (BBIBP-CorV)',
  };

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
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _countryController.dispose();
    _governorateController.dispose();
    _cityController.dispose();
    _avenueController.dispose();
    _streetController.dispose();
    _postalCodeController.dispose();
    _extraDetailsController.dispose();
    super.dispose();
  }

  String? _normalizeOption(String? value, List<String> options) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    return options.contains(trimmed) ? trimmed : null;
  }

  Future<void> _load() async {
    try {
      final identity = await _patientService.resolveIdentity();
      _userId = identity?.appUserId;

      try {
        final profile = await _profileService.fetchProfile();

        if (profile != null) {
          _profileId = profile.id;
          _addressId = profile.addressId;
          _userId = profile.userId;

          _legalIdController.text = profile.legalId ?? '';
          _firstNameController.text = profile.firstName;
          _familyNameController.text = profile.familyName;

          // CHANGED: do not surface unknown in the selector.
          _sex = (profile.sex == 'male' || profile.sex == 'female') ? profile.sex : null;

          _dateOfBirth = profile.dateOfBirth;
          _bloodType = _normalizeOption(profile.bloodType, _bloodTypes);
          _phoneController.text = profile.phone ?? '';
          _emergencyNameController.text = profile.emergencyContactName ?? '';
          _emergencyPhoneController.text = profile.emergencyContactPhone ?? '';
          _insurancePlan = _normalizeOption(profile.insurancePlan, _insurancePlans);
          _covidVaccineType = _normalizeOption(
            profile.covidVaccineType,
            _covidVaccines.values.toList(),
          );

          final fullName =
          '${_firstNameController.text.trim()} ${_familyNameController.text.trim()}'
              .trim();

          if (profile.id != null) {
            PatientSessionService.instance.setSession(
              patientId: profile.id!,
              patientName: fullName.isEmpty ? null : fullName,
              permission: 'owner',
            );
          }

          if (profile.addressId != null && profile.addressId!.trim().isNotEmpty) {
            try {
              final addressRow = await _supabase
                  .from('addresses')
                  .select()
                  .eq('id', profile.addressId!)
                  .maybeSingle();

              if (addressRow != null) {
                _countryController.text =
                    (addressRow['country'] ?? 'Tunisia').toString();
                _governorateController.text =
                    (addressRow['governorate'] ?? '').toString();
                _cityController.text = (addressRow['city'] ?? '').toString();
                _avenueController.text = (addressRow['avenue'] ?? '').toString();
                _streetController.text = (addressRow['street'] ?? '').toString();
                _postalCodeController.text =
                    (addressRow['postal_code'] ?? '').toString();
                _extraDetailsController.text =
                    (addressRow['extra_details'] ?? '').toString();
              }
            } catch (_) {
              // Keep the form usable even if address fetch fails.
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not load profile: $e')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not initialize screen: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all the required fields.')),
      );
      return;
    }

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
      final profile = PatientProfileModel(
        id: _profileId,
        userId: userId,
        legalId: _legalIdController.text.trim().isEmpty
            ? null
            : _legalIdController.text.trim(),
        firstName: _firstNameController.text.trim(),
        familyName: _familyNameController.text.trim(),
        sex: _sex ?? 'unknown',
        dateOfBirth: _dateOfBirth,
        bloodType: _bloodType,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        addressId: _addressId,
        emergencyContactName: _emergencyNameController.text.trim().isEmpty
            ? null
            : _emergencyNameController.text.trim(),
        emergencyContactPhone: _emergencyPhoneController.text.trim().isEmpty
            ? null
            : _emergencyPhoneController.text.trim(),
        insurancePlan: _insurancePlan,
        covidVaccineType: _covidVaccineType,
      );

      final addressFields = <String, dynamic>{
        'country': _countryController.text.trim(),
        'governorate': _governorateController.text.trim(),
        'city': _cityController.text.trim(),
        'avenue': _avenueController.text.trim(),
        'street': _streetController.text.trim(),
        'postal_code': _postalCodeController.text.trim(),
        'extra_details': _extraDetailsController.text.trim(),
      };

      final savedProfileId = await _profileService.saveProfile(
        profile: profile,
        performedByUserId: userId,
        addressFields: addressFields,
      );

      if (!mounted) return;

      final displayName =
      '${_firstNameController.text.trim()} ${_familyNameController.text.trim()}'
          .trim();

      setState(() {
        _profileId = savedProfileId;
      });

      PatientSessionService.instance.setSession(
        patientId: savedProfileId,
        patientName: displayName.isEmpty ? null : displayName,
        permission: 'owner',
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved.')));

      Navigator.of(context).pushNamedAndRemoveUntil('/entry', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? hint,
    bool requiredField = false,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      menuMaxHeight: 300,
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      hint: hint == null ? null : Text(hint),
      validator: requiredField
          ? (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Please fill all the required fields';
        }
        return null;
      }
          : null,
      items: items
          .map((item) => DropdownMenuItem<String>(
        value: item,
        child: Text(item, overflow: TextOverflow.ellipsis),
      ))
          .toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My profile'),
        actions: [
          IconButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (!context.mounted) return;
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
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
            _sectionTitle('Identity'),
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
            DropdownButtonFormField<String>(
              isExpanded: true,
              menuMaxHeight: 220,
              initialValue: _sex,
              decoration: const InputDecoration(labelText: 'Sex'),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please fill all the required fields';
                }
                return null;
              },
              onChanged: (value) => setState(() => _sex = value),
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
            _buildDropdown(
              label: 'Blood type',
              value: _bloodType,
              items: _bloodTypes,
              hint: 'Select blood type',
              onChanged: (value) => setState(() => _bloodType = value),
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
            _buildDropdown(
              label: 'Insurance plan',
              value: _insurancePlan,
              items: _insurancePlans,
              hint: 'Select insurance plan',
              onChanged: (value) => setState(() => _insurancePlan = value),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'COVID vaccine',
              value: _covidVaccineType,
              items: _covidVaccines.values.toList(),
              hint: 'Select COVID vaccine',
              onChanged: (value) =>
                  setState(() => _covidVaccineType = value),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Address'),
            TextFormField(
              controller: _countryController,
              decoration: const InputDecoration(labelText: 'Country'),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null,
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
              decoration: const InputDecoration(
                labelText: 'Extra details',
              ),
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