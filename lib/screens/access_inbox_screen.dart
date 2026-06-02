import 'dart:async';

import 'package:flutter/material.dart';

import '../models/access_inbox_item_model.dart';
import '../services/access_realtime_service.dart';
import '../services/access_service.dart';

// Recipient-side inbox with three tabs: Received (pending), Accepted, and Rejected.

// Pending items can be accepted or rejected from here.
class AccessInboxScreen extends StatefulWidget {
  // When true, renders body only for embedded tab layouts.
  final bool embedded;

  const AccessInboxScreen({super.key, this.embedded = false});

  @override
  State<AccessInboxScreen> createState() => _AccessInboxScreenState();
}

class _AccessInboxScreenState extends State<AccessInboxScreen> {
  final AccessService _accessService = AccessService();
  StreamSubscription<void>? _realtimeSub;

  bool _loading = true;
  List<AccessInboxItemModel> _pending = [];
  List<AccessInboxItemModel> _accepted = [];
  List<AccessInboxItemModel> _rejected = [];

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRealtime();
  }

  // Subscribes to real-time updates for the inbox items.
  void _subscribeRealtime() {
    AccessRealtimeService.instance.subscribe();
    _realtimeSub = AccessRealtimeService.instance.onChanged.listen((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    AccessRealtimeService.instance.unsubscribe();
    super.dispose();
  }

  // Fetches pending, accepted, and rejected invitations from the server.
  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);

    try {
      final results = await Future.wait([
        _accessService.fetchMyInboxPending(),
        _accessService.fetchMyInboxAccepted(),
        _accessService.fetchMyInboxRejected(),
      ]);

      if (!mounted) return;
      setState(() {
        _pending = results[0];
        _accepted = results[1];
        _rejected = results[2];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load inbox: $e')));
    }
  }

  // Accepts a specific invitation and refreshes the list.
  Future<void> _accept(AccessInboxItemModel item) async {
    if (item.inviteToken.isEmpty) return;

    try {
      await _accessService.acceptInvite(
        item.inviteToken,
        patientId: item.patientId,
        inviteId: item.id,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invite accepted.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not accept invite: $e')));
    }
  }

  // Rejects a specific invitation and refreshes the list.
  Future<void> _reject(AccessInboxItemModel item) async {
    if (item.inviteToken.isEmpty) return;

    try {
      await _accessService.rejectInvite(
        item.inviteToken,
        patientId: item.patientId,
        inviteId: item.id,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invite rejected.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not reject invite: $e')));
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  String _prettyText(String value) {
    final cleaned = value.replaceAll('_', ' ').trim();
    if (cleaned.isEmpty) return '-';
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  String _senderName(AccessInboxItemModel item) {
    final label = item.senderLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    return 'Unknown sender';
  }

  Widget _statusChip(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
    final text = status.toLowerCase().trim();

    Color background;
    Color foreground;

    switch (text) {
      case 'pending':
        background = scheme.primaryContainer;
        foreground = scheme.onPrimaryContainer;
        break;
      case 'accepted':
        background = scheme.secondaryContainer;
        foreground = scheme.onSecondaryContainer;
        break;
      case 'rejected':
        background = scheme.errorContainer;
        foreground = scheme.onErrorContainer;
        break;
      default:
        background = scheme.surfaceContainerHighest;
        foreground = scheme.onSurfaceVariant;
    }

    return Chip(
      label: Text(_prettyText(text), style: TextStyle(color: foreground)),
      backgroundColor: background,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _inviteCard(
    BuildContext context, {
    required AccessInboxItemModel item,
    required bool showActions,
  }) {
    final message = item.message?.trim();
    final sender = _senderName(item);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    sender,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _statusChip(context, item.status),
              ],
            ),
            const SizedBox(height: 10),
            Text('Role assigned: ${_prettyText(item.invitedRole)}'),
            const SizedBox(height: 4),
            Text('Permission: ${_prettyText(item.permission)}'),
            const SizedBox(height: 4),
            Text('Timestamp: ${_formatDate(item.eventAt)}'),
            const SizedBox(height: 4),
            Text('Patient: ${item.patientName}'),
            if (message != null && message.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Message',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(message),
            ],
            if (showActions) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _accept(item),
                    icon: const Icon(Icons.check),
                    label: const Text('Accept'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _reject(item),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String emptyMessage,
    required List<AccessInboxItemModel> items,
    required bool showActions,
  }) {
    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [_emptyCard(emptyMessage)],
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...items.map(
            (item) =>
                _inviteCard(context, item: item, showActions: showActions),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: const TabBar(
              tabs: [
                Tab(text: 'Received'),
                Tab(text: 'Accepted'),
                Tab(text: 'Rejected'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildSection(
                  context: context,
                  emptyMessage: 'No pending invites.',
                  items: _pending,
                  showActions: true,
                ),
                _buildSection(
                  context: context,
                  emptyMessage: 'No accepted invites yet.',
                  items: _accepted,
                  showActions: false,
                ),
                _buildSection(
                  context: context,
                  emptyMessage: 'No rejected invites yet.',
                  items: _rejected,
                  showActions: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invites inbox'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: body,
    );
  }
}
