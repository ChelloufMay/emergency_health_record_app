import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/access_service.dart';
import '../services/patient_service.dart';
import 'access_dashboard_screen.dart';
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
  final AccessService _accessService = AccessService();

  late Future<Widget> _decisionFuture;

  @override
  void initState() {
    super.initState();
    _decisionFuture = _decide();
  }

  Future<Widget> _decide() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return const LoginScreen();

    final identity = await _patientService.resolveIdentity();
    if (identity == null) return const LoginScreen();

    if (identity.hasPatientProfile) {
      return const HomeScreen();
    }

    final accessRows = await _accessService.fetchMyAccessDashboardRows();
    if (accessRows.isNotEmpty) {
      return const AccessDashboardScreen();
    }

    if (identity.hasCaregiverProfile ||
        identity.hasGuardianProfile ||
        identity.hasClinicianProfile) {
      return const CaregiverChoiceScreen();
    }

    return const CaregiverChoiceScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _decisionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const LoginScreen();
        }

        return snapshot.data ?? const LoginScreen();
      },
    );
  }
}