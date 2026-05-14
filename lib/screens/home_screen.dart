import 'package:flutter/material.dart';

import '../services/patient_service.dart';
import '../services/patient_session_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PatientService _patientService = PatientService();

  bool _loading = true;
  Map<String, dynamic>? _summary;
  PatientSession? _session;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = PatientSessionService.instance.current;
    final summary = session == null
        ? null
        : await _patientService.fetchPatientSummary(session.patientId);

    if (!mounted) return;
    setState(() {
      _session = session;
      _summary = summary;
      _loading = false;
    });
  }

  Future<void> _signOut() async {
    await PatientSessionService.instance.clear();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/entry', (route) => false);
  }

  void _openSection(String routeName) {
    final session = _session;
    if (session == null) {
      Navigator.pushNamed(context, '/access_dashboard');
      return;
    }

    Navigator.pushNamed(
      context,
      routeName,
      arguments: {
        'patientId': session.patientId,
        'canEdit': session.canEdit,
        'isEmergencyOnly': session.isEmergencyOnly,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final patientName = [
      _summary?['first_name']?.toString() ?? session?.patientName ?? '',
      _summary?['family_name']?.toString() ?? '',
    ].join(' ').trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active patient session',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      session == null
                          ? 'No patient selected yet.'
                          : (patientName.isEmpty ? 'Selected patient' : patientName),
                    ),
                    if (session != null) ...[
                      const SizedBox(height: 4),
                      Text('Permission: ${session.permission ?? 'owner'}'),
                      Text('Patient ID: ${session.patientId}'),
                    ],
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.pushNamed(context, '/access_dashboard'),
                      child: const Text('Choose patient'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quick access',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.3,
              children: [
                _NavCard(icon: Icons.person_outline, label: 'My Profile', onTap: () => _openSection('/profile')),
                _NavCard(icon: Icons.summarize_outlined, label: 'Medical Summary', onTap: () => _openSection('/medical_summary')),
                _NavCard(icon: Icons.emergency_outlined, label: 'Emergency', onTap: () => _openSection('/emergency')),
                _NavCard(icon: Icons.qr_code, label: 'QR Code', onTap: () => _openSection('/qr')),
                _NavCard(icon: Icons.people_outline, label: 'Access', onTap: () => Navigator.pushNamed(context, '/access_dashboard')),
                _NavCard(icon: Icons.history, label: 'Audit Log', onTap: () => _openSection('/audit_log')),
                _NavCard(icon: Icons.settings_outlined, label: 'Settings', onTap: () => Navigator.pushNamed(context, '/settings')),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Medical records',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.0,
              children: [
                _SmallCard(icon: Icons.warning_amber, label: 'Allergies', onTap: () => _openSection('/allergies')),
                _SmallCard(icon: Icons.medication, label: 'Medications', onTap: () => _openSection('/medications')),
                _SmallCard(icon: Icons.local_hospital, label: 'Conditions', onTap: () => _openSection('/conditions')),
                _SmallCard(icon: Icons.cut, label: 'Surgeries', onTap: () => _openSection('/surgeries')),
                _SmallCard(icon: Icons.bed_outlined, label: 'Hospitalizations', onTap: () => _openSection('/hospitalizations')),
                _SmallCard(icon: Icons.vaccines, label: 'Vaccinations', onTap: () => _openSection('/vaccinations')),
                _SmallCard(icon: Icons.self_improvement, label: 'Lifestyle', onTap: () => _openSection('/lifestyle')),
                _SmallCard(icon: Icons.family_restroom, label: 'Family history', onTap: () => _openSection('/family_history')),
                _SmallCard(icon: Icons.healing, label: 'Reproductive', onTap: () => _openSection('/reproductive_health')),
                _SmallCard(icon: Icons.person_search, label: 'Family doctor', onTap: () => _openSection('/family_doctor')),
                _SmallCard(icon: Icons.attach_file, label: 'Attachments', onTap: () => _openSection('/attachments')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SmallCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SmallCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}