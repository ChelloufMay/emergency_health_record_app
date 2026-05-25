import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_event_model.dart';

/// Reads `notification_events`.
///
/// The database now writes access lifecycle events itself, so this service
/// stays read-only.
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
}