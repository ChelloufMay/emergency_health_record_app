import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/audit_log_model.dart';

class AuditService {
  AuditService._();

  static final AuditService instance = AuditService._();

  final SupabaseClient _client = Supabase.instance.client;

  Future<List<AuditLogModel>> _fetchLogs(
      String source,
      String patientId, {
        String? entityType,
        String? action,
        int? limit,
        bool ranked = false,
      }) async {
    final query = _client.from(source).select().eq('patient_id', patientId);

    if (entityType != null && entityType.trim().isNotEmpty) {
      query.filter('entity_type', 'eq', entityType.trim());
    }

    if (action != null && action.trim().isNotEmpty) {
      query.filter('action', 'eq', action.trim());
    }

    final response = ranked
        ? await query.order('timestamp', ascending: false)
        : await query.order('timestamp', ascending: false).limit(limit ?? 500);

    return (response as List<dynamic>)
        .map((e) => AuditLogModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // Read-only.
  // The database triggers already write audit rows for data changes,
  // so the app should not insert audit rows manually during CRUD flows.
  Future<List<AuditLogModel>> getAuditLogsForPatient(String patientId) {
    return _fetchLogs('audit_logs', patientId);
  }

  /// Same idea as above, but reads the ranked view if the screen wants
  /// a precomputed newest-first ordering per patient.
  Future<List<AuditLogModel>> getRankedAuditLogsForPatient(
      String patientId,
      ) {
    return _fetchLogs(
      'audit_logs_ranked',
      patientId,
      ranked: true,
    );
  }

  /// Convenience filter for screens that want only one entity type or action.
  Future<List<AuditLogModel>> getAuditLogsForPatientEntity(
      String patientId, {
        String? entityType,
        String? action,
        int? limit,
      }) {
    return _fetchLogs(
      'audit_logs',
      patientId,
      entityType: entityType,
      action: action,
      limit: limit,
    );
  }
}
