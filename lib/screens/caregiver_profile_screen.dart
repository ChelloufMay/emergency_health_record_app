import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/caregiver_profile_model.dart';
import '../services/caregiver_profile_service.dart';
import '../services/patient_service.dart';

class CaregiverProfileScreen extends StatefulWidget {
  const CaregiverProfileScreen({super.key});

  @override
  State<CaregiverProfileScreen> createState() => _CaregiverProfileScreenState();
}

class _CaregiverProfileScreenState extends State<CaregiverProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PatientService _patientService = PatientService();
  final CaregiverProfileService _service = CaregiverProfileService();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Address fields for the caregiver's own address.
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _governorateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _avenueController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _extraDetailsController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  String? _profileId;
  String? _addressId;
  String? _userId;

  String? _proximity;
  String? _attendance;
  bool? _canDrive;
  String _mobility = 'independent';

  static const List<String> _proximityOptions = [
    'cohabitant',
    'near',
    'far',
  ];

  static const List<String> _attendanceOptions = [
    'daily',
    'doctor_visits_only',
    'phone_checkups',
    'long_periods_between_visits',
  ];

  static const List<String> _mobilityOptions = [
    'independent',
    'cane',
    'wheelchair',
    'needs_help',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadAddress(String? addressId) async {
    if (addressId == null || addressId.isEmpty) return;

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
  }

  Future<void> _loadProfile() async {
    try {
      _userId = await _patientService.ensureAppUserId();
      if (_userId == null) return;

      final profile = await _service.ensureProfileShell();
      _profileId = profile.id;
      _addressId = profile.addressId;

      _fullNameController.text = profile.fullName;
      _relationshipController.text = profile.relationshipToPatient ?? '';
      _phoneController.text = profile.phone ?? '';
      _proximity = profile.proximity;
      _attendance = profile.attendance;
      _canDrive = profile.canDrive;
      _mobility = profile.mobility;

      await _loadAddress(_addressId);
    } catch (e) {
      debugPrint('Caregiver profile load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
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
    if (_userId == null) return;

    final fullName = _fullNameController.text.trim();
    if (fullName.isEmpty) {
      _showMessage('Full name is required.', isError: true);
      return;
    }

    if (_hasAnyAddressInput() && _countryController.text.trim().isEmpty) {
      _showMessage(
        'Country is required when entering address information.',
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final savedId = await _service.saveProfile(
        profile: CaregiverProfileModel(
          id: _profileId,
          userId: _userId!,
          fullName: fullName,
          relationshipToPatient: _relationshipController.text.trim().isEmpty
              ? null
              : _relationshipController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          addressId: _addressId,
          proximity: _proximity,
          attendance: _attendance,
          canDrive: _canDrive,
          mobility: _mobility,
        ),
        performedByUserId: _userId!,
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

      _profileId = savedId;
      await _loadProfile();

      _showMessage('Caregiver profile saved successfully.');
    } on PostgrestException catch (e) {
      _showMessage('Database error: ${e.message}', isError: true);
    } catch (e) {
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
    _fullNameController.dispose();
    _relationshipController.dispose();
    _phoneController.dispose();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My caregiver profile'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'This is your personal caregiver profile. It is separate from the patient record you may access.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _fullNameController,
            decoration: const InputDecoration(labelText: 'Full name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _relationshipController,
            decoration: const InputDecoration(
              labelText: 'Relationship to patient',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _proximity,
            decoration: const InputDecoration(labelText: 'Proximity'),
            hint: const Text('Select proximity'),
            items: _proximityOptions
                .map(
                  (v) => DropdownMenuItem(
                value: v,
                child: Text(v),
              ),
            )
                .toList(),
            onChanged: (v) => setState(() => _proximity = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _attendance,
            decoration: const InputDecoration(labelText: 'Attendance'),
            hint: const Text('Select attendance'),
            items: _attendanceOptions
                .map(
                  (v) => DropdownMenuItem(
                value: v,
                child: Text(v),
              ),
            )
                .toList(),
            onChanged: (v) => setState(() => _attendance = v),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Can drive'),
            value: _canDrive ?? false,
            onChanged: (v) => setState(() => _canDrive = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _mobility,
            decoration: const InputDecoration(labelText: 'Mobility'),
            items: _mobilityOptions
                .map(
                  (v) => DropdownMenuItem(
                value: v,
                child: Text(v),
              ),
            )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _mobility = v);
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Address',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _countryController,
            decoration: const InputDecoration(labelText: 'Country'),
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
            decoration: const InputDecoration(labelText: 'City'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _avenueController,
            decoration: const InputDecoration(labelText: 'Avenue / Road'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _streetController,
            decoration: const InputDecoration(labelText: 'Street'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _postalCodeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Postal code'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _extraDetailsController,
            decoration:
            const InputDecoration(labelText: 'Extra details'),
            maxLines: 2,
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
                : const Text('Save caregiver profile'),
          ),
        ],
      ),
    );
  }
}
