import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class GuardianChoiceScreen extends StatelessWidget {
  const GuardianChoiceScreen({super.key});

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
      // NEW: guardian hub, same structure as caregiver/clinician hubs.
      appBar: AppBar(
        title: const Text('Guardian hub'),
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
                'Guardians can review the patients they are linked to based on DB permissions.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Guardian dashboard'),
              subtitle: const Text('Patients you can access'),
              onTap: () => _open(context, '/guardian_dashboard'),
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
              leading: const Icon(Icons.family_restroom_outlined),
              title: const Text('Guardian profile'),
              subtitle: const Text('Edit guardian profile data'),
              onTap: () => _open(context, '/guardian_profile'),
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