import 'package:flutter/material.dart';

import 'role_hub_screen.dart';

// Provides navigation options for the Caregiver role.
class CaregiverChoiceScreen extends StatelessWidget {
  // Creates a new CaregiverChoiceScreen instance.
  const CaregiverChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHubScreen(
      title: 'Caregiver hub',
      description:
          'Use this hub to reach your caregiver dashboard, pending invites, '
          'profile, and caregiver settings.',
      dashboardRoute: '/caregiver_dashboard',
      accessInboxRoute: '/access_inbox',
      accessManagementRoute: '/access_center',
      profileRoute: '/caregiver_profile',
      settingsRoute: '/caregiver_settings',
    );
  }
}
