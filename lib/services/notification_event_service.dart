import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_event_model.dart';

class NotificationEventService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<NotificationEventModel>> fetchByPatient(String patientId) async {
    final rows = await _supabase
        .from('notification_events')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => NotificationEventModel.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<NotificationEventModel>> fetchPendingByPatient(String patientId) async {
    final rows = await _supabase
        .from('notification_events')
        .select()
        .eq('patient_id', patientId)
        .eq('is_sent', false)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => NotificationEventModel.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }
}