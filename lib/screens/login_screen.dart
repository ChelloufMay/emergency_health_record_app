// user sign in with email and password.
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // controllers to read what the user typed in each field
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // shortcut to not write Supabase.instance.client everywhere
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // so that if user navigates away the context isn't touched
      if (!mounted) return;
      // clear navigation stack so as to not go back to login
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } on AuthException catch (e) {
      // Supabase's error message
      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      // catch-all for network errors, timeouts, etc.
      setState(() {
        _errorMessage = 'Something went wrong while signing in.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
            ),
            // only show the error text if there actually is one
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // disabling the button while loading
                onPressed: _isLoading ? null : _signIn,
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Sign In'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}