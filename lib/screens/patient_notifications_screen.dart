import 'package:flutter/material.dart';

import '../models/notification_event_model.dart';
import '../services/notification_event_service.dart';
import '../services/patient_service.dart';
import '../services/patient_session_service.dart';

class PatientNotificationsScreen extends StatefulWidget {
  final String? patientId;

  const PatientNotificationsScreen({
    super.key,
    this.patientId,
  });

  @override
  State<PatientNotificationsScreen> createState() =>
      _PatientNotificationsScreenState();
}

class _PatientNotificationsScreenState
    extends State<PatientNotificationsScreen> {
  final NotificationEventService _service = NotificationEventService();
  final PatientService _patientService = PatientService();

  bool _loading = true;
  String? _error;
  String? _patientId;
  List<NotificationEventModel> _events = [];
  bool _showOnlyPending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  Future<String?> _resolvePatientId() async {
    if (widget.patientId != null && widget.patientId!.trim().isNotEmpty) {
      return widget.patientId!.trim();
    }

    final session = PatientSessionService.instance.current;
    if (session?.patientId.isNotEmpty == true) return session!.patientId;

    final identity = await _patientService.resolveIdentity();
    return identity?.patientProfileId;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final patientId = await _resolvePatientId();
      if (patientId == null || patientId.isEmpty) {
        setState(() {
          _error = 'No patient selected.';
          _loading = false;
        });
        return;
      }

      final list = await _service.fetchByPatient(patientId);
      if (!mounted) return;
      setState(() {
        _patientId = patientId;
        _events = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load notifications: $e';
        _loading = false;
      });
    }
  }

  Widget _buildEventCard(NotificationEventModel event) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.eventType,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Chip(
                  label: Text(event.isSent ? 'Sent' : 'Pending'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Message: ${event.message}'),
            const SizedBox(height: 4),
            Text('Channel: ${event.deliveryChannel}'),
            if ((event.recipientEmail ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Recipient email: ${event.recipientEmail}'),
            ],
            if ((event.recipientUserId ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Recipient user ID: ${event.recipientUserId}'),
            ],
            if ((event.entityType ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Entity: ${event.entityType} / ${event.entityId ?? '-'}'),
            ],
            const SizedBox(height: 4),
            Text('Created: ${_formatDateTime(event.createdAt)}'),
            if (event.sentAt != null) ...[
              const SizedBox(height: 4),
              Text('Sent: ${_formatDateTime(event.sentAt)}'),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleEvents = _showOnlyPending
        ? _events.where((event) => !event.isSent).toList()
        : _events;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show only pending notifications'),
              value: _showOnlyPending,
              onChanged: (value) =>
                  setState(() => _showOnlyPending = value),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Notification timeline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text('${visibleEvents.length} shown'),
              ],
            ),
            const SizedBox(height: 12),
            if (visibleEvents.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Text('No notifications yet.'),
                ),
              )
            else
              ...visibleEvents.map(_buildEventCard),
          ],
        ),
      ),
    );
  }
}
