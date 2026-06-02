import 'package:flutter/material.dart';

import 'role_settings_screen.dart';

class GuardianSettingsScreen extends StatelessWidget {
  const GuardianSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleSettingsScreen(
      title: 'Guardian settings',
      profileRoute: '/guardian_profile',
      showMedicalSummary: false,
      showQr: false,
      showCaregivers: false,
      showAuditLog: true,
      showDeleteAccount: true,
    );
  }
}
