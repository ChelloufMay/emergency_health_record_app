// placeholder home screen for now
// will be replaced with the actual dashboard once the profile flow is built
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;

  String? _fullName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  // fetches the full name from public.users using the current auth id
  Future<void> _loadUserName() async {
    try {
      final authId = _supabase.auth.currentUser?.id;
      if (authId == null) return;

      final row = await _supabase
          .from('users')
          .select('full_name')
          .eq('auth_user_id', authId)
          .maybeSingle();

      if (row != null && mounted) {
        setState(() => _fullName = row['full_name'] as String?);
      }
    } catch (_) {
      // if the fetch fails we just fall back to the generic greeting
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: Center(
        child: _isLoading
        // show a spinner while we fetch the name
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _fullName != null ? 'Welcome, $_fullName' : 'Welcome',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/profile'),
              child: const Text('My Profile'),
            ),
          ],
        ),
      ),
    );
  }
}