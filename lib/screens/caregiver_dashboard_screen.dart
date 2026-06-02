import 'dart:async';

import 'package:flutter/material.dart';

import '../services/access_realtime_service.dart';
import '../utils/patient_access_context.dart';
import 'role_dashboard_screen.dart';

// A dashboard screen for the Caregiver role, showing accessible patients.
class CaregiverDashboardScreen extends StatefulWidget {
  // Creates a new CaregiverDashboardScreen instance.
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  void _onAccessChanged() {
    if (!mounted) return;
    setState(() {
      // Rebuild the dashboard so the section list reflects the latest grant.
    });
  }

  @override
  void initState() {
    super.initState();

    // Start the realtime listener once the dashboard is shown.
    unawaited(AccessRealtimeService.instance.subscribe());

    // Rebuild the screen whenever the reactive access context changes.
    PatientAccessContext.instance.addListener(_onAccessChanged);
  }

  @override
  void dispose() {
    PatientAccessContext.instance.removeListener(_onAccessChanged);

    // Balance the subscribe call made in initState.
    unawaited(AccessRealtimeService.instance.unsubscribe());

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final access = PatientAccessContext.instance;

    return RoleDashboardScreen(
      key: ValueKey('caregiver-dashboard-${access.revision}'),
      title: 'Caregiver dashboard',
      subtitle:
          'Patients shown here come from your active access grants. Permission limits are enforced by the active grant.',
      emptyMessage: 'No active caregiver access found.',
    );
  }
}
