import 'package:flutter/material.dart';

import '../services/patient_service.dart';
import '../services/patient_session_service.dart';
import '../utils/patient_access_context.dart';
import '../utils/section_screen_access.dart';
import 'patient_access_management_screen.dart';

// Viewing a patient's profile details, including demographics, contact information, and medical basics.
class PatientProfileViewScreen extends StatefulWidget {
  final String? patientId;
  final bool canEdit; // only true if permission == 'edit'
  final String? actorRole;

  const PatientProfileViewScreen({
    super.key,
    this.patientId,
    this.canEdit = false,
    this.actorRole,
  });

  @override
  State<PatientProfileViewScreen> createState() =>
      _PatientProfileViewScreenState();
}

class _PatientProfileViewScreenState extends State<PatientProfileViewScreen> {
  final PatientService _patientService = PatientService();

  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic>? _profile;
  late SectionScreenAccess _access;

  final _firstNameController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  final _insurancePlanController = TextEditingController();
  final _covidVaccineTypeController = TextEditingController();
  final _familyDoctorIdController = TextEditingController();

  String? _resolvePatientId() {
    return widget.patientId ?? PatientSessionService.instance.current?.patientId;
  }

  Map<String, dynamic> _routeContext(String patientId) {
    return PatientAccessContext(
      patientId: patientId,
      canEdit: _access.canEdit,
      isEmergencyOnly: _access.isEmergencyOnly,
      actorRole: widget.actorRole ?? 'unknown',
    ).toRouteArguments();
  }

  bool _isOwner() {
    return PatientSessionService.instance.current?.permission == 'owner';
  }

