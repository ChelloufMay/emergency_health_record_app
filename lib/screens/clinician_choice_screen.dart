import 'package:flutter/material.dart';
import 'role_hub_screen.dart';

class ClinicianChoiceScreen extends StatelessWidget {
  const ClinicianChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleHubScreen(
      title: 'Clinician hub',
      description:
      'Use this hub to reach your clinician dashboard, pending invites, profile, and settings.',
      dashboardRoute: '/clinician_dashboard',
      accessRoute: '/access_dashboard',
      profileRoute: '/clinician_profile',
      settingsRoute: '/settings',
    );
  }
}