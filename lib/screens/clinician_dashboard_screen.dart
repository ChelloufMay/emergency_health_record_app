import 'dart:async';

import 'package:flutter/material.dart';

import '../services/access_realtime_service.dart';
import '../utils/patient_access_context.dart';
import 'role_dashboard_screen.dart';

class ClinicianDashboardScreen extends StatefulWidget {
  const ClinicianDashboardScreen({super.key});

  @override
  State<ClinicianDashboardScreen> createState() =>
      _ClinicianDashboardScreenState();
}

class _ClinicianDashboardScreenState extends State<ClinicianDashboardScreen> {
  void _onAccessChanged() {
    if (!mounted) return;
    setState(() {
      // Rebuild so the current permission state is reflected immediately.
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
      key: ValueKey('clinician-dashboard-${access.revision}'),
      title: 'Clinician dashboard',
      subtitle:
          'Patients shown here come from your active access grants. Permission limits are enforced by the active grant.',
      emptyMessage: 'No active clinician access found.',
    );
  }
}
