import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/caregiver_permission_model.dart';

class CaregiverService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<CaregiverPermissionModel>> fetchPermissions(String patientId) async {
    final rows = await _supabase
        .from('caregiver_permissions')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => CaregiverPermissionModel.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<String> grantPermission({
    required CaregiverPermissionModel permission,
    required String performedByUserId,
  }) async {
    // The trigger on caregiver_permissions mirrors this row into access_grants.
    final inserted = await _supabase
        .from('caregiver_permissions')
        .insert(permission.toInsertMap())
        .select('id')
        .single();

    return inserted['id'].toString();
  }

  Future<void> updatePermission({
    required CaregiverPermissionModel permission,
    required String performedByUserId,
  }) async {
    if (permission.id == null || permission.id!.isEmpty) {
      throw Exception('Missing caregiver permission id.');
    }

    await _supabase
        .from('caregiver_permissions')
        .update(permission.toUpdateMap())
        .eq('id', permission.id!);
  }

  Future<void> revokePermission({
    required String id,
    required String patientId,
    required String performedByUserId,
  }) async {
    await _supabase.from('caregiver_permissions').update({'status': 'revoked'}).eq('id', id);
  }
}