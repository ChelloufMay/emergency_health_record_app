import 'package:flutter/material.dart';
import 'role_dashboard_screen.dart';

class ClinicianDashboardScreen extends StatelessWidget {
  const ClinicianDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleDashboardScreen(
      title: 'Clinician dashboard',
      subtitle:
      'Patients shown here come from the DB access view. Read-only and editable access are enforced by the current grant.',
      emptyMessage: 'No active clinician access found.',
    );
  }
}