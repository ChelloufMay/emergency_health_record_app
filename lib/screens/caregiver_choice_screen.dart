import 'package:flutter/material.dart';

class CaregiverChoiceScreen extends StatelessWidget {
  const CaregiverChoiceScreen({super.key});

  void _open(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose role'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // This screen is only a role launcher.
          // It does not read the DB directly; it sends the user to the
          // correct role/profile flow based on what they need to manage.
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Caregiver dashboard'),
              subtitle: const Text('View patients you can access'),
              onTap: () => _open(context, '/caregiver_dashboard'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Caregiver profile'),
              subtitle: const Text('Edit caregiver profile data'),
              onTap: () => _open(context, '/caregiver_profile'),
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
              leading: const Icon(Icons.family_restroom_outlined),
              title: const Text('Guardian profile'),
              subtitle: const Text('Edit guardian profile data'),
              onTap: () => _open(context, '/guardian_profile'),
            ),
          ),
        ],
      ),
    );
  }
}