import 'package:flutter/material.dart';

import 'access_center_screen.dart';
import 'patient_access_management_screen.dart';

/// Backward-compatible alias: routes to the split access flow.
///
/// CHANGED:
/// - Only owner context should open patient access management.
/// - A non-empty patientId alone should not force the owner-management screen,
///   because caregivers can also carry a patientId when navigating around the app.
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
    if (isOwnerContext) {
      return PatientAccessManagementScreen(patientId: patientId);
    }

    return AccessCenterScreen(
      initialTab: 0,
      patientId: patientId,
      isOwnerContext: false,
    );
  }
}