import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthCallbackScreen extends StatefulWidget {
  const AuthCallbackScreen({super.key});

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

  Future<void> _handle() async {
    // CHANGED: give Supabase a moment to finish processing the deep link.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (!mounted || _handled) return;
    _handled = true;

    final client = Supabase.instance.client;
    final session = client.auth.currentSession;

    // CHANGED: route based on whether Supabase created a session from the link.
    // Recovery links should land on the password reset screen.
    final targetRoute = session != null ? '/reset-password' : '/login';

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
