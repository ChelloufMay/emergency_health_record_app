import 'package:flutter/material.dart';

import 'role_hub_screen.dart';

class GuardianChoiceScreen extends StatelessWidget {
  const GuardianChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHubScreen(
      title: 'Guardian hub',
      description:
          'Use this hub to reach your guardian dashboard, pending invites, '
          'profile, and guardian settings.',
      dashboardRoute: '/guardian_dashboard',
      accessInboxRoute: '/access_inbox',
      accessManagementRoute: '/access_center',
      profileRoute: '/guardian_profile',
      settingsRoute: '/guardian_settings',
    );
  }
}
