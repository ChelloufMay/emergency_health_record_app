import 'package:flutter/material.dart';
import '../models/medication_model.dart';
import 'verification_badge.dart';

class MedicationCard extends StatelessWidget {
  final MedicationModel medication;
  final bool canEdit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MedicationCard({
    super.key,
    required this.medication,
    this.canEdit = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final badge = medication.verificationStatus ?? 'user_entered';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(medication.medicationName, style: const TextStyle(fontWeight: FontWeight.bold))),
                VerificationBadge(status: badge),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${medication.dosage ?? ''}'
                  '${medication.frequency != null && medication.frequency!.isNotEmpty ? ' • ${medication.frequency}' : ''}'
                  '${medication.purpose != null && medication.purpose!.isNotEmpty ? '\n${medication.purpose}' : ''}',
            ),
            if (canEdit) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: onEdit,
                    child: const Text('Edit'),
                  ),
                  TextButton(
                    onPressed: onDelete,
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}