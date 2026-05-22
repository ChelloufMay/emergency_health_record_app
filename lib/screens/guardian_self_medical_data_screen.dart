import 'package:flutter/material.dart';

import '../services/patient_service.dart';

class GuardianSelfMedicalDataScreen extends StatefulWidget {
  const GuardianSelfMedicalDataScreen({super.key});

  @override
  State<GuardianSelfMedicalDataScreen> createState() =>
      _GuardianSelfMedicalDataScreenState();
}

class _GuardianSelfMedicalDataScreenState
    extends State<GuardianSelfMedicalDataScreen> {
  final PatientService _patientService = PatientService();

  bool _loading = true;
  String? _error;
  String? _patientId;
  String _roleLabel = 'guardian';

  @override
  void initState() {
    super.initState();
    _loadIdentity();
  }

  Future<void> _loadIdentity() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final identity = await _patientService.resolveIdentity();
      final patientId = identity?.patientProfileId;
      final role = identity?.role?.trim().toLowerCase();

      if (!mounted) return;
      setState(() {
        _patientId = patientId;
        _roleLabel = (role == null || role.isEmpty) ? 'guardian' : role;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your profile: $e';
        _loading = false;
      });
    }
  }

  void _openSection(String routeName) {
    final patientId = _patientId;
    if (patientId == null || patientId.isEmpty) return;

    Navigator.of(context).pushNamed(
      routeName,
      arguments: {
        'patientId': patientId,
        'canEdit': true,
      },
    );
  }

  Widget _buildAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canOpen = _patientId != null && _patientId!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My medical data'),
        actions: [
          IconButton(
            onPressed: _loadIdentity,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'This area is for your own $_roleLabel profile data. '
                    'It opens the same section editors, but always targets your personal patient profile.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!canOpen)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No personal patient profile was found for this account yet.',
                ),
              ),
            )
          else ...[
            _buildAction(
              title: 'Allergies',
              subtitle: 'Add or edit your own allergy records.',
              icon: Icons.warning_amber_rounded,
              onPressed: () => _openSection('/allergies'),
            ),
            _buildAction(
              title: 'Medications',
              subtitle: 'Add or edit your own medications.',
              icon: Icons.medication_outlined,
              onPressed: () => _openSection('/medications'),
            ),
            _buildAction(
              title: 'Conditions',
              subtitle: 'Open your own condition records.',
              icon: Icons.monitor_heart_outlined,
              onPressed: () => _openSection('/conditions'),
            ),
          ],
        ],
      ),
    );
  }
}