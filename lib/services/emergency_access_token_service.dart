import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/emergency_access_token_model.dart';

class EmergencyAccessTokenService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<EmergencyAccessTokenModel>> fetchByPatient(String patientId) async {
    final rows = await _supabase
        .from('emergency_access_tokens')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => EmergencyAccessTokenModel.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<EmergencyAccessTokenModel> create({
    required String patientId,
    String? createdByUserId,
    String? notes,
    DateTime? expiresAt,
    String? token,
  }) async {
    final payload = EmergencyAccessTokenModel(
      patientId: patientId,
      createdByUserId: createdByUserId,
      notes: notes,
      expiresAt: expiresAt,
      token: token,
    );

    final row = await _supabase
        .from('emergency_access_tokens')
        .insert(payload.toInsertMap())
        .select()
        .single();

    return EmergencyAccessTokenModel.fromMap(Map<String, dynamic>.from(row as Map));
  }

  Future<void> revoke(String id) async {
    await _supabase.from('emergency_access_tokens').update({
      'is_active': false,
      'revoked_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> delete({
    required String patientId,
    required String id,
  }) async {
    await _supabase.from('emergency_access_tokens').delete().eq('id', id).eq('patient_id', patientId);
  }
}
