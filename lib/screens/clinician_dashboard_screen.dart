import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class ClinicianDashboardScreen extends StatelessWidget {
  const ClinicianDashboardScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await AuthService().signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // NEW FILE: clinician gets a separate dashboard instead of the caregiver one.
      appBar: AppBar(
        title: const Text('Clinician dashboard'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
          IconButton(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Clinician access depends on the DB grant attached to each patient. '
                    'Open the access dashboard to see who you can review and whether the access is read-only or editable.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: const Text('Invites & access'),
              subtitle: const Text('Accept, reject, or review shared access'),
              onTap: () => Navigator.pushNamed(context, '/access_dashboard'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_hospital_outlined),
              title: const Text('Clinician profile'),
              subtitle: const Text('Edit your clinician profile'),
              onTap: () => Navigator.pushNamed(context, '/clinician_profile'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              subtitle: const Text('Password, recovery, sign out'),
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
          ),
        ],
      ),
    );
  }
}