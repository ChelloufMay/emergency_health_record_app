import 'package:flutter/material.dart';

import 'role_dashboard_screen.dart';

class CaregiverDashboardScreen extends StatelessWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleDashboardScreen(
      title: 'Caregiver dashboard',
      subtitle:
      'Patients shown here come from the access view. Editable sections depend on the current grant permission.',
      emptyMessage: 'No active caregiver access found.',
    );
  }
}