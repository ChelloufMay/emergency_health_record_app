import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/patient_service.dart';
import 'caregiver_choice_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class RoleRouterScreen extends StatefulWidget {
  const RoleRouterScreen({super.key});

  @override
  State<RoleRouterScreen> createState() => _RoleRouterScreenState();
}

class _RoleRouterScreenState extends State<RoleRouterScreen> {
  final PatientService _patientService = PatientService();

  late Future<bool> _hasCaregiverAccessFuture;

  @override
  void initState() {
    super.initState();

    // Check if this logged-in user has caregiver permissions.
    _hasCaregiverAccessFuture =
        _patientService.hasCaregiverPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasCaregiverAccessFuture,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If something fails, safely go to home.
        if (snapshot.hasError) {
          return const HomeScreen();
        }

        // IMPORTANT:
        // Never access _patientService._supabase here.
        // _supabase is private inside PatientService.
        final session =
            Supabase.instance.client.auth.currentSession;

        // No session -> login
        if (session == null) {
          return const LoginScreen();
        }

        final hasCaregiverAccess = snapshot.data ?? false;

        // If the user is also a caregiver,
        // allow them to choose between:
        // 1. Their normal patient account
        // 2. Their caregiver profile
        // 3. Their caregiver dashboard
        if (hasCaregiverAccess) {
          return const CaregiverChoiceScreen();
        }

        // Normal user account
        return const HomeScreen();
      },
    );
  }
}