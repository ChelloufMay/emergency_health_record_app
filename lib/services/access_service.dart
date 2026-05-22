import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/access_grant_model.dart';
import '../models/access_invite_model.dart';
import '../models/patient_access_row_model.dart';

class AccessService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _currentEmail() {
    final email = _supabase.auth.currentUser?.email?.trim().toLowerCase();
    return email == null || email.isEmpty ? null : email;
  }

  List<Map<String, dynamic>> _toMapList(dynamic rows) {
    if (rows is! List) return const [];
    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<PatientAccessRowModel>> fetchMyAccessDashboardRows() async {
    final rows = await _supabase
        .from('patient_access_dashboard')
        .select()
        .order('created_at', ascending: false);

    return (rows as List)
        .map(
          (row) => PatientAccessRowModel.fromMap(
        Map<String, dynamic>.from(row as Map),
      ),
    )
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchMyAccessDashboardRowMaps() async {
    final rows = await _supabase
        .from('patient_access_dashboard')
        .select()
        .order('created_at', ascending: false);

    return _toMapList(rows);
  }

  /// CHANGED: active grants are now read from the access dashboard view so the
  /// UI keeps patient info and grant IDs together.
  Future<List<Map<String, dynamic>>> fetchMyActiveGrants() async {
    final rows = await _supabase
        .from('patient_access_dashboard')
        .select()
        .order('created_at', ascending: false);

    return _toMapList(rows);
  }

  Future<List<AccessGrantModel>> fetchPatientGrants(String patientId) async {
    final rows = await _supabase
        .from('access_grants')
        .select()
        .eq('patient_id', patientId)
        .eq('status', 'active')
        .order('created_at', ascending: false);

    return (rows as List)
        .map(
          (e) => AccessGrantModel.fromMap(
        Map<String, dynamic>.from(e as Map),
      ),
    )
        .toList();
  }

  Future<List<AccessInviteModel>> fetchPatientInvites(String patientId) async {
    // CHANGED: read from the invite dashboard view so patient info stays visible.
    final rows = await _supabase
        .from('access_invites_dashboard')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map(
          (e) => AccessInviteModel.fromMap(
        Map<String, dynamic>.from(e as Map),
      ),
    )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchMyInvitesByStatus(String status) async {
    final email = _currentEmail();
    if (email == null) return const [];

    final rows = await _supabase
        .from('access_invites_dashboard')
        .select()
        .eq('status', status)
        .eq('invited_email', email)
        .order('created_at', ascending: false);

    return _toMapList(rows);
  }

  /// CHANGED: pending invites now come from the invite dashboard view.
  Future<List<Map<String, dynamic>>> fetchMyPendingInvitesWithPatientDetails() {
    return _fetchMyInvitesByStatus('pending');
  }

  /// CHANGED: accepted invites are separated so the dashboard can show history.
  Future<List<Map<String, dynamic>>> fetchMyAcceptedInvitesWithPatientDetails() {
    return _fetchMyInvitesByStatus('accepted');
  }

  /// CHANGED: rejected invites are separated so the dashboard can show history.
  Future<List<Map<String, dynamic>>> fetchMyRejectedInvitesWithPatientDetails() {
    return _fetchMyInvitesByStatus('rejected');
  }

  /// CHANGED: revoked invites/grants can also be shown as history.
  Future<List<Map<String, dynamic>>> fetchMyRevokedInvitesWithPatientDetails() {
    return _fetchMyInvitesByStatus('revoked');
  }

  /// Backward-compatible alias for older screens.
  Future<List<Map<String, dynamic>>> fetchMyPendingInviteMaps() {
    return fetchMyPendingInvitesWithPatientDetails();
  }

  Future<List<AccessInviteModel>> fetchMyPendingInvites() async {
    final rows = await fetchMyPendingInvitesWithPatientDetails();
    return rows
        .map(
          (e) => AccessInviteModel.fromMap(e),
    )
        .toList();
  }

  Future<List<AccessInviteModel>> fetchMyAcceptedInvites() async {
    final rows = await fetchMyAcceptedInvitesWithPatientDetails();
    return rows
        .map(
          (e) => AccessInviteModel.fromMap(e),
    )
        .toList();
  }

  Future<List<AccessInviteModel>> fetchMyRejectedInvites() async {
    final rows = await fetchMyRejectedInvitesWithPatientDetails();
    return rows
        .map(
          (e) => AccessInviteModel.fromMap(e),
    )
        .toList();
  }

  Future<List<AccessInviteModel>> fetchMyRevokedInvites() async {
    final rows = await fetchMyRevokedInvitesWithPatientDetails();
    return rows
        .map(
          (e) => AccessInviteModel.fromMap(e),
    )
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

  Future<dynamic> acceptInvite(String inviteToken) async {
    // CHANGED: the invite is accepted through the database RPC, not by writing
    // locally, so the trigger chain can create the grant and notifications.
    return _supabase.rpc(
      'accept_access_invite',
      params: {'_invite_token': inviteToken.trim()},
    );
  }

  Future<dynamic> rejectInvite(String inviteToken) async {
    // CHANGED: the invite is rejected through the database RPC so the patient
    // can be notified and the status change stays consistent.
    return _supabase.rpc(
      'reject_access_invite',
      params: {'_invite_token': inviteToken.trim()},
    );
  }

  Future<dynamic> updateGrantPermission({
    required String grantId,
    required String permission,
    DateTime? expiresAt,
    String? notes,
  }) async {
    // CHANGED: permission changes now go through the secured RPC so the grant,
    // caregiver_permission mirror, and audit trail stay synchronized.
    return _supabase.rpc(
      'update_access_grant_permission',
      params: {
        '_grant_id': grantId.trim(),
        '_permission': permission.trim(),
        '_expires_at': expiresAt?.toIso8601String(),
        '_notes': notes?.trim(),
      },
    );
  }

  Future<dynamic> revokeGrant(String grantId) async {
    // CHANGED: revocation is handled by RPC so the access change can fan out to
    // mirrors, notifications, and audit logging in one controlled place.
    return _supabase.rpc(
      'revoke_access_grant',
      params: {'_grant_id': grantId.trim()},
    );
  }
}