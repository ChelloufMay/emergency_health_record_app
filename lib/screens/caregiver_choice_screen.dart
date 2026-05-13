import 'package:flutter/material.dart';
import '../services/patient_service.dart';

class CaregiverChoiceScreen extends StatelessWidget {
  const CaregiverChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PersonaChoiceScreen();
  }
}

class PersonaChoiceScreen extends StatefulWidget {
  const PersonaChoiceScreen({super.key});

  @override
  State<PersonaChoiceScreen> createState() => _PersonaChoiceScreenState();
}

class _PersonaChoiceScreenState extends State<PersonaChoiceScreen> {
  final PatientService _patientService = PatientService();

  bool _loading = true;
  bool _hasCaregiver = false;
  bool _hasGuardian = false;
  bool _hasClinician = false;
  bool _hasAccess = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final caregiver = await _patientService.hasCaregiverProfile();
    final guardian = await _patientService.hasGuardianProfile();
    final clinician = await _patientService.hasClinicianProfile();
    final access = await _patientService.hasAnyAccessGrant();

    if (!mounted) return;
    setState(() {
      _hasCaregiver = caregiver;
      _hasGuardian = guardian;
      _hasClinician = clinician;
      _hasAccess = access;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose your space'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Pick the area you want to open.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _PersonaCard(
            icon: Icons.home_outlined,
            title: 'My home account',
            subtitle: 'Open the owner/patient dashboard',
            onTap: () => Navigator.pushNamed(context, '/home'),
          ),
          const SizedBox(height: 12),
          _PersonaCard(
            icon: Icons.people_outline,
            title: 'Access dashboard',
            subtitle: 'Open the patients you can access',
            onTap: () => Navigator.pushNamed(context, '/access_dashboard'),
          ),
          const SizedBox(height: 12),
          _PersonaCard(
            icon: Icons.person_outline,
            title: 'My caregiver profile',
            subtitle: _hasCaregiver ? 'Open your caregiver profile' : 'Create your caregiver profile',
            onTap: () => Navigator.pushNamed(context, '/caregiver_profile'),
          ),
          const SizedBox(height: 12),
          _PersonaCard(
            icon: Icons.badge_outlined,
            title: 'My guardian profile',
            subtitle: _hasGuardian ? 'Open your guardian profile' : 'Create your guardian profile',
            onTap: () => Navigator.pushNamed(context, '/guardian_profile'),
          ),
          const SizedBox(height: 12),
          _PersonaCard(
            icon: Icons.medical_services_outlined,
            title: 'My clinician profile',
            subtitle: _hasClinician ? 'Open your clinician profile' : 'Create your clinician profile',
            onTap: () => Navigator.pushNamed(context, '/clinician_profile'),
          ),
          if (!_hasAccess)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text(
                'No access grants yet. Ask the owner to invite you.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}

class _PersonaCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PersonaCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}