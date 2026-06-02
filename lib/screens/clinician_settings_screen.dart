import 'package:flutter/material.dart';

import 'role_settings_screen.dart';

class ClinicianSettingsScreen extends StatelessWidget {
  const ClinicianSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleSettingsScreen(
      title: 'Clinician settings',
      profileRoute: '/clinician_profile',
      showMedicalSummary: false,
      showQr: false,
      showCaregivers: false,
      showAuditLog: true,
      showDeleteAccount: true,
    );
  }
}
