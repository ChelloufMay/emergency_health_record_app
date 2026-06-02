import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Handles authentication callbacks, such as email confirmation + password recovery redirects.
class AuthCallbackScreen extends StatefulWidget {
  final String? callbackUri;
  final bool isRecovery;

  const AuthCallbackScreen({
    super.key,
    this.callbackUri,
    this.isRecovery = false,
  });

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _handle();
  }

  // Processes the authentication result and redirects the user to the appropriate screen (e.g., password reset or home).
  Future<void> _handle() async {
    // Give Supabase a short moment to finish processing the deep link.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (!mounted || _handled) return;
    _handled = true;

    final client = Supabase.instance.client;
    final session = client.auth.currentSession;

    final uri = widget.callbackUri == null
        ? null
        : Uri.tryParse(widget.callbackUri!);

    final recoveryFromUri = uri?.queryParameters['type'] == 'recovery';
    final shouldResetPassword = widget.isRecovery || recoveryFromUri;

    if (!mounted) return;

    // Only route to password reset for recovery callbacks.
    if (session != null && shouldResetPassword) {
      Navigator.of(context).pushReplacementNamed('/reset-password');
      return;
    }

    // Normal auth callbacks go back into the role router flow.
    if (session != null) {
      Navigator.of(context).pushReplacementNamed('/entry');
      return;
    }

    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