  // Opens the access management screen for the patient
  Future<void> _openManageAccess() async {
    final patientId = _resolvePatientId();
    if (patientId == null || patientId.isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientAccessManagementScreen(
          patientId: patientId,
          patientName: _fullName(),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    PatientAccessContext.instance.addListener(_rebuildOnPermissionChange);

    _access = SectionScreenAccess(
      widgetCanEdit: widget.canEdit,
      widgetIsEmergencyOnly: false,
    );

    _load();
  }

  // Reloads the screen data when the patient access permissions change
  void _rebuildOnPermissionChange() {
    if (!mounted) return;
    setState(() {
      _access = SectionScreenAccess(
        widgetCanEdit: widget.canEdit,
        widgetIsEmergencyOnly: false,
      );
    });
  }

  @override
  void dispose() {
    PatientAccessContext.instance.removeListener(_rebuildOnPermissionChange);
    _firstNameController.dispose();
    _familyNameController.dispose();
    _phoneController.dispose();
    _bloodTypeController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _insurancePlanController.dispose();
    _covidVaccineTypeController.dispose();
    _familyDoctorIdController.dispose();
    super.dispose();
  }

  String _textOf(Map<String, dynamic>? row, String key) {
    final value = row?[key]?.toString().trim();
    return value == null || value.isEmpty ? '' : value;
  }

  void _fillControllers(Map<String, dynamic>? profile) {
    _firstNameController.text = _textOf(profile, 'first_name');
    _familyNameController.text = _textOf(profile, 'family_name');
    _phoneController.text = _textOf(profile, 'phone');
    _bloodTypeController.text = _textOf(profile, 'blood_type');
    _emergencyContactNameController.text =
        _textOf(profile, 'emergency_contact_name');
    _emergencyContactPhoneController.text =
        _textOf(profile, 'emergency_contact_phone');
    _insurancePlanController.text = _textOf(profile, 'insurance_plan');
    _covidVaccineTypeController.text = _textOf(profile, 'covid_vaccine_type');
    _familyDoctorIdController.text = _textOf(profile, 'family_doctor_id');
  }

  // Fetches the patient's profile information from the server.
  Future<void> _load() async {
    final patientId = _resolvePatientId();
    if (patientId == null || patientId.isEmpty) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    try {
      final profile = await _patientService.fetchPatientProfileForGrantee(
        patientId,
      );

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _fillControllers(profile);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _label(String key) {
    final value = _profile?[key]?.toString().trim();
    return value == null || value.isEmpty ? 'Not set' : value;
  }

  String _fullName() {
    final first = _label('first_name');
    final last = _label('family_name');
    final combined = '$first $last'.trim();
    return combined == 'Not set Not set' ? 'Patient profile' : combined;
  }

  String _address() {
    final parts = [
      _profile?['address_country']?.toString() ?? '',
      _profile?['address_governorate']?.toString() ?? '',
      _profile?['address_city']?.toString() ?? '',
      _profile?['address_avenue']?.toString() ?? '',
      _profile?['address_street']?.toString() ?? '',
      _profile?['address_postal_code']?.toString() ?? '',
      _profile?['address_extra_details']?.toString() ?? '',
    ].where((e) => e.trim().isNotEmpty).toList();

    return parts.isEmpty ? 'Not set' : parts.join(' • ');
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // Saves the edited profile information to the server.
  Future<void> _saveEdits() async {
    final patientId = _resolvePatientId();
    if (patientId == null || patientId.isEmpty) return;

    setState(() => _saving = true);

    final updates = <String, dynamic>{
      'first_name': _firstNameController.text.trim(),
      'family_name': _familyNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'blood_type': _bloodTypeController.text.trim(),
      'emergency_contact_name': _emergencyContactNameController.text.trim(),
      'emergency_contact_phone':
      _emergencyContactPhoneController.text.trim(),
      'insurance_plan': _insurancePlanController.text.trim(),
      'covid_vaccine_type': _covidVaccineTypeController.text.trim(),
      'family_doctor_id': _familyDoctorIdController.text.trim(),
    }..removeWhere((key, value) => value == null || value.toString().isEmpty);

    try {
      final dynamic service = _patientService;

      // Use the profile-save RPC wrapper in your service layer.
      // If your method names/signatures differ slightly, align them here.
      await service.saveMyPatientProfile(
        patientId: patientId,
        updates: updates,
      );

      if (!mounted) return;
      await _load();

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  // Displays a dialog to edit the patient's profile details.
  Future<void> _openEditDialog() async {
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit patient profile'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First name',
                    ),
                  ),
                  TextField(
                    controller: _familyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Family name',
                    ),
                  ),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                    ),
                  ),
                  TextField(
                    controller: _bloodTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Blood type',
                    ),
                  ),
                  TextField(
                    controller: _emergencyContactNameController,
                    decoration: const InputDecoration(
                      labelText: 'Emergency contact name',
                    ),
                  ),
                  TextField(
                    controller: _emergencyContactPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Emergency contact phone',
                    ),
                  ),
                  TextField(
                    controller: _insurancePlanController,
                    decoration: const InputDecoration(
                      labelText: 'Insurance plan',
                    ),
                  ),
                  TextField(
                    controller: _covidVaccineTypeController,
                    decoration: const InputDecoration(
                      labelText: 'COVID vaccine type',
                    ),
                  ),
                  TextField(
                    controller: _familyDoctorIdController,
                    decoration: const InputDecoration(
                      labelText: 'Family doctor ID',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (shouldSave == true) {
      await _saveEdits();
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientId = _resolvePatientId();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient profile'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : patientId == null
          ? const Center(child: Text('No patient selected.'))
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fullName(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Patient ID: $patientId'),
                    Text('Sex: ${_label('sex')}'),
                    Text('Date of birth: ${_label('date_of_birth')}'),
                    Text('Age: ${_label('age_years')}'),
                    Text('Blood type: ${_label('blood_type')}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact details',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _row('Phone', _label('phone')),
                    _row(
                      'Emergency contact',
                      _label('emergency_contact_name'),
                    ),
                    _row(
                      'Emergency phone',
                      _label('emergency_contact_phone'),
                    ),
                    _row('Address', _address()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Medical basics',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _row('Insurance plan', _label('insurance_plan')),
                    _row(
                      'COVID vaccine',
                      _label('covid_vaccine_type'),
                    ),
                    _row(
                      'Family doctor',
                      _label('family_doctor_id'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Access',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _access.canEdit
                          ? 'You can edit this patient profile.'
                          : 'Read-only access.',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/medical_summary',
                            arguments: _routeContext(patientId),
                          ),
                          child: const Text('Open medical summary'),
                        ),
                        OutlinedButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/emergency',
                            arguments: _routeContext(patientId),
                          ),
                          child: const Text('Emergency view'),
                        ),
                        if (_isOwner())
                          FilledButton.tonalIcon(
                            onPressed: _openManageAccess,
                            icon: const Icon(
                              Icons.admin_panel_settings_outlined,
                            ),
                            label: const Text('Manage access'),
                          ),
                      ],
                    ),
                    if (_access.canEdit) ...[
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _saving ? null : _openEditDialog,
                        child: Text(
                          _saving ? 'Saving...' : 'Edit profile',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}