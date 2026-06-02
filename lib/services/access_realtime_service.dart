import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Subscribes to access-related tables so inbox/management screens refresh.
// Tracks the logged-in app user and only emits grant-change +refreshes when the change is relevant to that user.
class AccessRealtimeService {
  AccessRealtimeService._();

  static final AccessRealtimeService instance = AccessRealtimeService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  RealtimeChannel? _channel;
  int _listenerCount = 0;
  String? _watchedAppUserId;

  // Stream that emits when access related changes occur.
  Stream<void> get onChanged => _changes.stream;

  // adds a listener to be notified of access changes
  void addListener(VoidCallback listener) {
    _changes.stream.listen((_) => listener());
  }

  // Fetches the current app user ID from the DB using a RPC call.
  Future<String?> _currentAppUserId() async {
    if (_supabase.auth.currentUser == null) return null;

    final result = await _supabase.rpc('current_app_user_id');
    final text = result?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  // Checks if the realtime payload involves the currently watched user.
  bool _payloadTouchesWatchedUser(dynamic payload) {
    final watchedUserId = _watchedAppUserId;
    if (watchedUserId == null || watchedUserId.isEmpty) return false;

    // Realtime payloads expose newRecord / oldRecord. --> check both so INSERT / UPDATE / DELETE work.
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
    } catch (_) {}

    final newGrantee = newRecord?['grantee_user_id']?.toString();
    final oldGrantee = oldRecord?['grantee_user_id']?.toString();

    return newGrantee == watchedUserId || oldGrantee == watchedUserId;
  }

  // Subscribes to realtime changes for access related tables (invites, notifications, grants).
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

    // If the authenticated app user changed --> rebuild the channel so the grant listener tracks the new user correctly.
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
            // Only refresh when the change touches the currently logged in user.
            if (_payloadTouchesWatchedUser(payload)) {
              _emit();
            }
          },
        );

    _channel!.subscribe();
  }

  // Decrements the listener count and unsubscribes if no more listeners remain.
  Future<void> unsubscribe() async {
    _listenerCount = (_listenerCount - 1).clamp(0, 999);
    if (_listenerCount > 0 || _channel == null) return;

    await _supabase.removeChannel(_channel!);
    _channel = null;
    _watchedAppUserId = null;
  }

  // Emits a change event to the stream controller
  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  // Disposes of the service, removing channels and closing the stream controller.
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
