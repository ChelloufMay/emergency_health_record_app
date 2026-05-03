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
  String? _patientSex;

  @override
  void initState() { super.initState(); _loadUserInfo(); }

  Future<void> _loadUserInfo() async {
    try {
      final authId = _supabase.auth.currentUser?.id;
      if (authId == null) return;

      final userRow = await _supabase.from('users').select('id, full_name').eq('auth_user_id', authId).maybeSingle();
      if (userRow == null) return;
      _fullName = userRow['full_name'] as String?;

      final profileRow = await _supabase.from('patient_profiles').select('id, sex').eq('user_id', userRow['id']).maybeSingle();
      if (mounted) {
        setState(() {
          _hasProfile = profileRow != null;
          _patientSex = profileRow?['sex'] as String?;
        });
      }
    } catch (_) {
      // not critical
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(onPressed: _signOut, icon: const Icon(Icons.logout), tooltip: 'Sign out'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _fullName != null ? 'Welcome, $_fullName' : 'Welcome',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            if (!_hasProfile) ...[
              const SizedBox(height: 4),
              const Text('Start by completing your profile.', style: TextStyle(color: Colors.grey)),
            ],
            const SizedBox(height: 24),

            // ------------------------------- Quick access -------------------------------
            const Text('Quick Access', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10, mainAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: [
                _NavCard(icon: Icons.person_outline, label: 'My Profile', onTap: () => Navigator.pushNamed(context, '/profile')),
                _NavCard(icon: Icons.summarize_outlined, label: 'Medical Summary', onTap: () => Navigator.pushNamed(context, '/medical_summary')),
                _NavCard(icon: Icons.emergency_outlined, label: 'Emergency View', onTap: () => Navigator.pushNamed(context, '/emergency')),
                _NavCard(icon: Icons.qr_code, label: 'Emergency QR', onTap: () => Navigator.pushNamed(context, '/qr')),
                _NavCard(icon: Icons.people_outline, label: 'Caregivers', onTap: () => Navigator.pushNamed(context, '/caregivers')),
                _NavCard(icon: Icons.history, label: 'Audit Log', onTap: () => Navigator.pushNamed(context, '/audit_log')),
                _NavCard(icon: Icons.settings_outlined, label: 'Settings', onTap: () => Navigator.pushNamed(context, '/settings')),
              ],
            ),

            const SizedBox(height: 24),

            // ------------------------------- Medical data entry -------------------------------
            const Text('Medical Records', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10, mainAxisSpacing: 10,
              children: [
                _NavCard(icon: Icons.warning_amber, label: 'Allergies', onTap: () => Navigator.pushNamed(context, '/allergies'), compact: true),
                _NavCard(icon: Icons.medication, label: 'Medications', onTap: () => Navigator.pushNamed(context, '/medications'), compact: true),
                _NavCard(icon: Icons.local_hospital, label: 'Conditions', onTap: () => Navigator.pushNamed(context, '/conditions'), compact: true),
                _NavCard(icon: Icons.cut, label: 'Surgeries', onTap: () => Navigator.pushNamed(context, '/surgeries'), compact: true),
                _NavCard(icon: Icons.bed_outlined, label: 'Hospitalizations', onTap: () => Navigator.pushNamed(context, '/hospitalizations'), compact: true),
                _NavCard(icon: Icons.vaccines, label: 'Vaccinations', onTap: () => Navigator.pushNamed(context, '/vaccinations'), compact: true),
                _NavCard(icon: Icons.self_improvement, label: 'Lifestyle', onTap: () => Navigator.pushNamed(context, '/lifestyle'), compact: true),
                _NavCard(icon: Icons.family_restroom, label: 'Family History', onTap: () => Navigator.pushNamed(context, '/family_history'), compact: true),
                // only show reproductive health for non-male patients
                if (_patientSex != 'male')
                  _NavCard(icon: Icons.pregnant_woman, label: 'Repro. Health', onTap: () => Navigator.pushNamed(context, '/reproductive_health'), compact: true),
                _NavCard(icon: Icons.person_search, label: 'Family Doctor', onTap: () => Navigator.pushNamed(context, '/family_doctor'), compact: true),
                _NavCard(icon: Icons.attach_file, label: 'Attachments', onTap: () => Navigator.pushNamed(context, '/attachments'), compact: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;

  const _NavCard({required this.icon, required this.label, required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: compact ? 24 : 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: compact ? 11 : 13)),
          ],
        ),
      ),
    );
  }
}