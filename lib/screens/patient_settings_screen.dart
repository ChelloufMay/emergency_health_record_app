import 'package:flutter/material.dart';

import 'role_settings_screen.dart';

class PatientSettingsScreen extends StatelessWidget {
  const PatientSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleSettingsScreen(
      title: 'Patient settings',
      description:
      'Manage your account, your profile, and your QR entry points from one place.',
      shortcuts: const [
        SettingsShortcut(
          icon: Icons.home_outlined,
          title: 'Home',
          subtitle: 'Return to your main patient view',
          routeName: '/home',
        ),
        SettingsShortcut(
          icon: Icons.person_outline,
          title: 'Profile',
          subtitle: 'Edit your personal profile data',
          routeName: '/profile',
        ),
        SettingsShortcut(
          icon: Icons.qr_code_2_outlined,
          title: 'QR code',
          subtitle: 'Open your emergency QR screen',
          routeName: '/qr',
        ),
      ],
    );
  }
}