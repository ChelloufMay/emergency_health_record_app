// Legacy screen for caregiver management.
// Redirects to PatientAccessManagementScreen.
import 'package:flutter/material.dart';

import 'patient_access_management_screen.dart';

@Deprecated('Use /patient_access_management instead')
class CaregiverScreen extends StatelessWidget {
  const CaregiverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PatientAccessManagementScreen();
  }
}
