import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;

  // ------------------------------- personal info -------------------------------
  final _firstNameController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _legalIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  String? _selectedSex;
  DateTime? _selectedDOB;

  // ------------------------------- address -------------------------------
  final _countryController = TextEditingController();
  final _governorateController = TextEditingController();
  final _cityController = TextEditingController();
  final _avenueController = TextEditingController();
  final _streetController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _extraDetailsController = TextEditingController();

  // ------------------------------- medical extras -------------------------------
  final _insurancePlanController = TextEditingController();

  // null means not vaccinated or not recorded
  String? _selectedCovidVaccine;

  // the seven vaccines available in Tunisia
  static const List<String> _covidVaccines = [
    'Pfizer-BioNTech (Comirnaty)',
    'Moderna (Spikevax)',
    'AstraZeneca/Oxford (Vaxzevria)',
    'Johnson & Johnson (Janssen)',
    'Sinovac (CoronaVac)',
    'Sputnik V',
    'Sinopharm',
  ];

  // ------------------------------- emergency contact -------------------------------
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();

  // ------------------------------- state -------------------------------
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  String? _appUserId;
  String? _existingAddressId;
  bool _profileExists = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final authId = _supabase.auth.currentUser?.id;

      if (authId == null) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
        }
        return;
      }

      final userRow = await _supabase
          .from('users')
          .select('id')
          .eq('auth_user_id', authId)
          .maybeSingle();

      if (userRow == null) {
        setState(() =>
        _errorMessage = 'User not found. Please log out and register again.');
        return;
      }

      _appUserId = userRow['id'] as String;

      final profileRow = await _supabase
          .from('patient_profiles')
          .select()
          .eq('user_id', _appUserId!)
          .maybeSingle();

      if (profileRow != null) {
        _profileExists = true;

        // ------------------------------- fill personal info -------------------------------
        _firstNameController.text = profileRow['first_name'] ?? '';
        _familyNameController.text = profileRow['family_name'] ?? '';
        _legalIdController.text = profileRow['legal_id'] ?? '';
        _phoneController.text = profileRow['phone'] ?? '';
        _bloodTypeController.text = profileRow['blood_type'] ?? '';

        // if the stored value is 'unknown' or null, leave the dropdown empty
        final storedSex = profileRow['sex'] as String?;
        _selectedSex = (storedSex == 'unknown' || storedSex == null)
            ? null
            : storedSex;

        final dobValue = profileRow['date_of_birth'];
        if (dobValue != null) {
          _selectedDOB = DateTime.tryParse(dobValue.toString());
        }

        // ------------------------------- fill medical extras -------------------------------
        _insurancePlanController.text = profileRow['insurance_plan'] ?? '';

        // only set the dropdown if the stored value matches one of our options
        final storedVaccine = profileRow['covid_vaccine_type'] as String?;
        if (storedVaccine != null && _covidVaccines.contains(storedVaccine)) {
          _selectedCovidVaccine = storedVaccine;
        }

        // ------------------------------- fill emergency contact -------------------------------
        _emergencyContactNameController.text =
            profileRow['emergency_contact_name'] ?? '';
        _emergencyContactPhoneController.text =
            profileRow['emergency_contact_phone'] ?? '';

        // ------------------------------- fill address if linked -------------------------------
        final addressId = profileRow['address_id'] as String?;
        if (addressId != null) {
          _existingAddressId = addressId;
          final addressRow = await _supabase
              .from('addresses')
              .select()
              .eq('id', addressId)
              .maybeSingle();

          if (addressRow != null) {
            _countryController.text = addressRow['country'] ?? '';
            _governorateController.text = addressRow['governorate'] ?? '';
            _cityController.text = addressRow['city'] ?? '';
            _avenueController.text = addressRow['avenue'] ?? '';
            _streetController.text = addressRow['street'] ?? '';
            _postalCodeController.text = addressRow['postal_code'] ?? '';
            _extraDetailsController.text = addressRow['extra_details'] ?? '';
          }
        }
      }
    } on PostgrestException catch (e) {
      setState(() => _errorMessage = 'Failed to load profile: ${e.message}');
    } catch (_) {
      setState(() => _errorMessage = 'Unexpected error while loading profile.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDOB ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDOB = picked);
  }

  bool _hasAddressData() {
    return _countryController.text.trim().isNotEmpty ||
        _governorateController.text.trim().isNotEmpty ||
        _cityController.text.trim().isNotEmpty ||
        _streetController.text.trim().isNotEmpty;
  }

  Future<String?> _saveAddress() async {
    if (!_hasAddressData()) return _existingAddressId;

    if (_countryController.text.trim().isEmpty) {
      throw Exception('Country is required when filling in an address.');
    }

    final addressData = {
      'country': _countryController.text.trim(),
      'governorate': _governorateController.text.trim().isEmpty
          ? null
          : _governorateController.text.trim(),
      'city': _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      'avenue': _avenueController.text.trim().isEmpty
          ? null
          : _avenueController.text.trim(),
      'street': _streetController.text.trim().isEmpty
          ? null
          : _streetController.text.trim(),
      'postal_code': _postalCodeController.text.trim().isEmpty
          ? null
          : _postalCodeController.text.trim(),
      'extra_details': _extraDetailsController.text.trim().isEmpty
          ? null
          : _extraDetailsController.text.trim(),
    };

    if (_existingAddressId != null) {
      await _supabase
          .from('addresses')
          .update(addressData)
          .eq('id', _existingAddressId!);
      return _existingAddressId;
    } else {
      final result = await _supabase
          .from('addresses')
          .insert(addressData)
          .select('id')
          .single();
      return result['id'] as String;
    }
  }

  Future<void> _saveProfile() async {
    if (_firstNameController.text.trim().isEmpty ||
        _familyNameController.text.trim().isEmpty) {
      setState(
              () => _errorMessage = 'First name and family name are required.');
      return;
    }

    if (_appUserId == null) {
      setState(() => _errorMessage =
      'User session not found. Please log out and back in.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      String? addressId;
      try {
        addressId = await _saveAddress();
        if (addressId != null) _existingAddressId = addressId;
      } catch (e) {
        setState(() =>
        _errorMessage = e.toString().replaceAll('Exception: ', ''));
        return;
      }

      final profileData = {
        'user_id': _appUserId,
        'first_name': _firstNameController.text.trim(),
        'family_name': _familyNameController.text.trim(),
        'legal_id': _legalIdController.text.trim().isEmpty
            ? null
            : _legalIdController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'blood_type': _bloodTypeController.text.trim().isEmpty
            ? null
            : _bloodTypeController.text.trim(),
        // if the user didn't pick a sex, store 'unknown' in the DB
        'sex': _selectedSex ?? 'unknown',
        'date_of_birth': _selectedDOB?.toIso8601String().split('T').first,
        'address_id': addressId,
        'insurance_plan': _insurancePlanController.text.trim().isEmpty
            ? null
            : _insurancePlanController.text.trim(),
        // null if nothing was selected in the dropdown
        'covid_vaccine_type': _selectedCovidVaccine,
        'emergency_contact_name':
        _emergencyContactNameController.text.trim().isEmpty
            ? null
            : _emergencyContactNameController.text.trim(),
        'emergency_contact_phone':
        _emergencyContactPhoneController.text.trim().isEmpty
            ? null
            : _emergencyContactPhoneController.text.trim(),
      };

      if (_profileExists) {
        await _supabase
            .from('patient_profiles')
            .update(profileData)
            .eq('user_id', _appUserId!);
      } else {
        await _supabase.from('patient_profiles').insert(profileData);
        _profileExists = true;
      }

      setState(() => _successMessage = 'Profile saved successfully.');
    } on PostgrestException catch (e) {
      setState(() => _errorMessage = 'Database error: ${e.message}');
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong while saving.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _familyNameController.dispose();
    _legalIdController.dispose();
    _phoneController.dispose();
    _bloodTypeController.dispose();
    _countryController.dispose();
    _governorateController.dispose();
    _cityController.dispose();
    _avenueController.dispose();
    _streetController.dispose();
    _postalCodeController.dispose();
    _extraDetailsController.dispose();
    _insurancePlanController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    super.dispose();
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ------------------------------- Personal info -------------------------------
            _sectionTitle('Personal Information'),

            TextField(
              controller: _firstNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'First Name *'),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _familyNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Family Name *'),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _legalIdController,
              decoration: const InputDecoration(
                labelText: 'Legal ID',
                hintText: 'National ID or passport number',
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            const SizedBox(height: 16),

            // sex is medically relevant so we only show the two real options. the DB stores 'unknown' if the user never picks one.
            DropdownButtonFormField<String>(
              value: _selectedSex,
              decoration: const InputDecoration(labelText: 'Sex'),
              hint: const Text('Select'),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedSex = value);
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDOB == null
                        ? 'Date of Birth: not set'
                        : 'Date of Birth: ${_selectedDOB!.toIso8601String().split('T').first}',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                TextButton(
                  onPressed: _pickDateOfBirth,
                  child: const Text('Pick date'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _bloodTypeController,
              decoration: const InputDecoration(
                labelText: 'Blood Type',
                hintText: 'e.g. O+, A-, B+',
              ),
            ),
            const Divider(height: 40),

            // ------------------------------- Address -------------------------------
            _sectionTitle('Address'),

            TextField(
              controller: _countryController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Country',
                hintText: 'Required if filling address',
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _governorateController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Governorate'),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _cityController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _avenueController,
              decoration: const InputDecoration(labelText: 'Avenue'),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _streetController,
              decoration: const InputDecoration(labelText: 'Street'),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _postalCodeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Postal Code'),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _extraDetailsController,
              decoration: const InputDecoration(
                labelText: 'Extra Details',
                hintText: 'Floor, apartment, landmark...',
              ),
            ),
            const Divider(height: 40),

            // ------------------------------- Medical extras -------------------------------
            _sectionTitle('Medical Information'),

            TextField(
              controller: _insurancePlanController,
              decoration: const InputDecoration(
                labelText: 'Insurance Plan',
                hintText: 'e.g. CNAM, CNSS, CNRPS',
              ),
            ),
            const SizedBox(height: 16),

            // dropdown listing the vaccines distributed in Tunisia. leaving it empty means not vaccinated or not recorded.
            DropdownButtonFormField<String>(
              value: _selectedCovidVaccine,
              decoration: const InputDecoration(labelText: 'COVID-19 Vaccine'),
              hint: const Text('Not vaccinated / Not recorded'),
              isExpanded: true,
              items: _covidVaccines.map((vaccine) {
                return DropdownMenuItem(
                  value: vaccine,
                  child: Text(vaccine),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCovidVaccine = value);
              },
            ),
            const Divider(height: 40),

            // ------------------------------- Emergency contact -------------------------------
            _sectionTitle('Emergency Contact'),

            TextField(
              controller: _emergencyContactNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Contact Name'),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _emergencyContactPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Contact Phone'),
            ),
            const SizedBox(height: 32),

            // ------------------------------- Feedback -------------------------------
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],

            if (_successMessage != null) ...[
              Text(
                _successMessage!,
                style: const TextStyle(color: Colors.green),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],

            // ------------------------------- Save -------------------------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Save Profile'),
              ),
            ),

            const SizedBox(height: 12),
            const Text(
              'Family doctor details can be added from the medical summary screen.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}