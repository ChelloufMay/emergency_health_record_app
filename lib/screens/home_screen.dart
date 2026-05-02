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
  bool _hasProfile = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final authId = _supabase.auth.currentUser?.id;
      if (authId == null) return;

      final userRow = await _supabase
          .from('users')
          .select('id, full_name')
          .eq('auth_user_id', authId)
          .maybeSingle();

      if (userRow == null) return;

      _fullName = userRow['full_name'] as String?;

      // check if the user already has a patient profile
      final profileRow = await _supabase
          .from('patient_profiles')
          .select('id')
          .eq('user_id', userRow['id'])
          .maybeSingle();

      if (mounted) {
        setState(() => _hasProfile = profileRow != null);
      }
    } catch (_) {
      // not critical --> just falls back to generic greeting
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _fullName != null ? 'Welcome, $_fullName' : 'Welcome',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),

            // nudge the user to fill their profile if they haven't yet
            if (!_hasProfile) ...[
              const SizedBox(height: 6),
              const Text(
                'Start by filling in your medical profile.',
                style: TextStyle(color: Colors.grey),
              ),
            ],

            const SizedBox(height: 24),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              // disable grid's own scrolling since we're inside SingleChildScrollView
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _NavCard(
                  icon: Icons.person_outline,
                  label: 'My Profile',
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                ),
                _NavCard(
                  icon: Icons.medical_services_outlined,
                  label: 'Medical Summary',
                  onTap: () =>
                      Navigator.pushNamed(context, '/medical_summary'),
                ),
                _NavCard(
                  icon: Icons.emergency_outlined,
                  label: 'Emergency View',
                  onTap: () =>
                      Navigator.pushNamed(context, '/emergency'),
                ),
                _NavCard(
                  icon: Icons.qr_code,
                  label: 'Emergency QR',
                  onTap: () => Navigator.pushNamed(context, '/qr'),
                ),
                _NavCard(
                  icon: Icons.people_outline,
                  label: 'Caregivers',
                  onTap: () =>
                      Navigator.pushNamed(context, '/caregivers'),
                ),
                _NavCard(
                  icon: Icons.history,
                  label: 'Audit Log',
                  onTap: () =>
                      Navigator.pushNamed(context, '/audit_log'),
                ),
                _NavCard(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () =>
                      Navigator.pushNamed(context, '/settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// reusable card used in the navigation grid
class _NavCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}