import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/access_grant_model.dart';
import '../models/access_grant_view_model.dart';
import '../models/access_inbox_item_model.dart';
import '../models/access_invite_model.dart';
import '../models/patient_access_row_model.dart';
import 'notification_event_service.dart';

class AccessService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationEventService _notifications = NotificationEventService();

  String? _currentEmail() {
    final email = _supabase.auth.currentUser?.email?.trim().toLowerCase();
    return email == null || email.isEmpty ? null : email;
  }

  /// Uses the security-definer RPC so that RLS on public.users is never
  /// an obstacle for resolving the caller's app-level user id.
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

  /// Reads patient identity fields from the enriched view.
  /// Replaces the removed get_patient_dashboard_details RPC.
  Future<Map<String, dynamic>?> _patientSummary(String patientId) async {
    final row = await _supabase
        .from('patient_profiles_enriched')
        .select(
          'id, user_id, legal_id, first_name, family_name, sex, age_years, '
          'blood_type, phone, address_country, address_governorate, '
          'address_city, emergency_contact_name, emergency_contact_phone, '
          'insurance_plan, covid_vaccine_type, family_doctor_id, '
          'created_at, updated_at',
        )
        .eq('id', patientId)
        .maybeSingle();

    if (row == null) return null;
    return Map<String, dynamic>.from(row);
  }

  String _patientNameFromDetails(Map<String, dynamic>? details) {
    if (details == null) return 'Unknown patient';

    final first = (details['first_name']?.toString() ?? '').trim();
    final last = (details['family_name']?.toString() ?? '').trim();
    final combined = '$first $last'.trim();

    if (combined.isNotEmpty) return combined;
    if (first.isNotEmpty) return first;
    if (last.isNotEmpty) return last;

    return 'Unknown patient';
  }

  Map<String, dynamic> _buildAccessDashboardRow({
    required Map<String, dynamic> grant,
    required Map<String, dynamic>? patientDetails,
  }) {
    return {
      'id': grant['id'],
      'access_grant_id': grant['id'],
      'grant_id': grant['id'],
      'patient_id': grant['patient_id'],
      'patient_name': _patientNameFromDetails(patientDetails),
      'first_name': patientDetails?['first_name'],
      'family_name': patientDetails?['family_name'],
      'date_of_birth': patientDetails?['date_of_birth'],
      'age_years': patientDetails?['age_years'],
      'sex': patientDetails?['sex'],
      'blood_type': patientDetails?['blood_type'],
      'grantee_user_id': grant['grantee_user_id'],
      'grantee_role': grant['grantee_role'],
      'grantee_full_name': null,
      'permission': grant['permission'],
      'status': grant['status'],
      'granted_by_user_id': grant['granted_by_user_id'],
      'granted_by_full_name': null,
      'granted_at': grant['granted_at'],
      'expires_at': grant['expires_at'],
      'notes': grant['notes'],
      'created_at': grant['created_at'],
      'updated_at': grant['updated_at'],
      'source_invite_id': grant['source_invite_id'],
    };
  }

  Future<List<PatientAccessRowModel>> fetchMyAccessDashboardRows() async {
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
        .eq('grantee_user_id', appUserId)
        .eq('status', 'active')
        .order('created_at', ascending: false);

    final result = <PatientAccessRowModel>[];

    for (final item in (rows as List)) {
      final grant = Map<String, dynamic>.from(item as Map);
      if (!_isActiveGrantRow(grant)) continue;

      final patientId = grant['patient_id']?.toString() ?? '';
      final details = patientId.isEmpty
          ? null
          : await _patientSummary(patientId);

      result.add(
        PatientAccessRowModel.fromMap(
          _buildAccessDashboardRow(
            grant: grant,
            patientDetails: details,
          ),
        ),
      );
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> fetchMyAccessDashboardRowMaps() async {
    final rows = await fetchMyAccessDashboardRows();
    return rows.map((row) => Map<String, dynamic>.from(row.toMap())).toList();
  }

  /// Active grants are now read directly from access_grants using the
  /// authenticated app user mapped through public.users.id.
  Future<List<Map<String, dynamic>>> fetchMyActiveGrants() async {
    final rows = await fetchMyAccessDashboardRows();
    return rows.map((row) => Map<String, dynamic>.from(row.toMap())).toList();
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

  void notifyAccessChanged() {
    // Realtime channel also emits; this supports manual refresh hooks.
  }

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

  Future<String?> _patientIdForInviteToken(String inviteToken) async {
    final rows = await _supabase
        .from('access_invites_dashboard')
        .select('patient_id, id')
        .eq('invite_token', inviteToken.trim())
        .limit(1);
    if (rows.isEmpty) return null;
    final row = Map<String, dynamic>.from(rows.first as Map);
    return row['patient_id']?.toString();
  }

  Future<String?> _patientIdForGrant(String grantId) async {
    final row = await _supabase
        .from('access_grants')
        .select('patient_id')
        .eq('id', grantId.trim())
        .maybeSingle();
    if (row == null) return null;
    return Map<String, dynamic>.from(row)['patient_id']?.toString();
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

    final pid =
        patientId ?? await _patientIdForInviteToken(inviteToken) ?? '';
    if (pid.isNotEmpty) {
      await _notifications.recordInviteAcceptedIfNeeded(
        patientId: pid,
        entityId: inviteId ?? inviteToken,
        actorUserId: actorUserId,
      );
    }
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

    final pid =
        patientId ?? await _patientIdForInviteToken(inviteToken) ?? '';
    if (pid.isNotEmpty) {
      await _notifications.recordInviteRejectedIfNeeded(
        patientId: pid,
        entityId: inviteId ?? inviteToken,
        actorUserId: actorUserId,
      );
    }
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

    final pid = patientId ?? await _patientIdForGrant(grantId) ?? '';
    if (pid.isNotEmpty) {
      await _notifications.recordPermissionUpdatedIfNeeded(
        patientId: pid,
        grantId: grantId,
        actorUserId: actorUserId,
      );
    }
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

    final pid = patientId ?? await _patientIdForGrant(grantId) ?? '';
    if (pid.isNotEmpty) {
      await _notifications.recordGrantRevokedIfNeeded(
        patientId: pid,
        grantId: grantId,
        actorUserId: actorUserId,
      );
    }
    notifyAccessChanged();
    return result;
  }
}
