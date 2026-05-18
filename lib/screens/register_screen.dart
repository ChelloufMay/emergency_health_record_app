import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'role_router_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Keeping the account creation flexible:
  // the DB defaults role to owner, but this lets the app create a
  // role-aware user row when the user is not a patient owner.
  String _selectedRole = 'owner';

  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final passwordError = _validatePassword(_passwordController.text);
    if (passwordError != null) {
      setState(() {
        _error = passwordError;
        _success = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      final auth = Supabase.instance.client.auth;

      final result = await auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: <String, dynamic>{
          // These land in auth metadata so the trigger can populate public.users.
          'full_name': _fullNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'role': _selectedRole,
        },
      );

      final user = result.user;
      if (user != null) {
        // The DB trigger already creates/updates public.users,
        // but we also update the row here so the chosen role is correct.
        // This keeps users.role in sync with the app branch the router uses.
        await Supabase.instance.client
            .from('users')
            .update({
              'full_name': _fullNameController.text.trim(),
              'phone': _phoneController.text.trim(),
              'role': _selectedRole,
            })
            .eq('auth_user_id', user.id);
      }

      if (!mounted) return;

      setState(() {
        _success =
            'Account created. Continue to sign in if email confirmation is enabled.';
      });

      // If email confirmation is off and the session exists, this takes the user
      // straight into the router. Otherwise they can sign in after confirming.
      if (auth.currentSession != null && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RoleRouterScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Registration failed: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String? _validatePassword(String password) {
    if (password.length <= 8) {
      return 'Password must be more than 8 characters.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter.';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Password must contain at least one number.';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return 'Password must contain at least one symbol.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const roles = <String>['owner', 'caregiver', 'guardian', 'clinician'];

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Create your account',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'The auth user is created first. Profile data is then attached by the router and profile screens.',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              items: roles
                  .map(
                    (role) => DropdownMenuItem(value: role, child: Text(role)),
                  )
                  .toList(),
              onChanged: _loading
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _selectedRole = value);
                      }
                    },
              decoration: const InputDecoration(
                labelText: 'Account role',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            if (_success != null) ...[
              Text(_success!, style: const TextStyle(color: Colors.green)),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _loading ? null : _register,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }
}
