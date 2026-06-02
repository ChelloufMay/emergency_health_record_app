import 'package:flutter/material.dart';

import 'role_settings_screen.dart';

class PatientSettingsScreen extends StatelessWidget {
  const PatientSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleSettingsScreen(
      title: 'Settings',
      profileRoute: '/profile',
      showMedicalSummary: true,
      showQr: true,
      showCaregivers: true,
      showAuditLog: true,
      showDeleteAccount: true,
    );
  }
}
