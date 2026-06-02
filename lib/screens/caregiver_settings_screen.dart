import 'package:flutter/material.dart';

import 'role_settings_screen.dart';

// Managing settings specific to the Caregiver role.
class CaregiverSettingsScreen extends StatelessWidget {
  // Creates a new CaregiverSettingsScreen instance.
  const CaregiverSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleSettingsScreen(
      title: 'Caregiver settings',
      profileRoute: '/caregiver_profile',
      showMedicalSummary: false,
      showQr: false,
      showCaregivers: false,
      showAuditLog: true,
      showDeleteAccount: true,
    );
  }
}
