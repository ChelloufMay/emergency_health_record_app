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
    _hasCaregiverAccessFuture = _patientService.hasCaregiverPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasCaregiverAccessFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          // Safe fallback if the caregiver check fails.
          return const HomeScreen();
        }

        final hasCaregiverAccess = snapshot.data ?? false;

        // Caregivers go to the choice screen first.
        if (hasCaregiverAccess) {
          return const CaregiverChoiceScreen();
        }

        // If there is no session, show login.
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          return const LoginScreen();
        }

        // Otherwise, this is a normal owner account.
        return const HomeScreen();
      },
    );
  }
}