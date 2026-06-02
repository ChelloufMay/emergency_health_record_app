import 'package:flutter/foundation.dart';

import '../utils/audit_helper.dart';

// A service that handles client-side audit logging for tables confirmed to lack server-side triggers.
class AuditWriteService {
  AuditWriteService._();
  static final AuditWriteService instance = AuditWriteService._();

  // Tables confirmed to lack audit triggers in the current schema.
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

  // Records an audit log entry if the specified entity type is in the gapTables allowlist.
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

    // Gap insert go here once RLS/RPC is confirmed for client writes.
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