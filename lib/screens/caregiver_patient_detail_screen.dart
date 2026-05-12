import 'package:flutter/material.dart';

import '../models/caregiver_permission_model.dart';

class CaregiverPatientDetailScreen extends StatelessWidget {
  final String patientId;
  final Map<String, dynamic>? summary;
  final List<CaregiverPermissionModel> permissions;

  const CaregiverPatientDetailScreen({
    super.key,
    required this.patientId,
    required this.summary,
    required this.permissions,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool _isActive(CaregiverPermissionModel permission) {
    if (permission.status != 'active') return false;
    if (permission.expiresAt == null) return true;
    return permission.expiresAt!.isAfter(DateTime.now());
  }

  String _permissionLabel(CaregiverPermissionModel permission) {
    if (permission.permission == 'emergency_only') {
      // Important note:
      // In the current database helper, emergency_only is still treated like read access.
      // If you want it to behave differently, the SQL helper / policies must be tightened.
      return 'Emergency only';
    }
    return permission.permission[0].toUpperCase() + permission.permission.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final first = summary?['first_name']?.toString().trim() ?? '';
    final family = summary?['family_name']?.toString().trim() ?? '';
    final fullName = '$first $family'.trim().isEmpty ? 'Patient details' : '$first $family';

    final activePermissions = permissions.where(_isActive).toList();
    final inactivePermissions = permissions.where((p) => !_isActive(p)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(fullName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                [
                  'Patient ID: $patientId',
                  if (summary != null) 'Age: ${summary!['age_years'] ?? '-'}',
                  if (summary != null) 'Blood type: ${summary!['blood_type'] ?? '-'}',
                  if (summary != null) 'City: ${summary!['address_city'] ?? '-'}',
                  if (summary != null)
                    'Emergency contact: ${summary!['emergency_contact_name'] ?? '-'}',
                  if (summary != null)
                    'Emergency phone: ${summary!['emergency_contact_phone'] ?? '-'}',
                ].join('\n'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your access on this patient',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (permissions.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No permission rows were found for this patient.'),
              ),
            )
          else
            ...permissions.map((permission) {
              final active = _isActive(permission);
              return Card(
                child: ListTile(
                  title: Text(
                    _permissionLabel(permission),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    [
                      'Status: ${permission.status}',
                      'State: ${active ? 'active' : 'inactive'}',
                      'Granted at: ${_formatDate(permission.grantedAt)}',
                      'Expires at: ${_formatDate(permission.expiresAt)}',
                      if (permission.notes != null && permission.notes!.isNotEmpty)
                        'Notes: ${permission.notes}',
                    ].join('\n'),
                  ),
                  isThreeLine: true,
                ),
              );
            }),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Important: the current database keeps the core patient profile owner-only. '
                    'Caregivers can open the shared patient record and the allowed medical data, '
                    'but editing the core patient profile itself needs a database policy change.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Active permission rows',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (activePermissions.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No active permission rows for this patient.'),
              ),
            )
          else
            ...activePermissions.map(
                  (permission) => Card(
                child: ListTile(
                  title: Text(
                    _permissionLabel(permission),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    [
                      'Granted at: ${_formatDate(permission.grantedAt)}',
                      'Expires at: ${_formatDate(permission.expiresAt)}',
                    ].join('\n'),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Inactive rows',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (inactivePermissions.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No revoked or expired rows for this patient.'),
              ),
            )
          else
            ...inactivePermissions.map(
                  (permission) => Card(
                child: ListTile(
                  title: Text(
                    _permissionLabel(permission),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    [
                      'Status: ${permission.status}',
                      'Expires at: ${_formatDate(permission.expiresAt)}',
                    ].join('\n'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
