import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    PatientSession? session = PatientSessionService.instance.current;

    if (session == null) {
      try {
        final identity = await _patientService.resolveIdentity();
        if (identity?.patientProfileId != null) {
          final patientId = identity!.patientProfileId!;
          final summary = await _patientService.fetchPatientSummary(patientId);

          final firstName = summary?['first_name']?.toString().trim() ?? '';
          final familyName = summary?['family_name']?.toString().trim() ?? '';
          final displayName = '$firstName $familyName'.trim();

          PatientSessionService.instance.setSession(
            patientId: patientId,
            patientName: displayName.isEmpty ? null : displayName,
            permission: 'owner',
          );

          session = PatientSessionService.instance.current;
        }
      } catch (_) {
        // Keep going; the screen can still render without a session.
      }
    }

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

  void _openSection(String routeName) {
    final session = _session;

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

  Widget _navCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 30),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                    (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
          ),
        ],
      ),
      // Responsive layout so cards adapt better across devices.
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 10.0;
          final quickWidth = constraints.maxWidth > 700
              ? (constraints.maxWidth - (spacing * 3)) / 4
              : (constraints.maxWidth - spacing) / 2;
          final medicalWidth = constraints.maxWidth > 900
              ? (constraints.maxWidth - (spacing * 4)) / 3
              : (constraints.maxWidth - spacing) / 2;

          return ListView(
            padding: const EdgeInsets.all(16),
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
                          'Address: ${((_summary?['address_country']?.toString() ?? '').trim().isEmpty) ? 'Not set' : [_summary?['address_country']?.toString(), _summary?['address_governorate']?.toString(), _summary?['address_city']?.toString()].where((e) => e != null && e.toString().trim().isNotEmpty).join(' • ')}',
                        ),
                      ],
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/patient_access_management',
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
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _navCard(
                    icon: Icons.person_outline,
                    label: 'My Profile',
                    onTap: () => _openSection('/profile'),
                    width: quickWidth,
                  ),
                  _navCard(
                    icon: Icons.summarize_outlined,
                    label: 'Medical Summary',
                    onTap: () => _openSection('/medical_summary'),
                    width: quickWidth,
                  ),
                  _navCard(
                    icon: Icons.qr_code_2,
                    label: 'Emergency Token',
                    onTap: () => _openSection('/qr'),
                    width: quickWidth,
                  ),
                  _navCard(
                    icon: Icons.emergency_outlined,
                    label: 'Emergency View',
                    onTap: () => _openSection('/emergency'),
                    width: quickWidth,
                  ),
                  _navCard(
                    icon: Icons.people_outline,
                    label: 'Access management',
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/patient_access_management',
                      arguments: {'patientId': session?.patientId},
                    ),
                    width: quickWidth,
                  ),
                  _navCard(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/patient_notifications',
                      arguments: {'patientId': session?.patientId},
                    ),
                    width: quickWidth,
                  ),
                  _navCard(
                    icon: Icons.history,
                    label: 'Audit Log',
                    onTap: () => _openSection('/audit_log'),
                    width: quickWidth,
                  ),
                  _navCard(
                    icon: Icons.psychology_outlined,
                    label: 'Risk Predictions',
                    onTap: () => _openSection('/patient_risk_predictions'),
                    width: quickWidth,
                  ),
                  _navCard(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                    width: quickWidth,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Medical sections',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _smallCard(
                    icon: Icons.warning_amber,
                    label: 'Allergies',
                    onTap: () => _openSection('/allergies'),
                    width: medicalWidth,
                  ),
                  _smallCard(
                    icon: Icons.medication,
                    label: 'Medications',
                    onTap: () => _openSection('/medications'),
                    width: medicalWidth,
                  ),
                  _smallCard(
                    icon: Icons.local_hospital,
                    label: 'Conditions',
                    onTap: () => _openSection('/conditions'),
                    width: medicalWidth,
                  ),
                  _smallCard(
                    icon: Icons.cut,
                    label: 'Surgeries',
                    onTap: () => _openSection('/surgeries'),
                    width: medicalWidth,
                  ),
                  _smallCard(
                    icon: Icons.bed_outlined,
                    label: 'Hospitalizations',
                    onTap: () => _openSection('/hospitalizations'),
                    width: medicalWidth,
                  ),
                  _smallCard(
                    icon: Icons.vaccines,
                    label: 'Vaccinations',
                    onTap: () => _openSection('/vaccinations'),
                    width: medicalWidth,
                  ),
                  _smallCard(
                    icon: Icons.self_improvement,
                    label: 'Lifestyle',
                    onTap: () => _openSection('/lifestyle'),
                    width: medicalWidth,
                  ),
                  _smallCard(
                    icon: Icons.family_restroom,
                    label: 'Family history',
                    onTap: () => _openSection('/family_history'),
                    width: medicalWidth,
                  ),
                  _smallCard(
                    icon: Icons.healing,
                    label: 'Reproductive',
                    onTap: () => _openSection('/reproductive_health'),
                    width: medicalWidth,
                  ),
                  _smallCard(
                    icon: Icons.person_search,
                    label: 'Family doctor',
                    onTap: () => _openSection('/family_doctor'),
                    width: medicalWidth,
                  ),
                  _smallCard(
                    icon: Icons.attach_file,
                    label: 'Attachments',
                    onTap: () => _openSection('/attachments'),
                    width: medicalWidth,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}