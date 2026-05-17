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
    // This screen is the owner hub.
    // It should read the currently selected patient from the local session,
    // then pull the owner-safe summary from patient_profiles_enriched.
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

    // Every owner-flow screen gets the patient context so it can stay aligned
    // with the DB row it is actually reading/writing.
    Navigator.pushNamed(
      context,
      routeName,
      arguments: {
        'patientId': session?.patientId,
        'canEdit': true,
        'isEmergencyOnly': false,
      },
    );
  }

  String _displayName() {
    final firstName = _summary?['first_name']?.toString().trim() ?? '';
    final familyName = _summary?['family_name']?.toString().trim() ?? '';
    final fromSummary = '$firstName $familyName'.trim();
    final fromSession = _session?.patientName?.trim() ?? '';
    return fromSummary.isNotEmpty ? fromSummary : fromSession;
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner dashboard'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
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
                      'Selected patient',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _displayName().isEmpty
                          ? 'No patient selected yet.'
                          : _displayName(),
                    ),
                    if (_summary != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Blood type: ${_summary?['blood_type']?.toString() ?? 'Unknown'}',
                      ),
                      Text(
                        'Age: ${_summary?['age_years']?.toString() ?? 'Unknown'}',
                      ),
                      Text(
                        'Address: ${((
                            _summary?['address_country']?.toString() ?? ''
                        )).trim().isEmpty ? 'Not set' : [
                          _summary?['address_country']?.toString(),
                          _summary?['address_governorate']?.toString(),
                          _summary?['address_city']?.toString(),
                        ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' • ')}',
                      ),
                    ],
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/access_dashboard',
                        arguments: {'patientId': session?.patientId},
                      ),
                      child: const Text('Change / manage access'),
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
                _NavCard(
                  icon: Icons.person_outline,
                  label: 'My Profile',
                  onTap: () => _openSection('/profile'),
                ),
                _NavCard(
                  icon: Icons.summarize_outlined,
                  label: 'Medical Summary',
                  onTap: () => _openSection('/medical_summary'),
                ),
                _NavCard(
                  icon: Icons.qr_code_2,
                  label: 'Emergency Token',
                  onTap: () => _openSection('/qr'),
                ),
                _NavCard(
                  icon: Icons.emergency_outlined,
                  label: 'Emergency View',
                  onTap: () => _openSection('/emergency'),
                ),
                _NavCard(
                  icon: Icons.people_outline,
                  label: 'Access Dashboard',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/access_dashboard',
                    arguments: {'patientId': session?.patientId},
                  ),
                ),
                _NavCard(
                  icon: Icons.history,
                  label: 'Audit Log',
                  onTap: () => _openSection('/audit_log'),
                ),
                _NavCard(
                  icon: Icons.psychology_outlined,
                  label: 'Risk Predictions',
                  onTap: () => _openSection('/patient_risk_predictions'),
                ),
                _NavCard(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Medical sections',
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
                _SmallCard(
                  icon: Icons.warning_amber,
                  label: 'Allergies',
                  onTap: () => _openSection('/allergies'),
                ),
                _SmallCard(
                  icon: Icons.medication,
                  label: 'Medications',
                  onTap: () => _openSection('/medications'),
                ),
                _SmallCard(
                  icon: Icons.local_hospital,
                  label: 'Conditions',
                  onTap: () => _openSection('/conditions'),
                ),
                _SmallCard(
                  icon: Icons.cut,
                  label: 'Surgeries',
                  onTap: () => _openSection('/surgeries'),
                ),
                _SmallCard(
                  icon: Icons.bed_outlined,
                  label: 'Hospitalizations',
                  onTap: () => _openSection('/hospitalizations'),
                ),
                _SmallCard(
                  icon: Icons.vaccines,
                  label: 'Vaccinations',
                  onTap: () => _openSection('/vaccinations'),
                ),
                _SmallCard(
                  icon: Icons.self_improvement,
                  label: 'Lifestyle',
                  onTap: () => _openSection('/lifestyle'),
                ),
                _SmallCard(
                  icon: Icons.family_restroom,
                  label: 'Family history',
                  onTap: () => _openSection('/family_history'),
                ),
                _SmallCard(
                  icon: Icons.healing,
                  label: 'Reproductive',
                  onTap: () => _openSection('/reproductive_health'),
                ),
                _SmallCard(
                  icon: Icons.person_search,
                  label: 'Family doctor',
                  onTap: () => _openSection('/family_doctor'),
                ),
                _SmallCard(
                  icon: Icons.attach_file,
                  label: 'Attachments',
                  onTap: () => _openSection('/attachments'),
                ),
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