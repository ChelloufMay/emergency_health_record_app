import 'package:flutter/material.dart';
import '../models/allergy_model.dart';
import 'verification_badge.dart';

class AllergyCard extends StatelessWidget {
  final AllergyModel allergy;
  final bool canEdit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AllergyCard({
    super.key,
    required this.allergy,
    this.canEdit = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final badge = allergy.verificationStatus ?? 'user_entered';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    allergy.allergenName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                VerificationBadge(status: badge),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${allergy.allergyType}'
              '${allergy.severity != null && allergy.severity!.isNotEmpty ? ' • ${allergy.severity}' : ''}'
              '${allergy.reaction != null && allergy.reaction!.isNotEmpty ? '\n${allergy.reaction}' : ''}',
            ),
            if (canEdit) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(onPressed: onEdit, child: const Text('Edit')),
                  TextButton(onPressed: onDelete, child: const Text('Delete')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
