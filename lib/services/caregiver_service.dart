import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/caregiver_permission_model.dart';
import 'audit_service.dart';

class CaregiverService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();

  Future<List<CaregiverPermissionModel>> fetchPermissions(
      String patientId,
      ) async {
    final rows = await _supabase
        .from('caregiver_permissions')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => CaregiverPermissionModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<String> grantPermission({
    required CaregiverPermissionModel permission,
    required String performedByUserId,
  }) async {
    // Insert uses the DB defaults for id / created_at / updated_at.
    final inserted = await _supabase
        .from('caregiver_permissions')
        .insert(permission.toInsertMap())
        .select('id')
        .single();

    final newId = inserted['id'] as String;

    // Keep an audit trail for access grants.
    await _audit.log(
      patientId: permission.patientId,
      performedByUserId: performedByUserId,
      action: 'create',
      entityType: 'caregiver_permissions',
      entityId: newId,
      fieldName: 'permission',
      newValue: permission.permission,
    );

    return newId;
  }

  Future<void> updatePermission({
    required CaregiverPermissionModel permission,
    required String performedByUserId,
  }) async {
    if (permission.id == null || permission.id!.isEmpty) {
      throw Exception('Cannot update a caregiver permission without an id.');
    }

    await _supabase
        .from('caregiver_permissions')
        .update(permission.toUpdateMap())
        .eq('id', permission.id!);

    await _audit.log(
      patientId: permission.patientId,
      performedByUserId: performedByUserId,
      action: 'update',
      entityType: 'caregiver_permissions',
      entityId: permission.id!,
      fieldName: 'permission',
      newValue: permission.permission,
    );
  }

  Future<void> revokePermission({
    required String id,
    required String patientId,
    required String performedByUserId,
  }) async {
    // The DB already has a status column, so revoking means changing status.
    await _supabase
        .from('caregiver_permissions')
        .update({'status': 'revoked'})
        .eq('id', id);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'update',
      entityType: 'caregiver_permissions',
      entityId: id,
      fieldName: 'status',
      newValue: 'revoked',
    );
  }
}