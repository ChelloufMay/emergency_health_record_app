import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/access_grant_model.dart';
import '../models/access_invite_model.dart';

class AccessService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchMyAccessDashboardRows() async {
    // CHANGED: keeps the dashboard backed by the DB view already used by the app.
    final rows = await _supabase
        .from('patient_access_dashboard')
        .select()
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<AccessGrantModel>> fetchPatientGrants(String patientId) async {
    final rows = await _supabase
        .from('access_grants')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((e) => AccessGrantModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<AccessInviteModel>> fetchPatientInvites(String patientId) async {
    final rows = await _supabase
        .from('access_invites')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((e) => AccessInviteModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // CHANGED: useful for invite receivers who just want to see their pending items.
  Future<List<AccessInviteModel>> fetchMyPendingInvites() async {
    final email = _supabase.auth.currentUser?.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) return const [];

    final rows = await _supabase
        .from('access_invites')
        .select()
        .eq('status', 'pending')
        .eq('invited_email', email)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((e) => AccessInviteModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchActiveAccessForPatient(
      String patientId,
      ) async {
    final rows = await _supabase.rpc(
      'get_active_access_for_patient',
      params: {'_patient_id': patientId},
    );

    if (rows is List) {
      return rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
    }
    return const [];
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

  // CHANGED: this is what lets the patient change a grant from read/edit/emergency_only.
  // The DB trigger keeps caregiver_permissions in sync.
  Future<void> updateGrantPermission({
    required String grantId,
    required String permission,
  }) async {
    await _supabase
        .from('access_grants')
        .update({'permission': permission})
        .eq('id', grantId);
  }

  Future<void> revokeGrant(String grantId) async {
    // CHANGED: revoke stays a direct update because the DB trigger syncs permissions.
    await _supabase
        .from('access_grants')
        .update({'status': 'revoked'})
        .eq('id', grantId);
  }
}