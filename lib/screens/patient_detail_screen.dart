import 'dart:async';

import 'package:flutter/material.dart';
import '../services/patient_session_service.dart';
import '../utils/patient_access_context.dart';
import 'patient_access_management_screen.dart';

// View of a patient's record, accessible to caregivers, clinicians, or guardians based on their specific permissions and roles.
class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String permission;
  final String roleLabel;
  final String grantId;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.permission,
    required this.roleLabel,
    required this.grantId,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final PatientAccessContext _access = PatientAccessContext.instance;

  void _onAccessChanged() {
    if (!mounted) return;
    _syncSession();
    setState(() {});
  }

  // Synchronises the current patient session with the screen's state
  void _syncSession() {
    PatientSessionService.instance.setSession(
      patientId: widget.patientId,
      patientName: widget.patientName,
      permission: _access.permission.isNotEmpty
          ? _access.permission
          : widget.permission,
    );
  }

  @override
  void initState() {
    super.initState();

    _access.addListener(_onAccessChanged);
    _syncSession();
    unawaited(_access.bindPatient(widget.patientId));
  }

  @override
  void dispose() {
    _access.removeListener(_onAccessChanged);
    super.dispose();
  }

  // Navigates to a specific medical section of the patient's record
  void _open(BuildContext context, String routeName) {
    final ctx = PatientAccessContext(
      patientId: widget.patientId,
      canEdit: _access.canEdit,
      isEmergencyOnly: _access.isEmergencyOnly,
      actorRole: widget.roleLabel,
    );

    Navigator.pushNamed(
      context,
      routeName,
      arguments: ctx.toRouteArguments(),
    );
  }

  // Opens the access management screen for the patient.
  Future<void> _openManageAccess() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientAccessManagementScreen(
          patientId: widget.patientId,
          patientName: widget.patientName,
        ),
      ),
    );
  }

  Widget _sectionTile(
      BuildContext context,
      String title,
      IconData icon,
      String routeName,
      ) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        onTap: () => _open(context, routeName),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final canEdit = _access.canEdit;
    final canViewProfile = _access.canViewProfile;
    final canViewMedicalSummary = _access.canViewMedicalSummary;
    final canViewEmergency = _access.canViewEmergency;
    final canViewQr = _access.canViewQr;
    final isOwner = PatientSessionService.instance.current?.permission == 'owner';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patientName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Role: ${widget.roleLabel}\nPermission: ${_access.permission.isNotEmpty ? _access.permission : widget.permission}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (canViewProfile)
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Patient profile'),
                subtitle: const Text('Demographics, blood type, contacts'),
                onTap: () => _open(context, '/patient_profile_view'),
              ),
            ),
          if (canViewMedicalSummary)
            Card(
              child: ListTile(
                leading: const Icon(Icons.medical_information_outlined),
                title: const Text('Medical summary'),
                subtitle: const Text('Allergies, medications, conditions'),
                onTap: () => _open(context, '/medical_summary'),
              ),
            ),
          if (canEdit) ...[
            _sectionTile(
              context,
              'Allergies',
              Icons.warning_amber_outlined,
              '/allergies',
            ),
            _sectionTile(
              context,
              'Medications',
              Icons.medication_outlined,
              '/medications',
            ),
            _sectionTile(
              context,
              'Conditions',
              Icons.monitor_heart_outlined,
              '/conditions',
            ),
            _sectionTile(
              context,
              'Surgeries',
              Icons.healing_outlined,
              '/surgeries',
            ),
            _sectionTile(
              context,
              'Hospitalizations',
              Icons.local_hospital_outlined,
              '/hospitalizations',
            ),
            _sectionTile(
              context,
              'Vaccinations',
              Icons.vaccines_outlined,
              '/vaccinations',
            ),
            _sectionTile(
              context,
              'Lifestyle',
              Icons.self_improvement_outlined,
              '/lifestyle',
            ),
            _sectionTile(
              context,
              'Family history',
              Icons.family_restroom_outlined,
              '/family_history',
            ),
            _sectionTile(
              context,
              'Reproductive health',
              Icons.monitor_outlined,
              '/reproductive_health',
            ),
          ],
          if (canViewEmergency)
            Card(
              child: ListTile(
                leading: const Icon(Icons.emergency_outlined),
                title: const Text('Emergency view'),
                onTap: () => _open(context, '/emergency'),
              ),
            ),
          if (canViewQr)
            Card(
              child: ListTile(
                leading: const Icon(Icons.qr_code_outlined),
                title: const Text('Emergency QR'),
                onTap: () => _open(context, '/qr'),
              ),
            ),
          if (isOwner)
            Card(
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Manage access'),
                subtitle: const Text(
                  'Invite caregivers, guardians, or clinicians',
                ),
                onTap: _openManageAccess,
              ),
            ),

          if (_access.permission == 'none' || _access.isExpired)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Access to this patient is no longer active.',
                ),
              ),
            ),
        ],
      ),
    );
  }
}