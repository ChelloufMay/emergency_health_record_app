import 'package:flutter/material.dart';
import '../models/medication_model.dart';
import 'verification_badge.dart';

class MedicationCard extends StatelessWidget {
  final MedicationModel medication;
  final VoidCallback? onDelete;

  const MedicationCard({
    super.key,
    required this.medication,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Row(
          children: [
            Expanded(child: Text(medication.medicationName)),
            const SizedBox(width: 8),
            VerificationBadge(status: medication.source == 'clinician' ? 'clinician_verified' : medication.source == 'caregiver' ? 'caregiver_entered' : 'user_entered'),
          ],
        ),
        subtitle: Text(
          '${medication.dosage ?? ''}${medication.frequency != null && medication.frequency!.isNotEmpty ? ' • ${medication.frequency}' : ''}'
              '${medication.purpose != null && medication.purpose!.isNotEmpty ? '\n${medication.purpose}' : ''}',
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