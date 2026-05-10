import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/caregiver_permission_model.dart';
import '../services/caregiver_service.dart';
import '../services/patient_service.dart';

class CaregiverScreen extends StatefulWidget {
  const CaregiverScreen({super.key});

  @override
  State<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends State<CaregiverScreen> {
  final _service = CaregiverService();
  final _patientService = PatientService();
  final _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _patientId;
  String? _userId;
  List<CaregiverPermissionModel> _permissions = [];

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
    final identity = await _patientService.resolveIdentity();
    if (identity == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    _patientId = identity.patientId;
    _userId = identity.appUserId;
    _permissions = await _service.fetchPermissions(_patientId!);

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addPermission() async {
    final emailController = TextEditingController();
    final notesController = TextEditingController();
    String permission = 'read';

    // Optional expiry date. If left empty, the permission stays active until revoked.
    DateTime? expiresAt;

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Grant caregiver access'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Caregiver email'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: permission,
                  items: const [
                    DropdownMenuItem(value: 'read', child: Text('Read')),
                    DropdownMenuItem(value: 'edit', child: Text('Edit')),
                    DropdownMenuItem(
                      value: 'emergency_only',
                      child: Text('Emergency only'),
                    ),
                  ],
                  onChanged: (v) {
                    setDialogState(() => permission = v ?? 'read');
                  },
                  decoration: const InputDecoration(labelText: 'Permission'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Expires at (optional)',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(expiresAt == null ? 'No expiry' : _formatDate(expiresAt)),
                      TextButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: now,
                            firstDate: now,
                            lastDate: DateTime(now.year + 10),
                          );
                          if (picked != null) {
                            setDialogState(() => expiresAt = picked);
                          }
                        },
                        child: const Text('Choose date'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (save != true || _patientId == null || _userId == null) return;

    // The caregiver must already exist in public.users.
    // The current DB FK points caregiver_user_id to users.id.
    final caregiverRow = await _supabase
        .from('users')
        .select('id')
        .eq('email', emailController.text.trim())
        .maybeSingle();

    if (caregiverRow == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No user found with that email. They must register first.'),
        ),
      );
      return;
    }

    final permissionRow = CaregiverPermissionModel(
      patientId: _patientId!,
      caregiverUserId: caregiverRow['id'] as String,
      permission: permission,
      status: 'active',
      grantedByUserId: _userId,
      grantedAt: DateTime.now(),
      expiresAt: expiresAt,
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
    );

    await _service.grantPermission(
      permission: permissionRow,
      performedByUserId: _userId!,
    );

    await _load();
  }

  Future<void> _revoke(String id) async {
    if (_patientId == null || _userId == null) return;

    await _service.revokePermission(
      id: id,
      patientId: _patientId!,
      performedByUserId: _userId!,
    );

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Caregivers')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPermission,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _permissions.isEmpty
          ? const Center(
        child: Text('No caregiver permissions yet.'),
      )
          : ListView.builder(
        itemCount: _permissions.length,
        itemBuilder: (context, index) {
          final item = _permissions[index];
          return Card(
            child: ListTile(
              title: Text(
                item.permission,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                [
                  'Status: ${item.status}',
                  'Caregiver user id: ${item.caregiverUserId}',
                  'Granted at: ${_formatDate(item.grantedAt)}',
                  'Expires at: ${_formatDate(item.expiresAt)}',
                  if (item.notes != null && item.notes!.isNotEmpty)
                    'Notes: ${item.notes}',
                ].join('\n'),
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.block),
                onPressed: () {
                  if (item.id != null) {
                    _revoke(item.id!);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}