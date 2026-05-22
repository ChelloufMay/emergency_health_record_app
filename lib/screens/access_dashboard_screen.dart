import 'package:flutter/material.dart';

import 'access_center_screen.dart';
import 'patient_access_management_screen.dart';

/// Backward-compatible alias: routes to the split access flow.
///
/// Owners land on management; grantees land on the access center (inbox tab).
class AccessDashboardScreen extends StatelessWidget {
  final String? patientId;
  final bool isOwnerContext;

  const AccessDashboardScreen({
    super.key,
    this.patientId,
    this.isOwnerContext = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOwnerContext ||
        (patientId != null && patientId!.trim().isNotEmpty)) {
      return PatientAccessManagementScreen(patientId: patientId);
    }

    return AccessCenterScreen(
      initialTab: 0,
      patientId: patientId,
      isOwnerContext: isOwnerContext,
    );
  }
}
