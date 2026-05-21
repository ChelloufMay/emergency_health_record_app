import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  String? _fullName;
  String? _email;
  String? _role;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) return;

      final row = await _supabase
          .from('users')
          .select('full_name, email, role')
          .eq('auth_user_id', authUser.id)
          .maybeSingle();

      if (row != null && mounted) {
        setState(() {
          _fullName = row['full_name']?.toString();
          _email = row['email']?.toString() ?? authUser.email;
          _role = row['role']?.toString();
        });
      }
    } catch (e) {
      debugPrint('Settings load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscurePassword = true;
    bool obscureConfirm = true;
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              setDialogState(() => saving = true);

              try {
                await _authService.updatePassword(passwordController.text.trim());
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                _showSnack('Password updated successfully.');
              } catch (e) {
                setDialogState(() => saving = false);
                _showSnack('Could not update password: $e', error: true);
              }
            }

            return AlertDialog(
              title: const Text('Change password'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'New password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return 'Enter a new password';
                          if (v.length < 8) return 'Use at least 8 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmController,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm new password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                obscureConfirm = !obscureConfirm;
                              });
                            },
                            icon: Icon(
                              obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return 'Confirm your password';
                          if (v != passwordController.text.trim()) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving ? null : submit,
                  child: saving
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Update password'),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();
    confirmController.dispose();
  }

  Future<void> _sendRecoveryEmail() async {
    final email = _email?.trim();
    if (email == null || email.isEmpty) {
      _showSnack('No email found for this account.', error: true);
      return;
    }

    try {
      await _authService.sendPasswordResetEmail(email: email);
      _showSnack('Password reset email sent.');
    } catch (e) {
      _showSnack('Could not send recovery email: $e', error: true);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await _confirm(
      title: 'Sign out',
      message: 'Are you sure you want to sign out?',
      confirmLabel: 'Sign out',
      destructive: false,
    );
    if (!confirmed) return;

    await _authService.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<void> _requestAccountDeletion() async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request account deletion'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This will send an email request to the administrator. '
                    'Your account will not be deleted immediately from this screen.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Optional reason',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Send request'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      reasonController.dispose();
      return;
    }

    try {
      final result = await _supabase.rpc(
        'request_account_deletion',
        params: {
          '_reason': reasonController.text.trim().isEmpty
              ? null
              : reasonController.text.trim(),
        },
      );

      _showSnack(
        'Deletion request sent to the administrator.',
      );

      debugPrint('Delete request queued: $result');
    } catch (e) {
      _showSnack(
        'Could not send deletion request: $e',
        error: true,
      );
    } finally {
      reasonController.dispose();
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    required bool destructive,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: destructive
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  Widget _sectionHeader(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
    Widget? trailing,
  }) =>
      ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          title,
          style: TextStyle(color: titleColor),
        ),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
        onTap: onTap,
      );

  Widget _divider() => const Divider(height: 1, indent: 56);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
            child: Card(
              elevation: 0,
              color: cs.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: cs.primary,
                      child: Text(
                        _initials(_fullName ?? _email ?? '?'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fullName ?? 'No name set',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _email ?? '',
                            style: TextStyle(
                              color: cs.onPrimaryContainer.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 13,
                            ),
                          ),
                          if (_role != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _role!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: cs.primary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _sectionHeader('Profile'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: Column(
              children: [
                _tile(
                  icon: Icons.person_outline,
                  title: 'Edit profile',
                  subtitle: 'Update your personal profile',
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                ),
                _divider(),
                _tile(
                  icon: Icons.medical_information_outlined,
                  title: 'Medical summary',
                  subtitle: 'Allergies, medications, conditions',
                  onTap: () =>
                      Navigator.pushNamed(context, '/medical_summary'),
                ),
                _divider(),
                _tile(
                  icon: Icons.qr_code_outlined,
                  title: 'My emergency QR',
                  subtitle: 'View or share your emergency card',
                  onTap: () => Navigator.pushNamed(context, '/qr'),
                ),
              ],
            ),
          ),
          _sectionHeader('Access & Caregivers'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: Column(
              children: [
                _tile(
                  icon: Icons.people_outline,
                  title: 'Caregivers',
                  subtitle: 'Manage who can view or edit your record',
                  onTap: () => Navigator.pushNamed(context, '/caregivers'),
                ),
                _divider(),
                _tile(
                  icon: Icons.history_outlined,
                  title: 'Actions performed',
                  subtitle: 'See all access and edit events',
                  onTap: () => Navigator.pushNamed(context, '/audit_log'),
                ),
              ],
            ),
          ),
          _sectionHeader('Security'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: Column(
              children: [
                _tile(
                  icon: Icons.lock_reset_outlined,
                  title: 'Change password',
                  subtitle: 'Open a dialog and update your password now',
                  onTap: _showChangePasswordDialog,
                ),
                _divider(),
                _tile(
                  icon: Icons.email_outlined,
                  title: 'Send password recovery email',
                  subtitle: 'Send a reset link to the current email',
                  onTap: _sendRecoveryEmail,
                ),
                _divider(),
                _tile(
                  icon: Icons.shield_outlined,
                  title: 'Data protection',
                  subtitle: 'Protected by Supabase Auth + RLS',
                  trailing: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          _sectionHeader('About'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: Column(
              children: [
                _tile(
                  icon: Icons.info_outline,
                  title: 'App version',
                  subtitle: '1.0.0 — MVP',
                  trailing: const SizedBox.shrink(),
                ),
                _divider(),
                _tile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy policy',
                  subtitle: 'How your data is protected',
                  onTap: () => _showSnack(
                    'Privacy policy — coming in a future version.',
                  ),
                ),
                _divider(),
                _tile(
                  icon: Icons.description_outlined,
                  title: 'Terms of use',
                  subtitle:
                  'This app supplements but does not replace clinical records',
                  onTap: () => _showSnack(
                    'Terms of use — coming in a future version.',
                  ),
                ),
              ],
            ),
          ),
          _sectionHeader('Account'),
          Card(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: Column(
              children: [
                _tile(
                  icon: Icons.logout,
                  title: 'Sign out',
                  iconColor: cs.error,
                  titleColor: cs.error,
                  trailing: const SizedBox.shrink(),
                  onTap: _signOut,
                ),
                _divider(),
                _tile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Delete account',
                  subtitle: 'Send a deletion request to the administrator',
                  iconColor: cs.error,
                  titleColor: cs.error,
                  onTap: _requestAccountDeletion,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }
}
