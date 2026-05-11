import 'package:flutter/material.dart';

import '../models/caregiver_permission_model.dart';
import '../services/caregiver_profile_service.dart';
import '../services/caregiver_service.dart';
import '../services/patient_service.dart';
import 'caregiver_patient_detail_screen.dart';

class _CaregiverPatientGroup {
  final String patientId;
  final Map<String, dynamic>? summary;
  final List<CaregiverPermissionModel> permissions;

  _CaregiverPatientGroup({
    required this.patientId,
    required this.summary,
    required this.permissions,
  });

  String get displayName {
    final first = summary?['first_name']?.toString().trim() ?? '';
    final family = summary?['family_name']?.toString().trim() ?? '';
    final fullName = '$first $family'.trim();
    return fullName.isEmpty ? 'Unknown patient' : fullName;
  }

  List<CaregiverPermissionModel> get activePermissions {
    return permissions.where((p) => _isActive(p)).toList();
  }

  List<CaregiverPermissionModel> get inactivePermissions {
    return permissions.where((p) => !_isActive(p)).toList();
  }

  bool get hasActivePermission => activePermissions.isNotEmpty;

  String get permissionSummary {
    final items = permissions
        .map((p) => p.permission)
        .toSet()
        .toList()
      ..sort();
    return items.isEmpty ? 'No permissions' : items.join(', ');
  }

  static bool _isActive(CaregiverPermissionModel permission) {
    if (permission.status != 'active') return false;
    if (permission.expiresAt == null) return true;
    return permission.expiresAt!.isAfter(DateTime.now());
  }
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
  String? _profileId;
  List<_CaregiverPatientGroup> _groups = [];

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

  Future<void> _load() async {
    try {
      final userRow = await _patientService.fetchCurrentAppUserRow();

      // This creates a shell profile if the caregiver has no profile row yet.
      // That way the profile screen does not feel empty or broken.
      final profile = await _caregiverProfileService.ensureProfileShell();

      final permissions = await _caregiverService.fetchMyPermissions();
      final byPatientId = <String, List<CaregiverPermissionModel>>{};

      for (final permission in permissions) {
        byPatientId.putIfAbsent(permission.patientId, () => []);
        byPatientId[permission.patientId]!.add(permission);
      }

      final groups = <_CaregiverPatientGroup>[];
      for (final entry in byPatientId.entries) {
        final summary = await _caregiverService.fetchPatientSummary(entry.key);
        groups.add(
          _CaregiverPatientGroup(
            patientId: entry.key,
            summary: summary,
            permissions: entry.value,
          ),
        );
      }

      groups.sort((a, b) => a.displayName.compareTo(b.displayName));

      if (!mounted) return;
      setState(() {
        _displayName = userRow?['full_name']?.toString().trim().isNotEmpty == true
            ? userRow!['full_name'].toString()
            : 'Caregiver';
        _profileId = profile.id;
        _groups = groups;
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
    final activeGroups = _groups.where((g) => g.hasActivePermission).toList();
    final inactiveGroups = _groups.where((g) => !g.hasActivePermission).toList();

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
                    const Text(
                      'Active means the permission is usable now. Revoked means the owner removed it. Expired means the date has passed.',
                    ),
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
              'Patients you can currently open',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (activeGroups.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No active patient access yet. When an owner grants you access, the patient will appear here.',
                  ),
                ),
              )
            else
              ...activeGroups.map((group) {
                final activeLabels = group.activePermissions
                    .map((p) => p.permission)
                    .toSet()
                    .toList()
                  ..sort();

                final expiresDates = group.activePermissions
                    .map((p) => p.expiresAt)
                    .whereType<DateTime>()
                    .toList();

                DateTime? nextExpiry;
                if (expiresDates.isNotEmpty) {
                  expiresDates.sort((a, b) => a.compareTo(b));
                  nextExpiry = expiresDates.first;
                }

                return Card(
                  child: ListTile(
                    title: Text(
                      group.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      [
                        'Permissions: ${activeLabels.isEmpty ? 'none' : activeLabels.join(', ')}',
                        'Active records: ${group.activePermissions.length}',
                        if (group.inactivePermissions.isNotEmpty)
                          'Other records: ${group.inactivePermissions.length} inactive/revoked/expired',
                        'Expires at: ${_formatDate(nextExpiry)}',
                      ].join('\n'),
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CaregiverPatientDetailScreen(
                            patientId: group.patientId,
                            summary: group.summary,
                            permissions: group.permissions,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            const SizedBox(height: 16),
            const Text(
              'Revoked or expired access',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (inactiveGroups.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No revoked or expired permissions found.'),
                ),
              )
            else
              ...inactiveGroups.map((group) {
                return Card(
                  child: ListTile(
                    title: Text(
                      group.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      [
                        'Permissions: ${group.permissionSummary}',
                        'Inactive records: ${group.permissions.length}',
                        'Status: revoked / expired',
                      ].join('\n'),
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CaregiverPatientDetailScreen(
                            patientId: group.patientId,
                            summary: group.summary,
                            permissions: group.permissions,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}