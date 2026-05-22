import 'package:flutter/foundation.dart';

import '../utils/audit_helper.dart';

/// Server-primary audit helper: Postgres triggers write most audit rows.
///
/// This service only fills gaps for tables that lack triggers. The default
/// allowlist is empty, so [recordIfNeeded] is a no-op until you add table names
/// after reviewing Supabase migrations.
class AuditWriteService {
  AuditWriteService._();
  static final AuditWriteService instance = AuditWriteService._();

  /// Tables confirmed to lack audit triggers (extend after Supabase review).
  static const Set<String> gapTables = {};

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
