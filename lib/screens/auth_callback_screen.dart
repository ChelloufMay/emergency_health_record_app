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
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (!mounted || _handled) return;
    _handled = true;

    final client = Supabase.instance.client;
    final session = client.auth.currentSession;

    if (session != null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/reset-password');
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}