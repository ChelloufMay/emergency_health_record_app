import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/emergency_access_token_model.dart';
import 'service_exceptions.dart';

class EmergencyAccessTokenService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<EmergencyAccessTokenModel>> fetchByPatient(
    String patientId,
  ) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return [];

    final rows = await _supabase
        .from('emergency_access_tokens')
        .select()
        .eq('patient_id', pid)
        .order('created_at', ascending: false);

    return (rows as List)
        .map(
          (row) => EmergencyAccessTokenModel.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<EmergencyAccessTokenModel> create({
    required String patientId,
    String? createdByUserId,
    String? notes,
    DateTime? expiresAt,
    String? token,
  }) async {
    final pid = requireText(patientId, 'patientId');

    final payload = EmergencyAccessTokenModel(
      patientId: pid,
      createdByUserId: trimToNull(createdByUserId),
      notes: trimToNull(notes),
      expiresAt: expiresAt,
      token: trimToNull(token),
    );

    try {
      final row = await _supabase
          .from('emergency_access_tokens')
          .insert(payload.toInsertMap())
          .select()
          .single();

      return EmergencyAccessTokenModel.fromMap(
        Map<String, dynamic>.from(row as Map),
      );
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Emergency token create'));
    }
  }

  Future<void> revoke(String id) async {
    final rowId = requireText(id, 'id');

    try {
      await _supabase
          .from('emergency_access_tokens')
          .update({
            'is_active': false,
            'revoked_at': DateTime.now().toIso8601String(),
          })
          .eq('id', rowId);
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Emergency token revoke'));
    }
  }

  Future<void> delete({required String patientId, required String id}) async {
    final pid = requireText(patientId, 'patientId');
    final rowId = requireText(id, 'id');

    try {
      await _supabase
          .from('emergency_access_tokens')
          .delete()
          .eq('id', rowId)
          .eq('patient_id', pid);
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Emergency token delete'));
    }
  }
}
