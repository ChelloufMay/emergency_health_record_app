import 'package:flutter/material.dart';

import '../models/access_inbox_item_model.dart';

/// Reusable invite row for the recipient inbox (accept/reject on pending only).
class AccessInviteCard extends StatelessWidget {
  final AccessInboxItemModel item;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onTap;

  const AccessInviteCard({
    super.key,
    required this.item,
    this.onAccept,
    this.onReject,
    this.onTap,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'caregiver':
        return 'Caregiver';
      case 'guardian':
        return 'Guardian';
      case 'clinician':
        return 'Clinician';
      default:
        return role;
    }
  }

  Color _statusColor(BuildContext context) {
    switch (item.status.toLowerCase()) {
      case 'pending':
        return Theme.of(context).colorScheme.primary;
      case 'accepted':
        return Colors.green.shade700;
      case 'rejected':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showActions =
        item.status.toLowerCase() == 'pending' &&
        item.inviteToken.isNotEmpty;

    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(item.patientName),
        subtitle: Text(
          [
            'Role: ${_roleLabel(item.invitedRole)}',
            'Permission: ${item.permission}',
            if (item.senderLabel != null && item.senderLabel!.isNotEmpty)
              'From: ${item.senderLabel}',
            'When: ${_formatDate(item.eventAt)}',
            if (item.message != null && item.message!.isNotEmpty)
              'Message: ${item.message}',
          ].join('\n'),
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Chip(
              label: Text(
                item.status,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                ),
              ),
              backgroundColor: _statusColor(context),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            if (showActions) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check),
                    tooltip: 'Accept invite',
                  ),
                  IconButton(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    tooltip: 'Reject invite',
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
