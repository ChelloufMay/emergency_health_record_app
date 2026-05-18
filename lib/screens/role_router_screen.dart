import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'caregiver_choice_screen.dart';
import 'caregiver_dashboard_screen.dart';
import 'caregiver_profile_screen.dart';
import 'clinician_profile_screen.dart';
import 'guardian_profile_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class RoleRouterScreen extends StatefulWidget {
  const RoleRouterScreen({super.key});

  @override
  State<RoleRouterScreen> createState() => _RoleRouterScreenState();
}

class _RoleRouterScreenState extends State<RoleRouterScreen> {
  late Future<Widget> _future;

  @override
  void initState() {
    super.initState();
    _future = _resolveDestination();
  }

  Future<Widget> _resolveDestination() async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    final authUser = session?.user;

    if (authUser == null) {
      // No auth session means no route can be resolved yet.
      return const LoginScreen();
    }

    // The public.users row is the central identity record used by your DB.
    // It stores the app role and links auth.users -> public schema.
    final userRow = await client
        .from('users')
        .select('id, role')
        .eq('auth_user_id', authUser.id)
        .maybeSingle();

    if (userRow == null) {
      // This is the safe fallback when the auth trigger has not populated
      // public.users yet or the row is still being initialized.
      return const LoginScreen();
    }

    final role = (userRow['role'] as String?) ?? 'owner';

    if (role == 'owner') {
      // Owners are routed through patient_profiles.
      // If the patient profile is missing, go to profile setup.
      final patientProfile = await client
          .from('patient_profiles')
          .select('id')
          .eq('user_id', userRow['id'])
          .maybeSingle();

      if (patientProfile == null) {
        return const ProfileScreen();
      }

      return const HomeScreen();
    }

    if (role == 'caregiver') {
      final caregiverProfile = await client
          .from('caregiver_profiles')
          .select('id')
          .eq('user_id', userRow['id'])
          .maybeSingle();

      // Caregivers first need their own profile row; after that they land in the
      // choice/dashboard flow that is tied to access_grants and caregiver_permissions.
      if (caregiverProfile == null) {
        return const CaregiverProfileScreen();
      }

      return const CaregiverChoiceScreen();
    }

    if (role == 'guardian') {
      final guardianProfile = await client
          .from('guardian_profiles')
          .select('id')
          .eq('user_id', userRow['id'])
          .maybeSingle();

      if (guardianProfile == null) {
        return const GuardianProfileScreen();
      }

      // Guardians can still use the shared access dashboard path.
      return const CaregiverDashboardScreen();
    }

    if (role == 'clinician') {
      final clinicianProfile = await client
          .from('clinician_profiles')
          .select('id')
          .eq('user_id', userRow['id'])
          .maybeSingle();

      if (clinicianProfile == null) {
        return const ClinicianProfileScreen();
      }

      // Clinicians also enter through the access/dashboard path in this app.
      return const CaregiverDashboardScreen();
    }

    // Safe fallback for unknown roles.
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Router error: ${snapshot.error}')),
          );
        }

        final destination = snapshot.data ?? const LoginScreen();

        // This screen never stays on top of the stack:
        // it exists only to route the authenticated user into the correct branch.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => destination),
          );
        });

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}