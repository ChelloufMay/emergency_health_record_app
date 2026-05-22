import 'package:flutter/material.dart';

import 'role_settings_screen.dart';

class GuardianSettingsScreen extends StatelessWidget {
  const GuardianSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleSettingsScreen(
      title: 'Guardian settings',
      description:
      'Manage your guardian profile and the patient access views you rely on.',
      shortcuts: const [
        SettingsShortcut(
          icon: Icons.dashboard_outlined,
          title: 'Dashboard',
          subtitle: 'Open your guardian dashboard',
          routeName: '/guardian_dashboard',
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
          subtitle: 'Edit your guardian profile',
          routeName: '/guardian_profile',
        ),
      ],
    );
  }
}