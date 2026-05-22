import 'package:flutter/material.dart';

import '../models/access_grant_view_model.dart';

/// Reusable active grant row for patient-owner access management.
class AccessGrantCard extends StatelessWidget {
  final AccessGrantViewModel grant;
  final bool canManage;
  final VoidCallback? onEditPermission;
  final VoidCallback? onRevoke;

  const AccessGrantCard({
    super.key,
    required this.grant,
    this.canManage = true,
    this.onEditPermission,
    this.onRevoke,
  });

  String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'caregiver':
        return 'Caregiver';
      case 'guardian':
        return 'Guardian';
      case 'clinician':
        return 'Clinician';
      default:
        return role;
    }
  }

  String _permissionLabel(String permission) {
    switch (permission.toLowerCase()) {
      case 'read':
        return 'Read-only';
      case 'edit':
        return 'Read and edit';
      case 'emergency_only':
        return 'Emergency only';
      default:
        return permission;
    }
  }

  IconData _permissionIcon() {
    switch (grant.permission.toLowerCase()) {
      case 'edit':
        return Icons.edit_outlined;
      case 'emergency_only':
        return Icons.warning_amber_outlined;
      default:
        return Icons.visibility_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final expiry = grant.expiresAt == null
        ? 'Never'
        : grant.expiresAt!.toIso8601String().split('T').first;

    return Card(
      child: ListTile(
        leading: Icon(_permissionIcon()),
        title: Text('${_roleLabel(grant.granteeRole)} • ${grant.granteeLabel}'),
        subtitle: Text(
          'Permission: ${_permissionLabel(grant.permission)}\n'
          'Status: ${grant.status}\n'
          'Expires: $expiry',
        ),
        isThreeLine: true,
        trailing: canManage
            ? Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    onPressed:
                        grant.grantId.isEmpty ? null : onEditPermission,
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Change permission',
                  ),
                  IconButton(
                    onPressed: grant.grantId.isEmpty ? null : onRevoke,
                    icon: const Icon(Icons.block),
                    tooltip: 'Revoke access',
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
