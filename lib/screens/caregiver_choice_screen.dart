import 'package:flutter/material.dart';
import 'role_hub_screen.dart';

class CaregiverChoiceScreen extends StatelessWidget {
  const CaregiverChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHubScreen(
      title: 'Caregiver hub',
      description:
      'Use this hub to reach your caregiver dashboard, pending invites, profile, and settings.',
      dashboardRoute: '/caregiver_dashboard',
      accessRoute: '/access_dashboard',
      profileRoute: '/caregiver_profile',
      settingsRoute: '/settings',
    );
  }
}