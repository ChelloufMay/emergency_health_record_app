import 'package:flutter/material.dart';

import '../services/patient_session_service.dart';
import '../utils/patient_access_context.dart';

class PatientDetailScreen extends StatelessWidget {
  final String patientId;
  final String patientName;
  final String permission;
  final String roleLabel;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.permission,
    required this.roleLabel,
  });

  bool get canEdit => permission == 'edit' || permission == 'owner';
  bool get isEmergencyOnly => permission == 'emergency_only';

  void _open(BuildContext context, String routeName) {
    final ctx = PatientAccessContext(
      patientId: patientId,
      canEdit: canEdit,
      isEmergencyOnly: isEmergencyOnly,
      actorRole: roleLabel,
    );
    Navigator.pushNamed(
      context,
      routeName,
      arguments: ctx.toRouteArguments(),
    );
  }

  @override
  Widget build(BuildContext context) {
    PatientSessionService.instance.setSession(
      patientId: patientId,
      patientName: patientName,
      permission: permission,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(patientName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Role: $roleLabel\nPermission: $permission',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.medical_information_outlined),
              title: const Text('Medical summary'),
              subtitle: const Text('Allergies, medications, conditions'),
              onTap: () => _open(context, '/medical_summary'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              subtitle: const Text('View patient profile and address'),
              onTap: () => _open(context, '/profile'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(
                canEdit ? Icons.edit_outlined : Icons.visibility_outlined,
              ),
              title: Text(canEdit ? 'Edit allowed sections' : 'Read-only access'),
              subtitle: Text(
                isEmergencyOnly
                    ? 'Emergency-only: open emergency views'
                    : canEdit
                    ? 'Open section screens and edit permitted fields'
                    : 'Open section screens in read-only mode',
              ),
              onTap: isEmergencyOnly
                  ? () => _open(context, '/emergency')
                  : (canEdit ? () => _open(context, '/medical_summary') : null),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.qr_code_outlined),
              title: const Text('Emergency QR'),
              subtitle: const Text('View the emergency card'),
              onTap: () => _open(context, '/qr'),
            ),
          ),
          if (isEmergencyOnly)
            Card(
              child: ListTile(
                leading: const Icon(Icons.emergency_outlined),
                title: const Text('Emergency view'),
                onTap: () => _open(context, '/emergency'),
              ),
            ),
        ],
      ),
    );
  }
}
