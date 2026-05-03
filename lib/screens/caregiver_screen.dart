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

  Future<void> _load() async {
    final identity = await _patientService.resolveIdentity();
    if (identity == null) {
      setState(() => _loading = false);
      return;
    }

    _patientId = identity.patientId;
    _userId = identity.appUserId;
    _permissions = await _service.fetchPermissions(_patientId!);

    setState(() => _loading = false);
  }

  Future<void> _addPermission() async {
    final emailController = TextEditingController();
    final notesController = TextEditingController();
    String permission = 'read';

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grant caregiver access'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Caregiver email'),
              ),
              DropdownButtonFormField<String>(
                initialValue: permission,
                items: const [
                  DropdownMenuItem(value: 'read', child: Text('Read')),
                  DropdownMenuItem(value: 'edit', child: Text('Edit')),
                  DropdownMenuItem(value: 'emergency_only', child: Text('Emergency only')),
                ],
                onChanged: (v) => permission = v ?? 'read',
                decoration: const InputDecoration(labelText: 'Permission'),
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (save != true || _patientId == null || _userId == null) return;

    final caregiverRow = await _supabase
        .from('users')
        .select('id')
        .eq('email', emailController.text.trim())
        .maybeSingle();

    if (caregiverRow == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user found with that email')),
      );
      return;
    }

    final permissionRow = CaregiverPermissionModel(
      id: 'temp',
      patientId: _patientId!,
      caregiverUserId: caregiverRow['id'] as String,
      permission: permission,
      status: 'active',
      grantedByUserId: _userId,
      grantedAt: DateTime.now(),
      notes: notesController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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
          : ListView.builder(
        itemCount: _permissions.length,
        itemBuilder: (context, index) {
          final item = _permissions[index];
          return Card(
            child: ListTile(
              title: Text(item.permission),
              subtitle: Text('${item.status} • ${item.caregiverUserId}'),
              trailing: IconButton(
                icon: const Icon(Icons.block),
                onPressed: () => _revoke(item.id),
              ),
            ),
          );
        },
      ),
    );
  }
}