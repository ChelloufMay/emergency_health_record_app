import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DebugLinkScreen extends StatelessWidget {
  const DebugLinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final uri = args?['uri']?.toString() ?? 'No URI received';
    final status = args?['status']?.toString() ?? 'No status';
    final session = Supabase.instance.client.auth.currentSession;
    final currentUser = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Deep link debug')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Callback received',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('URI: $uri'),
            const SizedBox(height: 8),
            Text('Status: $status'),
            const SizedBox(height: 8),
            Text('Session exists: ${session != null ? "yes" : "no"}'),
            const SizedBox(height: 8),
            Text('Current user: ${currentUser?.email ?? "none"}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                      (route) => false,
                );
              },
              child: const Text('Go to home'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                      (route) => false,
                );
              },
              child: const Text('Go to login'),
            ),
          ],
        ),
      ),
    );
  }
}