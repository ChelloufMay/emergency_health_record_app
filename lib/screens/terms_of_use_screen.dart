import 'package:flutter/material.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Use'),
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
                    'Terms of Use',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'By using this application, you agree to use it only for lawful and '
                        'appropriate personal, caregiver, or clinical record management.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '1. Purpose of the app',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'The app is designed to store and organize emergency health records, '
                        'medical history, access permissions, and related notifications.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '2. User responsibility',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Users are responsible for the accuracy of the data they enter and '
                        'for protecting access to their account.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '3. Access and sharing',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Users may grant access to caregivers or clinicians as allowed by the '
                        'app’s access system and rules.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '4. Medical disclaimer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'This application supports record management and does not replace '
                        'professional medical advice, diagnosis, or treatment.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '5. Account termination',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'The administrator may review deletion requests or take action when '
                        'required by the project rules or backend policies.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '6. Changes to these terms',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'These terms may be updated as the project evolves.',
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