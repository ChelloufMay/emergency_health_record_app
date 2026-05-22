import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class SettingsShortcut {
  final IconData icon;
  final String title;
  final String subtitle;
  final String routeName;

  const SettingsShortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.routeName,
  });
}

class RoleSettingsScreen extends StatefulWidget {
  final String title;
  final String description;
  final List<SettingsShortcut> shortcuts;
  final bool allowPasswordChange;
  final bool allowAccountDeletion;
  final bool allowLogOut;

  const RoleSettingsScreen({
    super.key,
    required this.title,
    required this.description,
    this.shortcuts = const [],
    this.allowPasswordChange = true,
    this.allowAccountDeletion = true,
    this.allowLogOut = true,
  });

  @override
  State<RoleSettingsScreen> createState() => _RoleSettingsScreenState();
}

class _RoleSettingsScreenState extends State<RoleSettingsScreen> {
  final AuthService _authService = AuthService();

  bool _busy = false;

  Future<void> _setBusy(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _openShortcut(String routeName) async {
    if (_busy) return;
    await Navigator.pushNamed(context, routeName);
  }

  Future<void> _showChangePasswordDialog() async {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    try {
      final shouldUpdate = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Change password'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New password',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm new password',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _busy ? null : () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: _busy
                    ? null
                    : () => Navigator.pop(dialogContext, true),
                child: const Text('Update'),
              ),
            ],
          );
        },
      );

      if (shouldUpdate != true) return;

      final newPassword = newPasswordController.text.trim();
      final confirmPassword = confirmPasswordController.text.trim();

      if (newPassword.length < 8) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password must be at least 8 characters long.'),
          ),
        );
        return;
      }

      if (newPassword != confirmPassword) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match.'),
          ),
        );
        return;
      }

      await _setBusy(() async {
        await _authService.updatePassword(newPassword);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update password: $e')),
      );
    } finally {
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final reasonController = TextEditingController();

    try {
      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Request account deletion'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'This sends a deletion request to the administrator. '
                        'Your account is not deleted immediately from this screen.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Reason (optional)',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _busy ? null : () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton.tonal(
                onPressed: _busy
                    ? null
                    : () => Navigator.pop(dialogContext, true),
                child: const Text('Send request'),
              ),
            ],
          );
        },
      );

      if (shouldRequest != true) return;

      await _setBusy(() async {
        await _authService.requestAccountDeletion(
          reason: reasonController.text.trim().isEmpty
              ? null
              : reasonController.text.trim(),
        );
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deletion request sent.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send deletion request: $e')),
      );
    } finally {
      reasonController.dispose();
    }
  }

  Future<void> _signOut() async {
    if (_busy) return;
    await _setBusy(() async {
      await _authService.signOut();
    });

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Widget _shortcutCard(SettingsShortcut shortcut) {
    return Card(
      child: ListTile(
        leading: Icon(shortcut.icon),
        title: Text(shortcut.title),
        subtitle: Text(shortcut.subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: _busy ? null : () => _openShortcut(shortcut.routeName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(widget.description),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.shortcuts.isNotEmpty) ...[
                Text(
                  'Shortcuts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...widget.shortcuts.map(_shortcutCard),
                const SizedBox(height: 16),
              ],
              if (widget.allowPasswordChange) ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Change password'),
                    subtitle: const Text('Update your login password directly'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _busy ? null : _showChangePasswordDialog,
                  ),
                ),
              ],
              if (widget.allowAccountDeletion) ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Request account deletion'),
                    subtitle: const Text('Send a deletion request to the admin'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _busy ? null : _showDeleteAccountDialog,
                  ),
                ),
              ],
              if (widget.allowLogOut) ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Log out'),
                    subtitle: const Text('Sign out from this device'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _busy ? null : _signOut,
                  ),
                ),
              ],
            ],
          ),
          if (_busy)
            const Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Color(0x22000000),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
