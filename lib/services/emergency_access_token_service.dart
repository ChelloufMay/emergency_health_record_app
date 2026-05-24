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

    // NOTE:
    // This method is still a direct table read, but it is only for the
    // owner/admin-style management screen path.
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
      await _supabase.from('emergency_access_tokens').update({
        'is_active': false,
        'revoked_at': DateTime.now().toIso8601String(),
      }).eq('id', rowId);
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

  Future<EmergencyAccessTokenModel?> fetchActiveVisibleTokenForPatient(
      String patientId,
      ) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return null;

    // First try the RPC path. If the DB wrapper is still blocked,
    // fall back to a direct table read for owner/admin-style access.
    try {
      final result = await _supabase.rpc(
        'get_active_emergency_token_for_patient',
        params: {'_patient_id': pid},
      );

      final parsed = _parseSingleTokenRow(result);
      if (parsed != null) return parsed;
    } catch (_) {
      // Ignore and fall back below.
    }

    try {
      final rows = await _supabase
          .from('emergency_access_tokens')
          .select()
          .eq('patient_id', pid)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1);

      final parsed = _parseSingleTokenRow(rows);
      if (parsed != null) return parsed;
    } catch (_) {
      // Ignore and return null below.
    }

    return null;
  }

  Future<Map<String, dynamic>?> resolveEmergencyAccessToken(
      String token,
      ) async {
    final normalized = token.trim();
    if (normalized.isEmpty) return null;

    // Prefer the public wrapper if present.
    try {
      final result = await _supabase.rpc(
        'resolve_public_emergency_token',
        params: {'_token': normalized},
      );

      final parsed = _parseSingleMapRow(result);
      if (parsed != null) return parsed;
    } catch (_) {
      // Fall back to the older resolver below.
    }

    try {
      final result = await _supabase.rpc(
        'resolve_emergency_access_token',
        params: {'_token': normalized},
      );

      final parsed = _parseSingleMapRow(result);
      if (parsed != null) return parsed;
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(
        e,
        'Emergency token resolve',
      ));
    }

    return null;
  }

  EmergencyAccessTokenModel? _parseSingleTokenRow(dynamic result) {
    if (result is Map) {
      return EmergencyAccessTokenModel.fromMap(
        Map<String, dynamic>.from(result),
      );
    }

    if (result is List && result.isNotEmpty && result.first is Map) {
      return EmergencyAccessTokenModel.fromMap(
        Map<String, dynamic>.from(result.first as Map),
      );
    }

    return null;
  }

  Map<String, dynamic>? _parseSingleMapRow(dynamic result) {
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }

    if (result is List && result.isNotEmpty && result.first is Map) {
      return Map<String, dynamic>.from(result.first as Map);
    }

    return null;
  }
}