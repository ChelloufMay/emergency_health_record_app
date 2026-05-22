import 'package:flutter/material.dart';

import 'role_dashboard_screen.dart';

class GuardianDashboardScreen extends StatelessWidget {
  const GuardianDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleDashboardScreen(
      title: 'Guardian dashboard',
      subtitle:
      'Patients shown here come from the access view. Guardian permissions are enforced by the current grant.',
      emptyMessage: 'No active guardian access found.',
    );
  }
}