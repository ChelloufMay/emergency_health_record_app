import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _supabase = Supabase.instance.client;

  final _nameController = TextEditingController();
  String? _email;
  String? _appUserId;
  String? _role;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final authId = _supabase.auth.currentUser?.id;
      if (authId == null) return;

      final userRow = await _supabase
          .from('users')
          .select()
          .eq('auth_user_id', authId)
          .maybeSingle();

      if (userRow != null && mounted) {
        _nameController.text = userRow['full_name'] ?? '';
        _email = userRow['email'] as String?;
        _appUserId = userRow['id'] as String?;
        _role = userRow['role'] as String?;
      }
    } catch (_) {
      // not critical
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveName() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final authId = _supabase.auth.currentUser?.id;
      if (authId == null) return;

      await _supabase
          .from('users')
          .update({'full_name': _nameController.text.trim()})
          .eq('auth_user_id', authId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated.')),
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.message}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(24),
        children: [

          // ------------------------------- Account section -------------------------------
          const Text(
            'Account',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration:
            const InputDecoration(labelText: 'Full Name'),
          ),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveName,
              child: _isSaving
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2),
              )
                  : const Text('Update Name'),
            ),
          ),
          const SizedBox(height: 16),

          if (_email != null)
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email'),
              subtitle: Text(_email!),
              contentPadding: EdgeInsets.zero,
            ),

          if (_role != null)
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Role'),
              subtitle: Text(_role!),
              contentPadding: EdgeInsets.zero,
            ),

          const Divider(height: 32),

          // ------------------------------- User ID (for caregiver linking) ---------------
          const Text(
            'Your User ID',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Share this with a patient who wants to add you as their caregiver.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 10),

          if (_appUserId != null)
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
                      _appUserId!,
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
                          ClipboardData(text: _appUserId!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('User ID copied.')),
                      );
                    },
                  ),
                ],
              ),
            ),

          const Divider(height: 32),

          // ------------------------------- Sign out -------------------------------
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
            onTap: _signOut,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}