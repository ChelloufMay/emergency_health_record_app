import 'package:flutter/material.dart';

class CaregiverChoiceScreen extends StatelessWidget {
  const CaregiverChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose your persona'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ChoiceCard(
            title: 'Caregiver',
            subtitle: 'Access records and manage patient permissions.',
            icon: Icons.health_and_safety,
            onTap: () => Navigator.pushNamed(context, '/caregiver_profile'),
          ),
          const SizedBox(height: 12),
          _ChoiceCard(
            title: 'Guardian',
            subtitle: 'Create a guardian profile for legal responsibility support.',
            icon: Icons.shield_outlined,
            onTap: () => Navigator.pushNamed(context, '/guardian_profile'),
          ),
          const SizedBox(height: 12),
          _ChoiceCard(
            title: 'Clinician',
            subtitle: 'Create a clinician profile for professional access.',
            icon: Icons.medical_services_outlined,
            onTap: () => Navigator.pushNamed(context, '/clinician_profile'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.pushNamed(context, '/access_dashboard'),
            child: const Text('Open access dashboard'),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}