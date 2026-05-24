import 'dart:async';

import 'package:flutter/material.dart';

import '../services/access_realtime_service.dart';
import '../utils/patient_access_context.dart';
import 'role_dashboard_screen.dart';

class GuardianDashboardScreen extends StatefulWidget {
  const GuardianDashboardScreen({super.key});

  @override
  State<GuardianDashboardScreen> createState() =>
      _GuardianDashboardScreenState();
}

class _GuardianDashboardScreenState extends State<GuardianDashboardScreen> {
  void _onAccessChanged() {
    if (!mounted) return;
    setState(() {
      // Rebuild so the dashboard reflects the latest permission level.
    });
  }

  @override
  void initState() {
    super.initState();
    unawaited(AccessRealtimeService.instance.subscribe());
    PatientAccessContext.instance.addListener(_onAccessChanged);
  }

  @override
  void dispose() {
    PatientAccessContext.instance.removeListener(_onAccessChanged);
    unawaited(AccessRealtimeService.instance.unsubscribe());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final access = PatientAccessContext.instance;

    return RoleDashboardScreen(
      key: ValueKey('guardian-dashboard-${access.revision}'),
      title: 'Guardian dashboard',
      subtitle:
      'Patients shown here come from your active access grants. Permission limits are enforced by the active grant.',
      emptyMessage: 'No active guardian access found.',
    );
  }
}