import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// manages who has access to the patient's record
// note: adding a caregiver requires knowing their public.users UUID
// in production this would be handled by an invite link flow
class CaregiverScreen extends StatefulWidget {
  const CaregiverScreen({super.key});

  @override
  State<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends State<CaregiverScreen> {
  final _supabase = Supabase.instance.client;

  String? _patientId;
  String? _appUserId;
  List<Map<String, dynamic>> _permissions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final authId = _supabase.auth.currentUser?.id;
      if (authId == null) return;

      final userRow = await _supabase
          .from('users')
          .select('id')
          .eq('auth_user_id', authId)
          .maybeSingle();

      if (userRow == null) return;
      _appUserId = userRow['id'] as String;

      final profileRow = await _supabase
          .from('patient_profiles')
          .select('id')
          .eq('user_id', _appUserId!)
          .maybeSingle();

      if (profileRow == null) {
        setState(
                () => _errorMessage = 'Complete your profile first.');
        return;
      }

      _patientId = profileRow['id'] as String;

      final perms = await _supabase
          .from('caregiver_permissions')
          .select()
          .eq('patient_id', _patientId!)
          .order('granted_at', ascending: false);

      setState(() =>
      _permissions = List<Map<String, dynamic>>.from(perms as List));
    } on PostgrestException catch (e) {
      setState(() => _errorMessage = 'Error: ${e.message}');
    } catch (_) {
      setState(() => _errorMessage = 'Unexpected error.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddCaregiverDialog() async {
    final userIdCtrl = TextEditingController();
    String selectedPermission = 'read';
    String? dialogError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Caregiver'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The caregiver must already have an account. '
                      'Ask them to share their User ID from the Settings screen.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: userIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Caregiver User ID',
                    hintText: 'Paste their UUID here',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedPermission,
                  decoration:
                  const InputDecoration(labelText: 'Permission Level'),
                  items: const [
                    DropdownMenuItem(
                        value: 'read', child: Text('Read only')),
                    DropdownMenuItem(
                        value: 'edit', child: Text('Read and edit')),
                    DropdownMenuItem(
                        value: 'emergency_only',
                        child: Text('Emergency access only')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedPermission = v);
                    }
                  },
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: 8),
                  Text(dialogError!,
                      style: const TextStyle(
                          color: Colors.red, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final caregiverId = userIdCtrl.text.trim();

                if (caregiverId.isEmpty) {
                  setDialogState(
                          () => dialogError = 'Please enter a User ID.');
                  return;
                }

                if (caregiverId == _appUserId) {
                  setDialogState(() =>
                  dialogError = 'You cannot add yourself as a caregiver.');
                  return;
                }

                try {
                  await _supabase.from('caregiver_permissions').insert({
                    'patient_id': _patientId,
                    'caregiver_user_id': caregiverId,
                    'permission': selectedPermission,
                    'status': 'active',
                    'granted_by_user_id': _appUserId,
                  });

                  if (ctx.mounted) Navigator.pop(ctx);
                  await _loadData();
                } on PostgrestException catch (e) {
                  setDialogState(
                          () => dialogError = 'Failed: ${e.message}');
                } catch (_) {
                  setDialogState(() => dialogError = 'Unexpected error.');
                }
              },
              child: const Text('Grant Access'),
            ),
          ],
        ),
      ),
    );

    userIdCtrl.dispose();
  }

  Future<void> _revokePermission(String permissionId) async {
    try {
      await _supabase
          .from('caregiver_permissions')
          .update({'status': 'revoked'})
          .eq('id', permissionId);
      await _loadData();
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to revoke: ${e.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Caregiver Access')),
      floatingActionButton: _patientId != null
          ? FloatingActionButton(
        onPressed: _showAddCaregiverDialog,
        child: const Icon(Icons.person_add),
      )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
          child: Text(_errorMessage!,
              style: const TextStyle(color: Colors.red)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ------------------------------- share patient ID section -------------------------------
            if (_patientId != null) ...[
              const Text(
                'Your Patient ID',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              const Text(
                'Share this with a caregiver so they can be linked to your record.',
                style:
                TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _patientId!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: _patientId!));
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text('Patient ID copied.'),
                        ));
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 32),
            ],

            // ------------------------------- permissions list -------------------------------
            const Text(
              'Active Permissions',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),

            if (_permissions.isEmpty)
              const Text(
                'No caregivers added yet.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ..._permissions.map((p) {
                final status = p['status'] as String? ?? '';
                final permission = p['permission'] as String? ?? '';
                final grantedAt = p['granted_at'] as String? ?? '';
                final caregiverShortId = ((p['caregiver_user_id']
                as String?) ??
                    '')
                    .substring(
                    0,
                    ((p['caregiver_user_id'] as String?) ?? '')
                        .length >
                        8
                        ? 8
                        : 0);
                final isActive = status == 'active';

                return Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.person,
                      color:
                      isActive ? Colors.green : Colors.grey,
                    ),
                    title: Text(
                      'Permission: $permission',
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text('Status: $status'),
                        if (grantedAt.length >= 10)
                          Text(
                            'Granted: ${grantedAt.substring(0, 10)}',
                            style:
                            const TextStyle(fontSize: 11),
                          ),
                        Text(
                          'Caregiver: $caregiverShortId...',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: isActive
                        ? TextButton(
                      onPressed: () =>
                          _revokePermission(p['id']),
                      child: const Text(
                        'Revoke',
                        style:
                        TextStyle(color: Colors.red),
                      ),
                    )
                        : null,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}