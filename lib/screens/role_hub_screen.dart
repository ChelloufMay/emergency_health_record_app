import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class RoleHubScreen extends StatelessWidget {
  final String title;
  final String description;
  final String dashboardRoute;
  final String accessInboxRoute;
  final String accessManagementRoute;
  final String profileRoute;
  final String settingsRoute;

  const RoleHubScreen({
    super.key,
    required this.title,
    required this.description,
    required this.dashboardRoute,
    required this.accessInboxRoute,
    required this.accessManagementRoute,
    required this.profileRoute,
    required this.settingsRoute,
  });

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
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? BackButton(
          onPressed: () => Navigator.pop(context),
        )
            : null,
        title: Text(title),
        actions: [
          IconButton(
            onPressed: () => _open(context, settingsRoute),
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
              child: Text(description),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              subtitle: const Text('Patients you can access'),
              onTap: () => _open(context, dashboardRoute),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: const Text('Invites / inbox'),
              subtitle: const Text('Accept or reject incoming access invites'),
              onTap: () => _open(context, accessInboxRoute),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('My active access'),
              subtitle: const Text('View patients and permissions granted to you'),
              onTap: () => _open(context, accessManagementRoute),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Profile'),
              subtitle: const Text('Edit your role profile'),
              onTap: () => _open(context, profileRoute),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              subtitle: const Text('Open your role-specific settings'),
              onTap: () => _open(context, settingsRoute),
            ),
          ),
        ],
      ),
    );
  }
}
