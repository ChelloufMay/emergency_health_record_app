import 'package:flutter/material.dart';

import 'role_settings_screen.dart';

class CaregiverSettingsScreen extends StatelessWidget {
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
      showDeleteAccount: false,
    );
  }
}