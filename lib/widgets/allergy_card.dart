import 'package:flutter/material.dart';
import '../models/allergy_model.dart';
import 'verification_badge.dart';

class AllergyCard extends StatelessWidget {
  final AllergyModel allergy;
  final VoidCallback? onDelete;

  const AllergyCard({
    super.key,
    required this.allergy,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Row(
          children: [
            Expanded(child: Text(allergy.allergenName)),
            const SizedBox(width: 8),
            VerificationBadge(status: allergy.source == 'clinician' ? 'clinician_verified' : allergy.source == 'caregiver' ? 'caregiver_entered' : 'user_entered'),
          ],
        ),
        subtitle: Text(
          '${allergy.allergyType}${allergy.severity != null && allergy.severity!.isNotEmpty ? ' • ${allergy.severity}' : ''}'
              '${allergy.reaction != null && allergy.reaction!.isNotEmpty ? '\n${allergy.reaction}' : ''}',
        ),
        isThreeLine: true,
        trailing: onDelete == null
            ? null
            : IconButton(
          icon: const Icon(Icons.delete),
          onPressed: onDelete,
        ),
      ),
    );
  }
}