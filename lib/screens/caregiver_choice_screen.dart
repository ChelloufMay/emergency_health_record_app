import 'package:flutter/material.dart';

class CaregiverChoiceScreen extends StatelessWidget {
  const CaregiverChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caregiver area'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choose what you want to open.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Card(
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, '/caregiver_profile'),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 32),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'My profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, '/caregiver_dashboard'),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.dashboard_outlined, size: 32),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Caregiver dashboard',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}