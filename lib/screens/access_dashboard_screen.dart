import 'package:flutter/material.dart';

import 'access_center_screen.dart';
import 'patient_access_management_screen.dart';

// Backward-compatible alias: routes to the split access flow.

// Only owner can open patient access management.
// A non empty patientId alone should not force the owner management screen, cus 'other role' can also carry a patientId when navigating around the app.
// A wrapper screen that routes to either the owner's access management or the user's access center based on the context.
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