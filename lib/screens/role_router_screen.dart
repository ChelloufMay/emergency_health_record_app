import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/patient_session_service.dart';
import 'caregiver_choice_screen.dart';
import 'caregiver_profile_screen.dart';
import 'clinician_choice_screen.dart'; // NEW
import 'clinician_profile_screen.dart';
import 'guardian_choice_screen.dart'; // NEW
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
      return const LoginScreen();
    }

    final userRow = await client
        .from('users')
        .select('id, role')
        .eq('auth_user_id', authUser.id)
        .maybeSingle();

    if (userRow == null) {
      return const LoginScreen();
    }

    final role = (userRow['role'] as String?) ?? 'owner';

    if (role == 'owner') {
      final patientProfile = await client
          .from('patient_profiles')
          .select('id, first_name, family_name')
          .eq('user_id', userRow['id'])
          .maybeSingle();

      if (patientProfile == null) {
        return const ProfileScreen();
      }

      final first = (patientProfile['first_name']?.toString() ?? '').trim();
      final last = (patientProfile['family_name']?.toString() ?? '').trim();
      final fullName = '$first $last'.trim();

      PatientSessionService.instance.setSession(
        patientId: patientProfile['id'].toString(),
        patientName: fullName.isEmpty ? null : fullName,
        permission: 'owner',
      );

      return const HomeScreen();
    }

    if (role == 'caregiver') {
      final caregiverProfile = await client
          .from('caregiver_profiles')
          .select('id')
          .eq('user_id', userRow['id'])
          .maybeSingle();

      if (caregiverProfile == null) {
        return const CaregiverProfileScreen();
      }

      // CHANGED: caregiver lands on caregiver hub.
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

      // CHANGED: guardian lands on guardian hub.
      return const GuardianChoiceScreen();
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

      // CHANGED: clinician lands on clinician hub.
      return const ClinicianChoiceScreen();
    }

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

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => destination),
          );
        });

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}