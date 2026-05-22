import 'package:flutter/material.dart';

import 'role_hub_screen.dart';

class ClinicianChoiceScreen extends StatelessWidget {
  const ClinicianChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHubScreen(
      title: 'Clinician hub',
      description:
          'Use this hub to reach your clinician dashboard, pending invites, '
          'profile, and clinician settings.',
      dashboardRoute: '/clinician_dashboard',
      accessInboxRoute: '/access_inbox',
      accessManagementRoute: '/access_center',
      profileRoute: '/clinician_profile',
      settingsRoute: '/clinician_settings',
    );
  }
}
