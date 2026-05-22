import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_event_model.dart';

/// Reads and optionally writes `notification_events` for access lifecycle gaps.
///
/// Postgres RPCs normally create rows; gap methods run only when
/// [hasRecentEvent] finds no matching server row.
class NotificationEventService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String eventInviteAccepted = 'access_invite_accepted';
  static const String eventInviteRejected = 'access_invite_rejected';
  static const String eventPermissionUpdated = 'access_permission_updated';
  static const String eventGrantRevoked = 'access_grant_revoked';

  static const List<String> accessEventTypes = [
    eventInviteAccepted,
    eventInviteRejected,
    eventPermissionUpdated,
    eventGrantRevoked,
  ];

  Future<List<NotificationEventModel>> fetchByPatient(String patientId) async {
    final rows = await _supabase
        .from('notification_events')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map(
          (row) => NotificationEventModel.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<List<NotificationEventModel>> fetchPendingByPatient(
    String patientId,
  ) async {
    final rows = await _supabase
        .from('notification_events')
        .select()
        .eq('patient_id', patientId)
        .eq('is_sent', false)
        .order('created_at', ascending: false);

    return (rows as List)
        .map(
          (row) => NotificationEventModel.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<List<NotificationEventModel>> fetchAccessRelatedForPatient(
    String patientId,
  ) async {
    final all = await fetchByPatient(patientId);
    return all
        .where(
          (e) =>
              accessEventTypes.contains(e.eventType) ||
              e.eventType.startsWith('access_'),
        )
        .toList();
  }

  /// Returns true if a matching event was created within [withinSeconds].
  Future<bool> hasRecentEvent({
    required String patientId,
    required String eventType,
    String? entityId,
    int withinSeconds = 30,
  }) async {
    final since = DateTime.now().toUtc().subtract(
      Duration(seconds: withinSeconds),
    );

    var query = _supabase
        .from('notification_events')
        .select('id')
        .eq('patient_id', patientId)
        .eq('event_type', eventType)
        .gte('created_at', since.toIso8601String());

    if (entityId != null && entityId.trim().isNotEmpty) {
      query = query.eq('entity_id', entityId.trim());
    }

    final rows = await query.limit(1);
    return rows.isNotEmpty;
  }

  Future<void> _insertGapEvent(NotificationEventModel event) async {
    await _supabase.from('notification_events').insert(event.toInsertMap());
  }

  Future<void> recordInviteAcceptedIfNeeded({
    required String patientId,
    required String entityId,
    String? message,
    String? actorUserId,
  }) async {
    if (await hasRecentEvent(
      patientId: patientId,
      eventType: eventInviteAccepted,
      entityId: entityId,
    )) {
      return;
    }

    await _insertGapEvent(
      NotificationEventModel(
        patientId: patientId,
        actorUserId: actorUserId,
        eventType: eventInviteAccepted,
        entityType: 'access_invite',
        entityId: entityId,
        message: message ?? 'An invite was accepted.',
        deliveryChannel: 'in_app',
      ),
    );
  }

  Future<void> recordInviteRejectedIfNeeded({
    required String patientId,
    required String entityId,
    String? message,
    String? actorUserId,
  }) async {
    if (await hasRecentEvent(
      patientId: patientId,
      eventType: eventInviteRejected,
      entityId: entityId,
    )) {
      return;
    }

    await _insertGapEvent(
      NotificationEventModel(
        patientId: patientId,
        actorUserId: actorUserId,
        eventType: eventInviteRejected,
        entityType: 'access_invite',
        entityId: entityId,
        message: message ?? 'An invite was rejected.',
        deliveryChannel: 'in_app',
      ),
    );
  }

  Future<void> recordPermissionUpdatedIfNeeded({
    required String patientId,
    required String grantId,
    String? message,
    String? actorUserId,
  }) async {
    if (await hasRecentEvent(
      patientId: patientId,
      eventType: eventPermissionUpdated,
      entityId: grantId,
    )) {
      return;
    }

    await _insertGapEvent(
      NotificationEventModel(
        patientId: patientId,
        actorUserId: actorUserId,
        eventType: eventPermissionUpdated,
        entityType: 'access_grant',
        entityId: grantId,
        message: message ?? 'Access permission was updated.',
        deliveryChannel: 'in_app',
      ),
    );
  }

  Future<void> recordGrantRevokedIfNeeded({
    required String patientId,
    required String grantId,
    String? message,
    String? actorUserId,
  }) async {
    if (await hasRecentEvent(
      patientId: patientId,
      eventType: eventGrantRevoked,
      entityId: grantId,
    )) {
      return;
    }

    await _insertGapEvent(
      NotificationEventModel(
        patientId: patientId,
        actorUserId: actorUserId,
        eventType: eventGrantRevoked,
        entityType: 'access_grant',
        entityId: grantId,
        message: message ?? 'Access was revoked.',
        deliveryChannel: 'in_app',
      ),
    );
  }
}
