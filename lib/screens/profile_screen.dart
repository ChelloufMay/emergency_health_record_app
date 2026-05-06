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
  final _phoneController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _profileId;
  String? _patientId;
  String? _appUserId;

  String _sex = 'male';
  DateTime? _selectedDob;
  String? _bloodType;
  String? _insurancePlan;
  String? _covidVaccineType;

  static const List<String> _sexOptions = ['male', 'female'];
  static const List<String> _bloodTypeOptions = [
    'O-', 'O+', 'B-', 'B+', 'A-', 'A+', 'AB-', 'AB+',
  ];
  static const List<String> _insurancePlanOptions = ['NAM', 'CNSS', 'CNRPS'];
  static const List<String> _covidVaccineOptions = [
    'Pfizer-BioNTech (Comirnaty)',
    'Moderna (Spikevax / mRNA-1273)',
    'AstraZeneca/Oxford (Vaxzevria)',
    'Johnson & Johnson (Janssen)',
    'Sputnik V (Gam-COVID-Vac)',
    'CoronaVac (Sinovac)',
    'Sinopharm (BBIBP-CorV)',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final identity = await _patientService.resolveIdentity();
      _appUserId = identity?.appUserId ?? await _patientService.getAppUserId();

      if (_appUserId == null) {
        if (mounted) setState(() => _loading = false);
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

        final sexValue = row['sex']?.toString();
        _sex = sexValue == 'female' ? 'female' : 'male';

        final dobValue = row['date_of_birth']?.toString();
        if (dobValue != null && dobValue.isNotEmpty) {
          _selectedDob = DateTime.tryParse(dobValue);
        }

        final bloodTypeValue = row['blood_type']?.toString();
        if (_bloodTypeOptions.contains(bloodTypeValue)) {
          _bloodType = bloodTypeValue;
        }

        _phoneController.text = row['phone']?.toString() ?? '';
        _emergencyNameController.text =
            row['emergency_contact_name']?.toString() ?? '';
        _emergencyPhoneController.text =
            row['emergency_contact_phone']?.toString() ?? '';

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
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _selectedDob ?? DateTime(now.year - 30, now.month, now.day);
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
    // Refresh _appUserId in case sync hadn't finished when the screen loaded
    _appUserId ??= await _patientService.getAppUserId();

    if (_appUserId == null) {
      _showMessage(
        'Your account is not fully set up yet. Please sign out and sign in again.',
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final payload = {
        'user_id': _appUserId,
        'first_name': _firstNameController.text.trim(),
        'family_name': _familyNameController.text.trim(),
        'sex': _sex,
        'date_of_birth':
        _selectedDob == null ? null : _formatDate(_selectedDob!),
        'blood_type': _bloodType,
        'phone': _phoneController.text.trim(),
        'emergency_contact_name': _emergencyNameController.text.trim(),
        'emergency_contact_phone': _emergencyPhoneController.text.trim(),
        'insurance_plan': _insurancePlan,
        'covid_vaccine_type': _covidVaccineType,
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

      _showMessage('Profile saved');
    } on PostgrestException catch (e) {
      debugPrint('Profile save PostgrestException: ${e.message} code:${e.code}');
      if (e.code == '42501') {
        _showMessage(
          'Permission denied. Please sign out and sign in again, then try saving.',
          isError: true,
        );
      } else {
        _showMessage('Database error: ${e.message}', isError: true);
      }
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
    _firstNameController.dispose();
    _familyNameController.dispose();
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
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
          // ── name ──────────────────────────────────────────────
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

          // ── sex ───────────────────────────────────────────────
          DropdownButtonFormField<String>(
            initialValue: _sex,
            decoration: const InputDecoration(labelText: 'Sex'),
            items: _sexOptions
                .map((v) => DropdownMenuItem(
              value: v,
              child: Text(
                  v[0].toUpperCase() + v.substring(1)),
            ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _sex = v);
            },
          ),
          const SizedBox(height: 12),

          // ── date of birth ──────────────────────────────────────
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date of birth',
              border: OutlineInputBorder(),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDob == null
                      ? 'Select date'
                      : _formatDate(_selectedDob!),
                ),
                TextButton(
                  onPressed: _pickDateOfBirth,
                  child: const Text('Choose date'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── blood type ─────────────────────────────────────────
          DropdownButtonFormField<String>(
            initialValue: _bloodType,
            decoration:
            const InputDecoration(labelText: 'Blood type'),
            hint: const Text('Select blood type'),
            items: _bloodTypeOptions
                .map((v) =>
                DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() => _bloodType = v),
          ),
          const SizedBox(height: 12),

          // ── phone ──────────────────────────────────────────────
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          const SizedBox(height: 12),

          // ── emergency contact ──────────────────────────────────
          TextField(
            controller: _emergencyNameController,
            decoration: const InputDecoration(
                labelText: 'Emergency contact name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emergencyPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                labelText: 'Emergency contact phone'),
          ),
          const SizedBox(height: 12),

          // ── insurance ──────────────────────────────────────────
          DropdownButtonFormField<String>(
            initialValue: _insurancePlan,
            decoration:
            const InputDecoration(labelText: 'Insurance plan'),
            hint: const Text('Select insurance plan'),
            items: _insurancePlanOptions
                .map((v) =>
                DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() => _insurancePlan = v),
          ),
          const SizedBox(height: 12),

          // ── covid vaccine ──────────────────────────────────────
          DropdownButtonFormField<String>(
            initialValue: _covidVaccineType,
            decoration: const InputDecoration(
                labelText: 'COVID vaccine type'),
            hint: const Text('Select vaccine type'),
            items: _covidVaccineOptions
                .map((v) =>
                DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() => _covidVaccineType = v),
          ),
          const SizedBox(height: 20),

          // ── save button ────────────────────────────────────────
          ElevatedButton(
            onPressed: _saving ? null : _saveProfile,
            child: _saving
                ? const SizedBox(
              height: 20,
              width: 20,
              child:
              CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Save profile'),
          ),
        ],
      ),
    );
  }
}