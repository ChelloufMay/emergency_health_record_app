import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class GuardianDashboardScreen extends StatelessWidget {
  const GuardianDashboardScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await AuthService().signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // NEW FILE: guardian gets a separate dashboard instead of the caregiver one.
      appBar: AppBar(
        title: const Text('Guardian dashboard'),
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
                'Guardian access depends on the DB permission attached to each patient. '
                    'Use the access dashboard to review the invites and the patients you can see.',
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
              leading: const Icon(Icons.family_restroom_outlined),
              title: const Text('Guardian profile'),
              subtitle: const Text('Edit your guardian profile'),
              onTap: () => Navigator.pushNamed(context, '/guardian_profile'),
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