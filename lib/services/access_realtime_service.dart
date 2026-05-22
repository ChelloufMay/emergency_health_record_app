import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Subscribes to access-related tables so inbox/management screens refresh.
///
/// Supabase Realtime must be enabled on `access_invites`, `access_grants`, and
/// `notification_events` in the remote project.
class AccessRealtimeService {
  AccessRealtimeService._();
  static final AccessRealtimeService instance = AccessRealtimeService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  RealtimeChannel? _channel;
  int _listenerCount = 0;

  Stream<void> get onChanged => _changes.stream;

  void addListener(VoidCallback listener) {
    _changes.stream.listen((_) => listener());
  }

  Future<void> subscribe() async {
    _listenerCount++;
    if (_channel != null) return;

    _channel = _supabase.channel('access-changes');
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
          table: 'access_grants',
          callback: (_) => _emit(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notification_events',
          callback: (_) => _emit(),
        );

    _channel!.subscribe();
  }

  Future<void> unsubscribe() async {
    _listenerCount = (_listenerCount - 1).clamp(0, 999);
    if (_listenerCount > 0 || _channel == null) return;

    await _supabase.removeChannel(_channel!);
    _channel = null;
  }

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  void dispose() {
    _listenerCount = 0;
    if (_channel != null) {
      _supabase.removeChannel(_channel!);
      _channel = null;
    }
    _changes.close();
  }
}
