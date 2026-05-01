// creates a new account
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  final _supabase = Supabase.instance.client;

  Future<void> _signUp() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // basic check before even hitting the network
    if (fullName.isEmpty) {
      setState(() => _errorMessage = 'Please enter your full name.');
      return;
    }

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email.');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // create the auth account
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
      );

      final authUser = response.user;

      // when we didn't get a user back
      if (authUser == null) {
        setState(() => _errorMessage = 'Sign up failed. Please try again.');
        return;
      }

      // insert the matching row in public.users: the schema has full_name as NOT NULL and the RLS policies rely on this table existing for the user
      if (response.session != null) {
        await _supabase.from('users').insert({
          'auth_user_id': authUser.id,
          'full_name': fullName,
          'email': email,
          'role': 'owner',
        });

        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
              (route) => false,
        );
      } else {
        // If this happens, check for email confirmation
        setState(() {
          _errorMessage =
          'Account created, but no session was returned. Turn OFF email confirmation in Supabase for development.';
        });
      }

    } on AuthException catch (e) {
      setState(() => _errorMessage = 'Auth error: ${e.message}');

    } on PostgrestException catch (e) {
      setState(() => _errorMessage = 'Database error: ${e.message}');

    } catch (e) {
      setState(() => _errorMessage = 'Unexpected error: $e');

    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _fullNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 24),

            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Create Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}