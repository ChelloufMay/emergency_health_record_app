import 'package:flutter/foundation.dart';

import '../utils/audit_helper.dart';

/// Server-primary audit helper: Postgres triggers write most audit rows.
///
/// This service only fills gaps for tables that lack triggers. The allowlist is
/// limited to tables confirmed missing audit triggers in the current schema.
class AuditWriteService {
  AuditWriteService._();
  static final AuditWriteService instance = AuditWriteService._();

  /// Tables confirmed to lack audit triggers in the current schema.
  static const Set<String> gapTables = {
    'account_deletion_requests',
    'addresses',
    'caregiver_permissions',
    'caregiver_profiles',
    'clinician_profiles',
    'email_outbox',
    'family_doctors',
    'guardian_profiles',
    'users',
  };

  Future<void> recordIfNeeded({
    required String patientId,
    required String action,
    required String entityType,
    String? entityId,
    String? performedByUserId,
    String? actorRole,
    String? fieldName,
    String? oldValue,
    String? newValue,
    String? notes,
  }) async {
    if (!gapTables.contains(entityType)) {
      if (kDebugMode) {
        debugPrint(
          'AuditWriteService: skip $action on $entityType (server triggers)',
        );
      }
      return;
    }

    // Gap insert would go here once RLS/RPC is confirmed for client writes.
    final _ = AuditHelper.buildAuditRecord(
      patientId: patientId,
      action: action,
      entityType: entityType,
      performedByUserId: performedByUserId,
      entityId: entityId,
      fieldName: fieldName,
      oldValue: oldValue,
      newValue: newValue,
      notes: notes ?? actorRole,
    );

    if (kDebugMode) {
      debugPrint(
        'AuditWriteService: gap audit not inserted (configure gapTables + RLS)',
      );
    }
  }
}