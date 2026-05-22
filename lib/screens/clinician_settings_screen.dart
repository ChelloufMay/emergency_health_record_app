import 'package:flutter/material.dart';

import 'role_settings_screen.dart';

class ClinicianSettingsScreen extends StatelessWidget {
  const ClinicianSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleSettingsScreen(
      title: 'Clinician settings',
      description:
      'Manage your clinician profile, access workflow, and account actions.',
      shortcuts: const [
        SettingsShortcut(
          icon: Icons.dashboard_outlined,
          title: 'Dashboard',
          subtitle: 'Open your clinician dashboard',
          routeName: '/clinician_dashboard',
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
          subtitle: 'Edit your clinician profile',
          routeName: '/clinician_profile',
        ),
      ],
    );
  }
}