import 'package:flutter/material.dart';

import '../models/caregiver_permission_model.dart';
import '../services/caregiver_profile_service.dart';
import '../services/caregiver_service.dart';
import '../services/patient_service.dart';

class _CaregiverPatientCard {
  final CaregiverPermissionModel permission;
  final Map<String, dynamic>? summary;

  _CaregiverPatientCard({
    required this.permission,
    required this.summary,
  });
}

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  final PatientService _patientService = PatientService();
  final CaregiverService _caregiverService = CaregiverService();
  final CaregiverProfileService _caregiverProfileService =
  CaregiverProfileService();

  bool _loading = true;
  String _displayName = 'Caregiver';
  String? _role;
  String? _profileId;
  String? _profileStatus;
  List<_CaregiverPatientCard> _cards = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool _isExpired(DateTime? expiresAt) {
    if (expiresAt == null) return false;
    return expiresAt.isBefore(DateTime.now());
  }

  Future<void> _load() async {
    try {
      final userRow = await _patientService.fetchCurrentAppUserRow();
      final currentRole = await _patientService.getCurrentRole();

      // This creates a shell profile if the caregiver has no profile row yet.
      // That way the profile screen does not feel empty or broken.
      final profile = await _caregiverProfileService.ensureProfileShell();

      final permissions = await _caregiverService.fetchMyPermissions();
      final cards = <_CaregiverPatientCard>[];

      for (final permission in permissions) {
        final summary = await _caregiverService.fetchPatientSummary(
          permission.patientId,
        );
        cards.add(_CaregiverPatientCard(
          permission: permission,
          summary: summary,
        ));
      }

      if (!mounted) return;
      setState(() {
        _displayName = userRow?['full_name']?.toString().trim().isNotEmpty == true
            ? userRow!['full_name'].toString()
            : 'Caregiver';
        _role = currentRole;
        _profileId = profile.id;
        _profileStatus = profile.relationshipToPatient == null &&
            profile.phone == null &&
            profile.addressId == null
            ? 'Profile started, but not completed yet'
            : 'Profile completed or partially filled';
        _cards = cards;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCards = _cards
        .where((c) => c.permission.status == 'active' && !_isExpired(c.permission.expiresAt))
        .toList();

    final inactiveCards = _cards
        .where((c) => c.permission.status != 'active' || _isExpired(c.permission.expiresAt))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caregiver Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () async {
              await Navigator.pushNamed(context, '/caregiver_profile');
              await _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $_displayName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Role label in public.users: ${_role ?? '-'}'),
                    const SizedBox(height: 8),
                    Text('Profile: $_profileStatus'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        await Navigator.pushNamed(
                          context,
                          '/caregiver_profile',
                        );
                        await _load();
                      },
                      child: const Text('Edit caregiver profile'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your active patient access',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (activeCards.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No active patient access yet. When an owner grants you access, the patient will appear here.',
                  ),
                ),
              )
            else
              ...activeCards.map((card) {
                final summary = card.summary;
                final fullName = summary == null
                    ? 'Unknown patient'
                    : '${summary['first_name'] ?? ''} ${summary['family_name'] ?? ''}'
                    .trim();

                return Card(
                  child: ListTile(
                    title: Text(
                      fullName.isEmpty ? 'Unknown patient' : fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      [
                        'Permission: ${card.permission.permission}',
                        'Status: ${card.permission.status}',
                        'Expires at: ${_formatDate(card.permission.expiresAt)}',
                        if (summary != null)
                          'Age: ${summary['age_years'] ?? '-'}',
                        if (summary != null)
                          'Blood type: ${summary['blood_type'] ?? '-'}',
                        if (summary != null)
                          'City: ${summary['address_city'] ?? '-'}',
                      ].join('\n'),
                    ),
                    isThreeLine: true,
                  ),
                );
              }),
            const SizedBox(height: 16),
            const Text(
              'Inactive or expired access',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (inactiveCards.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No expired permissions found.'),
                ),
              )
            else
              ...inactiveCards.map((card) {
                return Card(
                  child: ListTile(
                    title: Text(
                      'Patient ID: ${card.permission.patientId}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      [
                        'Permission: ${card.permission.permission}',
                        'Status: ${card.permission.status}',
                        'Expires at: ${_formatDate(card.permission.expiresAt)}',
                        if (_isExpired(card.permission.expiresAt))
                          'Reason: permission expired',
                      ].join('\n'),
                    ),
                    isThreeLine: true,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}