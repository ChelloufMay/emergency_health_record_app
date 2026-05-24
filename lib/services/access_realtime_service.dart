import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Subscribes to access-related tables so inbox/management screens refresh.
///
/// This version also tracks the logged-in app user and only emits grant-change
/// refreshes when the change is relevant to that user.
class AccessRealtimeService {
  AccessRealtimeService._();
  static final AccessRealtimeService instance = AccessRealtimeService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  RealtimeChannel? _channel;
  int _listenerCount = 0;
  String? _watchedAppUserId;

  Stream<void> get onChanged => _changes.stream;

  void addListener(VoidCallback listener) {
    _changes.stream.listen((_) => listener());
  }

  Future<String?> _currentAppUserId() async {
    if (_supabase.auth.currentUser == null) return null;

    final result = await _supabase.rpc('current_app_user_id');
    final text = result?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  bool _payloadTouchesWatchedUser(dynamic payload) {
    final watchedUserId = _watchedAppUserId;
    if (watchedUserId == null || watchedUserId.isEmpty) return false;

    // Realtime payloads usually expose newRecord / oldRecord.
    // We check both so INSERT / UPDATE / DELETE all work.
    Map<String, dynamic>? newRecord;
    Map<String, dynamic>? oldRecord;

    try {
      final dynamic nr = payload.newRecord;
      if (nr is Map) {
        newRecord = Map<String, dynamic>.from(nr);
      }
    } catch (_) {
      // Ignore payload shape differences.
    }

    try {
      final dynamic or = payload.oldRecord;
      if (or is Map) {
        oldRecord = Map<String, dynamic>.from(or);
      }
    } catch (_) {
      // Ignore payload shape differences.
    }

    final newGrantee = newRecord?['grantee_user_id']?.toString();
    final oldGrantee = oldRecord?['grantee_user_id']?.toString();

    return newGrantee == watchedUserId || oldGrantee == watchedUserId;
  }

  Future<void> subscribe() async {
    _listenerCount++;

    final currentAppUserId = await _currentAppUserId();
    if (currentAppUserId == null || currentAppUserId.isEmpty) {
      return;
    }

    // If we are already watching the same user, do nothing.
    if (_channel != null && _watchedAppUserId == currentAppUserId) {
      return;
    }

    // If the authenticated app user changed, rebuild the channel so the
    // grant listener tracks the new user correctly.
    if (_channel != null) {
      await _supabase.removeChannel(_channel!);
      _channel = null;
    }

    _watchedAppUserId = currentAppUserId;

    _channel = _supabase.channel('access-changes-$currentAppUserId');

    _channel!
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'access_invites',
      callback: (_) => _emit(),
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'notification_events',
      callback: (_) => _emit(),
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'access_grants',
      callback: (payload) {
        // Only refresh the dashboard/context when the change touches the
        // currently logged-in app user.
        if (_payloadTouchesWatchedUser(payload)) {
          _emit();
        }
      },
    );

    _channel!.subscribe();
  }

  Future<void> unsubscribe() async {
    _listenerCount = (_listenerCount - 1).clamp(0, 999);
    if (_listenerCount > 0 || _channel == null) return;

    await _supabase.removeChannel(_channel!);
    _channel = null;
    _watchedAppUserId = null;
  }

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  void dispose() {
    _listenerCount = 0;
    _watchedAppUserId = null;

    if (_channel != null) {
      _supabase.removeChannel(_channel!);
      _channel = null;
    }

    if (!_changes.isClosed) {
      _changes.close();
    }
  }
}
