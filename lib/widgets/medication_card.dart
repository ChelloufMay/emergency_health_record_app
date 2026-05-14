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
    required this.canEdit,
    this.onEdit,
    this.onDelete,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final details = <Widget>[
      if (medication.dosage != null && medication.dosage!.isNotEmpty)
        Text('Dosage: ${medication.dosage}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
      if (medication.frequency != null && medication.frequency!.isNotEmpty)
        Text('Frequency: ${medication.frequency}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
      if (medication.purpose != null && medication.purpose!.isNotEmpty)
        Text('Purpose: ${medication.purpose}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
      Text('Start date: ${_formatDate(medication.startDate)}',
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      Text('End date: ${_formatDate(medication.endDate)}',
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      Text('Source: ${medication.source}',
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    medication.medicationName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (canEdit) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: onEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            ...details,
            const SizedBox(height: 6),
            VerificationBadge(status: medication.verificationStatus ?? 'user_entered'),
          ],
        ),
      ),
    );
  }
}
