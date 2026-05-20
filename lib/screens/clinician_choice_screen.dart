import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class ClinicianChoiceScreen extends StatelessWidget {
  const ClinicianChoiceScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await AuthService().signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _open(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // NEW: clinician hub, same structure as caregiver/guardian hubs.
      appBar: AppBar(
        title: const Text('Clinician hub'),
        actions: [
          IconButton(
            onPressed: () => _open(context, '/settings'),
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
                'Clinicians can review the patients they are linked to and only edit what the DB permission allows.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Clinician dashboard'),
              subtitle: const Text('Patients you can access'),
              onTap: () => _open(context, '/clinician_dashboard'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: const Text('Invites & access'),
              subtitle: const Text('Accept or reject pending invites'),
              onTap: () => _open(context, '/access_dashboard'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_hospital_outlined),
              title: const Text('Clinician profile'),
              subtitle: const Text('Edit clinician profile data'),
              onTap: () => _open(context, '/clinician_profile'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              subtitle: const Text('Password, recovery, sign out'),
              onTap: () => _open(context, '/settings'),
            ),
          ),
        ],
      ),
    );
  }
}