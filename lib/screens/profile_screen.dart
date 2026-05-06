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
  final SupabaseClient _supabase = Supabase.instance.client;
  final PatientService _patientService = PatientService();
  final AuditService _audit = AuditService();

  final TextEditingController _legalIdController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _familyNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emergencyNameController = TextEditingController();
  final TextEditingController _emergencyPhoneController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  String? _profileId;
  String? _appUserId;

  String _sex = 'unknown';
  DateTime? _selectedDob;
  String? _bloodType;
  String? _insurancePlan;
  String? _covidVaccineType;

  static const List<String> _sexOptions = ['male', 'female'];
  static const List<String> _bloodTypeOptions = [
    'O-', 'O+', 'B-', 'B+', 'A-', 'A+', 'AB-', 'AB+',
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

  Future<void> _loadProfile() async {
    try {
      _appUserId = await _patientService.ensureAppUserId();

      if (_appUserId == null) {
        return;
      }

      final row = await _supabase
          .from('patient_profiles')
          .select()
          .eq('user_id', _appUserId!)
          .maybeSingle();

      if (row != null) {
        _profileId = row['id']?.toString();

        _legalIdController.text = row['legal_id']?.toString() ?? '';
        _firstNameController.text = row['first_name']?.toString() ?? '';
        _familyNameController.text = row['family_name']?.toString() ?? '';
        _phoneController.text = row['phone']?.toString() ?? '';
        _emergencyNameController.text =
            row['emergency_contact_name']?.toString() ?? '';
        _emergencyPhoneController.text =
            row['emergency_contact_phone']?.toString() ?? '';

        final sexValue = row['sex']?.toString();
        if (sexValue == 'male' || sexValue == 'female') {
          _sex = sexValue!;
        } else {
          _sex = 'unknown';
        }

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
      }
    } catch (e) {
      debugPrint('_loadProfile error: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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

    setState(() => _saving = true);

    try {
      _appUserId = await _patientService.ensureAppUserId(
        fullName: '$firstName $familyName',
        phone: _phoneController.text.trim(),
      );

      if (_appUserId == null) {
        _showMessage(
          'No linked app user row was found. Please sign out and sign in again.',
          isError: true,
        );
        return;
      }

      final payload = <String, dynamic>{
        'user_id': _appUserId,
        'legal_id': _legalIdController.text.trim().isEmpty
            ? null
            : _legalIdController.text.trim(),
        'first_name': firstName,
        'family_name': familyName,
        'sex': _sex == 'male' || _sex == 'female' ? _sex : 'unknown',
        'date_of_birth': _selectedDob == null ? null : _formatDate(_selectedDob!),
        'blood_type': _bloodType,
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'emergency_contact_name': _emergencyNameController.text.trim().isEmpty
            ? null
            : _emergencyNameController.text.trim(),
        'emergency_contact_phone': _emergencyPhoneController.text.trim().isEmpty
            ? null
            : _emergencyPhoneController.text.trim(),
        'insurance_plan': _insurancePlan,
        'covid_vaccine_type': _covidVaccineType,
      };

      // One path for both create and update
      final saved = await _supabase
          .from('patient_profiles')
          .upsert(payload, onConflict: 'user_id')
          .select('id')
          .single();

      _profileId = saved['id']?.toString();

      await _audit.log(
        patientId: _profileId!,
        performedByUserId: _appUserId!,
        action: 'update',
        entityType: 'patient_profiles',
        entityId: _profileId,
        fieldName: 'first_name',
        newValue: '$firstName $familyName',
      );

      _showMessage('Profile saved successfully.');
    } on PostgrestException catch (e) {
      debugPrint('Profile save PostgrestException: ${e.message} code:${e.code}');
      _showMessage(
        e.code == '42501'
            ? 'Permission denied. The linked app user row is missing or not matching.'
            : 'Database error: ${e.message}',
        isError: true,
      );
    } catch (e) {
      debugPrint('Profile save error: $e');
      _showMessage('Unexpected error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
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
              if (v != null) {
                setState(() => _sex = v);
              }
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
          const SizedBox(height: 12),

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
            decoration:
            const InputDecoration(labelText: 'Insurance plan'),
            hint: const Text('Select insurance plan'),
            items: _insurancePlanOptions
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() => _insurancePlan = v),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            initialValue: _covidVaccineType,
            decoration:
            const InputDecoration(labelText: 'COVID vaccine type'),
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