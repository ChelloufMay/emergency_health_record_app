import 'package:flutter/material.dart';
import '../services/access_service.dart';
import '../services/patient_service.dart';

class CaregiverScreen extends StatefulWidget {
  const CaregiverScreen({super.key});

  @override
  State<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends State<CaregiverScreen> {
  final PatientService _patientService = PatientService();
  final AccessService _accessService = AccessService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _loading = true;
  bool _sending = false;
  String? _patientId;
  List<Map<String, dynamic>> _invites = [];
  List<Map<String, dynamic>> _grants = [];

  String _selectedRole = 'caregiver';
  String _selectedPermission = 'read';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final identity = await _patientService.resolveIdentity();
    if (identity == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final invites = await _accessService.fetchPatientInvites(identity.patientId);
    final grants = await _accessService.fetchPatientGrants(identity.patientId);

    if (!mounted) return;
    setState(() {
      _patientId = identity.patientId;
      _invites = invites;
      _grants = grants;
      _loading = false;
    });
  }

  Future<void> _sendInvite() async {
    if (_patientId == null) return;
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _sending = true);
    try {
      await _accessService.createInvite(
        patientId: _patientId!,
        invitedEmail: email,
        invitedRole: _selectedRole,
        permission: _selectedPermission,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      _emailController.clear();
      _notesController.clear();
      await _load();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access management'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Invite caregiver, guardian, or clinician',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            items: const [
              DropdownMenuItem(value: 'caregiver', child: Text('Caregiver')),
              DropdownMenuItem(value: 'guardian', child: Text('Guardian')),
              DropdownMenuItem(value: 'clinician', child: Text('Clinician')),
            ],
            onChanged: (value) => setState(() => _selectedRole = value ?? 'caregiver'),
            decoration: const InputDecoration(labelText: 'Role'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedPermission,
            items: const [
              DropdownMenuItem(value: 'read', child: Text('Read')),
              DropdownMenuItem(value: 'edit', child: Text('Edit')),
              DropdownMenuItem(value: 'emergency_only', child: Text('Emergency only')),
            ],
            onChanged: (value) => setState(() => _selectedPermission = value ?? 'read'),
            decoration: const InputDecoration(labelText: 'Permission'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes'),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _sending ? null : _sendInvite,
            child: Text(_sending ? 'Sending...' : 'Send invite'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Current grants',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._grants.map((g) => Card(
            child: ListTile(
              title: Text('${g['grantee_role'] ?? '-'} • ${g['permission'] ?? '-'}'),
              subtitle: Text(
                'Status: ${g['status'] ?? '-'}\n'
                    'Expires: ${g['expires_at'] ?? '-'}',
              ),
            ),
          )),
          const SizedBox(height: 24),
          const Text(
            'Pending invites',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._invites.map((i) => Card(
            child: ListTile(
              title: Text('${i['invited_role'] ?? '-'} • ${i['invited_email'] ?? '-'}'),
              subtitle: Text(
                'Permission: ${i['permission'] ?? '-'}\nStatus: ${i['status'] ?? '-'}',
              ),
            ),
          )),
        ],
      ),
    );
  }
}
