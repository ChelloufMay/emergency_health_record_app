import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'This application stores and processes personal and medical data '
                        'for the purpose of managing a user’s emergency health record.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    'What we collect',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• Account information such as name, email, and role\n'
                        '• Profile and medical data entered by the user\n'
                        '• Access control events and audit logs\n'
                        '• Emergency access records and notifications',
                  ),
                  SizedBox(height: 12),
                  Text(
                    'How data is used',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Data is used to provide account authentication, medical record '
                        'management, caregiver access control, audit logging, emergency '
                        'record viewing, and notification delivery.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Data storage',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'The app uses Supabase for backend storage and access control. '
                        'Medical and account data are protected using the project’s database '
                        'policies and authenticated access rules.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Account deletion',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Users can request account deletion from the settings screen. '
                        'The request is sent to the administrator for review.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Contact',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'For privacy questions, contact the administrator.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}