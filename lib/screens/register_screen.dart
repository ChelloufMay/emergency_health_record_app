import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  Future<void> _signUp() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (fullName.isEmpty) {
      setState(() {
        _message = 'Please enter your full name.';
        _isSuccess = false;
      });
      return;
    }

    if (email.isEmpty) {
      setState(() {
        _message = 'Please enter your email.';
        _isSuccess = false;
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _message = 'Password must be at least 6 characters.';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone.isEmpty ? null : phone,
      );

      if (!mounted) return;

      // If email confirmation is disabled in Supabase, a session may exist
      // immediately and the auth listener in main.dart will send the user home.
      // If confirmation is enabled, the user must open the email link first.
      final hasSession = response.session != null;

      setState(() {
        _isSuccess = true;
        _message = hasSession
            ? 'Account created. You are signed in and will be redirected.'
            : 'Account created! Check your email and tap the confirmation link to continue.';
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSuccess = false;
        _message = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSuccess = false;
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
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
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone (optional)',
                hintText: '+216 XX XXX XXX',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 24),
            if (_message != null) ...[
              Text(
                _message!,
                style: TextStyle(
                  color: _isSuccess ? Colors.green.shade700 : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || _isSuccess ? null : _signUp,
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Create Account'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
              child: const Text('Already have an account? Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}