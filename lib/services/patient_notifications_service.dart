import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_event_model.dart';

/// Read-only notification timeline service.
/// This is useful for showing the invite/access notification history in a
/// patient-facing screen without mixing that logic into the widget.
class PatientNotificationsService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<NotificationEventModel>> fetchForPatient(String patientId) async {
    final rows = await _client
        .from('notification_events')
        .select('*')
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => NotificationEventModel.fromMap(Map.from(row as Map)))
        .toList();
  }
}
