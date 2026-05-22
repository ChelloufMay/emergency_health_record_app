import 'dart:async';

import 'package:flutter/material.dart';

import '../models/access_inbox_item_model.dart';
import '../services/access_realtime_service.dart';
import '../services/access_service.dart';
import '../widgets/access_invite_card.dart';

/// Recipient-side inbox: accept or reject incoming invites only.
///
/// Patient owners manage grants on [PatientAccessManagementScreen], not here.
class AccessInboxScreen extends StatefulWidget {
  /// When true, renders body only (for [AccessCenterScreen] tabs).
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load inbox: $e')),
      );
    }
  }

  Future<void> _accept(AccessInboxItemModel item) async {
    if (item.inviteToken.isEmpty) return;
    try {
      await _accessService.acceptInvite(
        item.inviteToken,
        patientId: item.patientId,
        inviteId: item.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite accepted.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not accept invite: $e')),
      );
    }
  }

  Future<void> _reject(AccessInboxItemModel item) async {
    if (item.inviteToken.isEmpty) return;
    try {
      await _accessService.rejectInvite(
        item.inviteToken,
        patientId: item.patientId,
        inviteId: item.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite rejected.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not reject invite: $e')),
      );
    }
  }

  Widget _section({
    required String title,
    required List<AccessInboxItemModel> items,
    required String emptyMessage,
    bool showActions = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(emptyMessage),
            ),
          )
        else
          ...items.map(
            (item) => AccessInviteCard(
              item: item,
              onAccept: showActions ? () => _accept(item) : null,
              onReject: showActions ? () => _reject(item) : null,
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Incoming invites sent to your account. Accepting creates an '
            'active grant; rejecting notifies the patient.',
          ),
          const SizedBox(height: 16),
          _section(
            title: 'Received (pending)',
            items: _pending,
            emptyMessage: 'No pending invites.',
            showActions: true,
          ),
          _section(
            title: 'Accepted',
            items: _accepted,
            emptyMessage: 'No accepted invites yet.',
          ),
          _section(
            title: 'Rejected',
            items: _rejected,
            emptyMessage: 'No rejected invites yet.',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _buildBody();

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
      body: _buildBody(),
    );
  }
}
