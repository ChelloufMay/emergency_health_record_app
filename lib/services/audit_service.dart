import 'package:supabase_flutter/supabase_flutter.dart';
import 'patient_service.dart';

class AuditService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PatientService _patientService = PatientService();

  Future<void> log({
    required String patientId,
    String? performedByUserId,
    required String action,
    required String entityType,
    String? entityId,
    String? fieldName,
    String? oldValue,
    String? newValue,
    String? breakGlassReason,
    String? deviceId,
    String? ipAddress,
    String? eventHash,
  }) async {
    try {
      final actorId = performedByUserId ?? await _patientService.getAppUserId();

      await _supabase.from('audit_logs').insert({
        'patient_id': patientId,
        'performed_by_user_id': actorId,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'field_name': fieldName,
        'old_value': oldValue,
        'new_value': newValue,
        'device_id': deviceId,
        'ip_address': ipAddress,
        'break_glass_reason': breakGlassReason,
        'event_hash': eventHash,
      });
    } catch (_) {
      // never block the main flow
    }
  }

  Future<List<Map<String, dynamic>>> fetchLogs(String patientId) async {
    final rows = await _supabase
        .from('audit_logs')
        .select()
        .eq('patient_id', patientId)
        .order('timestamp', ascending: false);

    return (rows as List).cast<Map<String, dynamic>>();
  }
}