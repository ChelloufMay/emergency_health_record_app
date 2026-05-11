import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/patient_profile_model.dart';
import '../services/patient_service.dart';
import '../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PatientService _patientService = PatientService();
  final ProfileService _profileService = ProfileService();

  final TextEditingController _legalIdController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _familyNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emergencyNameController = TextEditingController();
  final TextEditingController _emergencyPhoneController =
  TextEditingController();

  // Address fields are now part of the profile flow.
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _governorateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _avenueController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _extraDetailsController =
  TextEditingController();

  bool _loading = true;
  bool _saving = false;

  String? _profileId;
  String? _appUserId;
  String? _addressId;
  String? _familyDoctorId;

  String _sex = 'unknown';
  DateTime? _selectedDob;
  String? _bloodType;
  String? _insurancePlan;
  String? _covidVaccineType;

  static const List<String> _sexOptions = ['male', 'female'];
  static const List<String> _bloodTypeOptions = [
    'O-',
    'O+',
    'B-',
    'B+',
    'A-',
    'A+',
    'AB-',
    'AB+',
  ];
  static const List<String> _insurancePlanOptions = ['CNAM', 'CNSS', 'CNRPS'];
  static const List<String> _covidVaccineOptions = [
    'Pfizer-BioNTech (Comirnaty)',
    'Moderna (Spikevax / mRNA-1273)',
    'AstraZeneca/Oxford (Vaxzevria)',
    'Johnson & Johnson (Janssen)',
    'Sputnik V (Gam-COVID-Vac)',
    'CoronaVac (Sinovac)',
    'Sinopharm (BBIBP-CorV)',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  Future<void> _loadAddress(String? addressId) async {
    if (addressId == null || addressId.isEmpty) return;

    try {
      final addressRow = await _supabase
          .from('addresses')
          .select()
          .eq('id', addressId)
          .maybeSingle();

      if (addressRow == null) return;

      _countryController.text = addressRow['country']?.toString() ?? '';
      _governorateController.text =
          addressRow['governorate']?.toString() ?? '';
      _cityController.text = addressRow['city']?.toString() ?? '';
      _avenueController.text = addressRow['avenue']?.toString() ?? '';
      _streetController.text = addressRow['street']?.toString() ?? '';
      _postalCodeController.text = addressRow['postal_code']?.toString() ?? '';
      _extraDetailsController.text =
          addressRow['extra_details']?.toString() ?? '';
    } catch (e) {
      debugPrint('_loadAddress error: $e');
    }
  }

  Future<void> _loadProfile() async {
    try {
      _appUserId = await _patientService.ensureAppUserId();
      if (_appUserId == null) return;

      final row = await _supabase
          .from('patient_profiles')
          .select()
          .eq('user_id', _appUserId!)
          .maybeSingle();

      if (row != null) {
        _profileId = row['id']?.toString();
        _addressId = row['address_id']?.toString();
        _familyDoctorId = row['family_doctor_id']?.toString();

        _legalIdController.text = row['legal_id']?.toString() ?? '';
        _firstNameController.text = row['first_name']?.toString() ?? '';
        _familyNameController.text = row['family_name']?.toString() ?? '';
        _phoneController.text = row['phone']?.toString() ?? '';
        _emergencyNameController.text =
            row['emergency_contact_name']?.toString() ?? '';
        _emergencyPhoneController.text =
            row['emergency_contact_phone']?.toString() ?? '';

        final sexValue = row['sex']?.toString();
        _sex = ((sexValue == 'male' || sexValue == 'female')
            ? sexValue
            : 'unknown')!;

        _selectedDob = _parseDate(row['date_of_birth']);

        final bloodTypeValue = row['blood_type']?.toString();
        if (_bloodTypeOptions.contains(bloodTypeValue)) {
          _bloodType = bloodTypeValue;
        }

        final insuranceValue = row['insurance_plan']?.toString();
        if (_insurancePlanOptions.contains(insuranceValue)) {
          _insurancePlan = insuranceValue;
        }

        final covidValue = row['covid_vaccine_type']?.toString();
        if (_covidVaccineOptions.contains(covidValue)) {
          _covidVaccineType = covidValue;
        }

        // Load the linked address row into the new address fields.
        await _loadAddress(_addressId);
      }
    } catch (e) {
      debugPrint('_loadProfile error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate =
        _selectedDob ?? DateTime(now.year - 30, now.month, now.day);
    final firstDate = DateTime(1900);
    final lastDate = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate)
          ? firstDate
          : (initialDate.isAfter(lastDate) ? lastDate : initialDate),
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null && mounted) {
      setState(() => _selectedDob = picked);
    }
  }

  bool _hasAnyAddressInput() {
    return [
      _countryController.text,
      _governorateController.text,
      _cityController.text,
      _avenueController.text,
      _streetController.text,
      _postalCodeController.text,
      _extraDetailsController.text,
    ].any((value) => value.trim().isNotEmpty);
  }

  Future<void> _saveProfile() async {
    final firstName = _firstNameController.text.trim();
    final familyName = _familyNameController.text.trim();

    if (firstName.isEmpty || familyName.isEmpty) {
      _showMessage(
        'First name and family name are required.',
        isError: true,
      );
      return;
    }

    // If the user starts filling address fields, country should not be blank.
    if (_hasAnyAddressInput() && _countryController.text.trim().isEmpty) {
      _showMessage(
        'Country is required when entering address information.',
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);

    try {
      if (_appUserId == null) {
        _appUserId = await _patientService.ensureAppUserId();
      }

      if (_appUserId == null) {
        _showMessage(
          'Could not resolve the current user.',
          isError: true,
        );
        return;
      }

      final patientId = await _profileService.saveProfile(
        profile: PatientProfileModel(
          id: _profileId,
          userId: _appUserId!,
          legalId: _legalIdController.text.trim(),
          firstName: firstName,
          familyName: familyName,
          sex: _sex,
          dateOfBirth: _selectedDob,
          bloodType: _bloodType,
          phone: _phoneController.text.trim(),
          addressId: _addressId,
          emergencyContactName: _emergencyNameController.text.trim(),
          emergencyContactPhone: _emergencyPhoneController.text.trim(),
          insurancePlan: _insurancePlan,
          covidVaccineType: _covidVaccineType,
          familyDoctorId: _familyDoctorId,
        ),
        performedByUserId: _appUserId!,
        addressFields: {
          'country': _countryController.text.trim(),
          'governorate': _governorateController.text.trim(),
          'city': _cityController.text.trim(),
          'avenue': _avenueController.text.trim(),
          'street': _streetController.text.trim(),
          'postal_code': _postalCodeController.text.trim(),
          'extra_details': _extraDetailsController.text.trim(),
        },
      );

      _profileId = patientId;
      await _loadProfile();

      _showMessage('Profile saved successfully.');
    } on PostgrestException catch (e) {
      debugPrint('Profile save PostgrestException: ${e.message} code:${e.code}');
      _showMessage(
        'Database error: ${e.message}',
        isError: true,
      );
    } catch (e) {
      debugPrint('Profile save error: $e');
      _showMessage('Unexpected error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  void dispose() {
    _legalIdController.dispose();
    _firstNameController.dispose();
    _familyNameController.dispose();
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();

    // Dispose the new address controllers too.
    _countryController.dispose();
    _governorateController.dispose();
    _cityController.dispose();
    _avenueController.dispose();
    _streetController.dispose();
    _postalCodeController.dispose();
    _extraDetailsController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dobText =
    _selectedDob == null ? 'Select date' : _formatDate(_selectedDob!);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _legalIdController,
            decoration: const InputDecoration(
              labelText: 'Legal ID',
              hintText: 'National ID / passport / official number',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _firstNameController,
            decoration: const InputDecoration(labelText: 'First name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _familyNameController,
            decoration: const InputDecoration(labelText: 'Family name'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue:
            _sex == 'male' || _sex == 'female' ? _sex : null,
            decoration: const InputDecoration(labelText: 'Sex'),
            hint: const Text('Select sex'),
            items: _sexOptions
                .map(
                  (v) => DropdownMenuItem(
                value: v,
                child: Text(v[0].toUpperCase() + v.substring(1)),
              ),
            )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _sex = v);
            },
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date of birth',
              border: OutlineInputBorder(),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dobText),
                TextButton(
                  onPressed: _pickDateOfBirth,
                  child: const Text('Choose date'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _bloodType,
            decoration: const InputDecoration(labelText: 'Blood type'),
            hint: const Text('Select blood type'),
            items: _bloodTypeOptions
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() => _bloodType = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          const SizedBox(height: 20),

          // New: patient address section.
          const Text(
            'Address',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _countryController,
            decoration: const InputDecoration(
              labelText: 'Country',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _governorateController,
            decoration: const InputDecoration(
              labelText: 'Governorate / State',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: 'City',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _avenueController,
            decoration: const InputDecoration(
              labelText: 'Avenue / Road',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _streetController,
            decoration: const InputDecoration(
              labelText: 'Street',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _postalCodeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Postal code',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _extraDetailsController,
            decoration: const InputDecoration(
              labelText: 'Extra details',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _emergencyNameController,
            decoration: const InputDecoration(
              labelText: 'Emergency contact name',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emergencyPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Emergency contact phone',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _insurancePlan,
            decoration: const InputDecoration(labelText: 'Insurance plan'),
            hint: const Text('Select insurance plan'),
            items: _insurancePlanOptions
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() => _insurancePlan = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _covidVaccineType,
            decoration: const InputDecoration(
              labelText: 'COVID vaccine type',
            ),
            hint: const Text('Select vaccine type'),
            items: _covidVaccineOptions
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() => _covidVaccineType = v),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _saveProfile,
            child: _saving
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Save profile'),
          ),
        ],
      ),
    );
  }
}
