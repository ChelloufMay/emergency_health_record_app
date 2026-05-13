import 'package:supabase_flutter/supabase_flutter.dart';

class AccessService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchMyAccessDashboardRows() async {
    final rows = await _supabase
        .from('patient_access_dashboard')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> fetchPatientGrants(String patientId) async {
    final rows = await _supabase
        .from('access_grants')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> fetchPatientInvites(String patientId) async {
    final rows = await _supabase
        .from('access_invites')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<String> createInvite({
    required String patientId,
    required String invitedEmail,
    required String invitedRole,
    required String permission,
    DateTime? expiresAt,
    String? notes,
  }) async {
    final result = await _supabase.rpc(
      'create_access_invite',
      params: {
        '_patient_id': patientId,
        '_invited_email': invitedEmail,
        '_invited_role': invitedRole,
        '_permission': permission,
        '_expires_at': expiresAt?.toIso8601String(),
        '_notes': notes,
      },
    );
    return result.toString();
  }

  Future<String> acceptInvite(String inviteToken) async {
    final result = await _supabase.rpc(
      'accept_access_invite',
      params: {'_invite_token': inviteToken},
    );
    return result.toString();
  }

  Future<String> rejectInvite(String inviteToken) async {
    final result = await _supabase.rpc(
      'reject_access_invite',
      params: {'_invite_token': inviteToken},
    );
    return result.toString();
  }

  Future<void> revokeGrant(String grantId) async {
    await _supabase.from('access_grants').update({
      'status': 'revoked',
    }).eq('id', grantId);
  }
}