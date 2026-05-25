import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/access_grant_model.dart';
import '../models/access_grant_view_model.dart';
import '../models/access_inbox_item_model.dart';
import '../models/access_invite_model.dart';
import '../models/patient_access_row_model.dart';

class AccessService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _currentEmail() {
    final email = _supabase.auth.currentUser?.email?.trim().toLowerCase();
    return email == null || email.isEmpty ? null : email;
  }

  Future<String?> _currentAppUserId() async {
    if (_supabase.auth.currentUser == null) return null;
    final result = await _supabase.rpc('current_app_user_id');
    final text = result?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  List<Map<String, dynamic>> _toMapList(dynamic rows) {
    if (rows is! List) return const [];
    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  bool _isActiveGrantRow(Map<String, dynamic> row) {
    final status = row['status']?.toString();
    if (status != 'active') return false;

    final expiresAtRaw = row['expires_at']?.toString();
    if (expiresAtRaw == null || expiresAtRaw.trim().isEmpty) {
      return true;
    }

    final expiresAt = DateTime.tryParse(expiresAtRaw);
    if (expiresAt == null) return true;

    return expiresAt.isAfter(DateTime.now());
  }

  Future<List<PatientAccessRowModel>> fetchMyAccessDashboardRows() async {
    final rows = await _supabase
        .from('patient_access_dashboard')
        .select()
        .order('created_at', ascending: false);

    return (rows as List)
        .map((item) {
      final m = Map<String, dynamic>.from(item as Map);

      if (!_isActiveGrantRow(m)) return null;

      return PatientAccessRowModel.fromMap({
        ...m,
        'id': m['access_grant_id'] ?? m['id'],
        'grant_id': m['access_grant_id'] ?? m['id'],
      });
    })
        .whereType<PatientAccessRowModel>()
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchMyAccessDashboardRowMaps() async {
    final rows = await fetchMyAccessDashboardRows();
    return rows.map((row) => row.toMap()).toList();
  }

  Future<List<Map<String, dynamic>>> fetchMyActiveGrants() async {
    final rows = await fetchMyAccessDashboardRows();
    return rows.map((row) => row.toMap()).toList();
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

  Future<List<Map<String, dynamic>>> _fetchMyInvitesByStatus(
      String status,
      ) async {
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

  Future<List<Map<String, dynamic>>> fetchMyPendingInvitesWithPatientDetails() {
    return _fetchMyInvitesByStatus('pending');
  }

  Future<List<Map<String, dynamic>>> fetchMyAcceptedInvitesWithPatientDetails() {
    return _fetchMyInvitesByStatus('accepted');
  }

  Future<List<Map<String, dynamic>>> fetchMyRejectedInvitesWithPatientDetails() {
    return _fetchMyInvitesByStatus('rejected');
  }

  Future<List<Map<String, dynamic>>> fetchMyRevokedInvitesWithPatientDetails() {
    return _fetchMyInvitesByStatus('revoked');
  }

  Future<List<Map<String, dynamic>>> fetchMyPendingInviteMaps() {
    return fetchMyPendingInvitesWithPatientDetails();
  }

  Future<List<AccessInviteModel>> fetchMyPendingInvites() async {
    final rows = await fetchMyPendingInvitesWithPatientDetails();
    return rows.map((e) => AccessInviteModel.fromMap(e)).toList();
  }

  Future<List<AccessInviteModel>> fetchMyAcceptedInvites() async {
    final rows = await fetchMyAcceptedInvitesWithPatientDetails();
    return rows.map((e) => AccessInviteModel.fromMap(e)).toList();
  }

  Future<List<AccessInviteModel>> fetchMyRejectedInvites() async {
    final rows = await fetchMyRejectedInvitesWithPatientDetails();
    return rows.map((e) => AccessInviteModel.fromMap(e)).toList();
  }

  Future<List<AccessInviteModel>> fetchMyRevokedInvites() async {
    final rows = await fetchMyRevokedInvitesWithPatientDetails();
    return rows.map((e) => AccessInviteModel.fromMap(e)).toList();
  }

  Future<List<AccessInboxItemModel>> fetchMyInboxPending() async {
    final rows = await fetchMyPendingInvitesWithPatientDetails();
    return rows.map(AccessInboxItemModel.fromMap).toList();
  }

  Future<List<AccessInboxItemModel>> fetchMyInboxAccepted() async {
    final rows = await fetchMyAcceptedInvitesWithPatientDetails();
    return rows.map(AccessInboxItemModel.fromMap).toList();
  }

  Future<List<AccessInboxItemModel>> fetchMyInboxRejected() async {
    final rows = await fetchMyRejectedInvitesWithPatientDetails();
    return rows.map(AccessInboxItemModel.fromMap).toList();
  }

  Future<List<AccessGrantViewModel>> fetchPatientGrantViews(
      String patientId,
      ) async {
    final grants = await fetchPatientGrants(patientId);
    return grants
        .map((g) => AccessGrantViewModel.fromGrant(g))
        .where((g) => g.grantId.isNotEmpty)
        .toList();
  }

  Future<List<AccessGrantViewModel>> fetchMyActiveGrantViews() async {
    final rows = await fetchMyActiveGrants();
    return rows
        .map((r) => AccessGrantViewModel.fromDashboardRow(r))
        .where((g) => g.grantId.isNotEmpty)
        .toList();
  }

  void notifyAccessChanged() {}

  Future<List<Map<String, dynamic>>> fetchActiveAccessForPatient(
      String patientId,
      ) async {
    final appUserId = await _currentAppUserId();
    if (appUserId == null || appUserId.isEmpty) {
      return const [];
    }

    final rows = await _supabase
        .from('access_grants')
        .select(
      'id, patient_id, grantee_user_id, grantee_role, permission, status, '
          'granted_by_user_id, granted_at, expires_at, source_invite_id, notes, '
          'created_at, updated_at',
    )
        .eq('patient_id', patientId)
        .eq('grantee_user_id', appUserId)
        .eq('status', 'active')
        .order('created_at', ascending: false);

    return _toMapList(rows);
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

  Future<dynamic> acceptInvite(
      String inviteToken, {
        String? patientId,
        String? inviteId,
        String? actorUserId,
      }) async {
    final result = await _supabase.rpc(
      'accept_access_invite',
      params: {'_invite_token': inviteToken.trim()},
    );

    notifyAccessChanged();
    return result;
  }

  Future<dynamic> rejectInvite(
      String inviteToken, {
        String? patientId,
        String? inviteId,
        String? actorUserId,
      }) async {
    final result = await _supabase.rpc(
      'reject_access_invite',
      params: {'_invite_token': inviteToken.trim()},
    );

    notifyAccessChanged();
    return result;
  }

  Future<dynamic> updateGrantPermission({
    required String grantId,
    required String permission,
    DateTime? expiresAt,
    String? notes,
    String? patientId,
    String? actorUserId,
  }) async {
    final result = await _supabase.rpc(
      'update_access_grant_permission',
      params: {
        '_grant_id': grantId.trim(),
        '_permission': permission.trim(),
        '_expires_at': expiresAt?.toIso8601String(),
        '_notes': notes?.trim(),
      },
    );

    notifyAccessChanged();
    return result;
  }

  Future<dynamic> revokeGrant(
      String grantId, {
        String? patientId,
        String? actorUserId,
      }) async {
    final result = await _supabase.rpc(
      'revoke_access_grant',
      params: {'_grant_id': grantId.trim()},
    );

    notifyAccessChanged();
    return result;
  }
}