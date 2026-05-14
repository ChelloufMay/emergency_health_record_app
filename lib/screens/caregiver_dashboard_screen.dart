import 'package:flutter/material.dart';

class CaregiverDashboardScreen extends StatelessWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caregiver dashboard'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.health_and_safety, size: 64),
              const SizedBox(height: 16),
              const Text(
                'This screen is now a compatibility screen.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Use the access dashboard for patient selection and access management.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pushNamed(context, '/access_dashboard'),
                child: const Text('Go to access dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}