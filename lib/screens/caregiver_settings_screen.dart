import 'package:flutter/material.dart';

import 'role_settings_screen.dart';

class CaregiverSettingsScreen extends StatelessWidget {
  const CaregiverSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleSettingsScreen(
      title: 'Caregiver settings',
      description:
      'Manage your caregiver profile and the places you use to support patients.',
      shortcuts: const [
        SettingsShortcut(
          icon: Icons.dashboard_outlined,
          title: 'Dashboard',
          subtitle: 'Open your caregiver dashboard',
          routeName: '/caregiver_dashboard',
        ),
        SettingsShortcut(
          icon: Icons.medical_information_outlined,
          title: 'Access dashboard',
          subtitle: 'Review invites, grants, and patient access',
          routeName: '/access_dashboard',
        ),
        SettingsShortcut(
          icon: Icons.badge_outlined,
          title: 'Profile',
          subtitle: 'Edit your caregiver profile',
          routeName: '/caregiver_profile',
        ),
      ],
    );
  }
}