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
  late Future<_RouterDecision> _decisionFuture;

  @override
  void initState() {
    super.initState();
    _decisionFuture = _decide();
  }

  Future<_RouterDecision> _decide() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return _RouterDecision.login();

    final hasPatient = await _patientService.hasPatientProfile();
    final hasCaregiver = await _patientService.hasCaregiverProfile();
    final hasGuardian = await _patientService.hasGuardianProfile();
    final hasClinician = await _patientService.hasClinicianProfile();
    final hasAccess = await _patientService.hasAnyAccessGrant();

    final hasMultiplePersonas =
    [hasCaregiver, hasGuardian, hasClinician, hasAccess].contains(true);

    if (hasMultiplePersonas) {
      return _RouterDecision.personaChoice();
    }

    if (hasPatient) {
      return _RouterDecision.home();
    }

    return _RouterDecision.home();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RouterDecision>(
      future: _decisionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const HomeScreen();
        }

        final decision = snapshot.data ?? _RouterDecision.home();

        if (decision.type == _RouterDecisionType.login) {
          return const LoginScreen();
        }

        if (decision.type == _RouterDecisionType.personaChoice) {
          return const CaregiverChoiceScreen();
        }

        return const HomeScreen();
      },
    );
  }
}

enum _RouterDecisionType { login, home, personaChoice }

class _RouterDecision {
  final _RouterDecisionType type;
  const _RouterDecision(this.type);

  factory _RouterDecision.login() => const _RouterDecision(_RouterDecisionType.login);
  factory _RouterDecision.home() => const _RouterDecision(_RouterDecisionType.home);
  factory _RouterDecision.personaChoice() =>
      const _RouterDecision(_RouterDecisionType.personaChoice);
}