import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/audit_log_model.dart';

class AuditService {
  AuditService._();

  static final AuditService instance = AuditService._();

  final SupabaseClient _client = Supabase.instance.client;

  // Read-only.
  // The database triggers already write audit rows for data changes,
  // so the app should not insert audit rows manually during CRUD flows.
  Future<List<AuditLogModel>> getAuditLogsForPatient(String patientId) async {
    final response = await _client
        .from('audit_logs')
        .select()
        .eq('patient_id', patientId)
        .order('timestamp', ascending: false);

    return (response as List<dynamic>)
        .map((e) => AuditLogModel.fromMap(e as Map))
        .toList();
  }

  /// Same idea as above, but reads the ranked view if the screen wants
  /// a precomputed newest-first ordering per patient.
  Future<List<AuditLogModel>> getRankedAuditLogsForPatient(
      String patientId,
      ) async {
    final response = await _client
        .from('audit_logs_ranked')
        .select()
        .eq('patient_id', patientId)
        .order('timestamp', ascending: false);

    return (response as List<dynamic>)
        .map((e) => AuditLogModel.fromMap(e as Map))
        .toList();
  }
}