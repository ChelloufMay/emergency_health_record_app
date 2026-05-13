import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/caregiver_permission_model.dart';
import 'audit_service.dart';
import 'patient_service.dart';

class CaregiverService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();
  final PatientService _patientService = PatientService();

  Future<List<CaregiverPermissionModel>> fetchPermissions(String patientId) async {
    final rows = await _supabase
        .from('caregiver_permissions')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List).map((r) => CaregiverPermissionModel.fromMap(r as Map)).toList();
  }

  Future<List<CaregiverPermissionModel>> fetchMyPermissions() async {
    final appUserId = await _patientService.ensureAppUserId();
    if (appUserId == null) return [];

    final rows = await _supabase
        .from('caregiver_permissions')
        .select()
        .eq('caregiver_user_id', appUserId)
        .order('created_at', ascending: false);

    return (rows as List).map((r) => CaregiverPermissionModel.fromMap(r as Map)).toList();
  }

  Future<Map<String, dynamic>?> fetchPatientSummary(String patientId) async {
    return _supabase
        .from('patient_profiles_enriched')
        .select('id, first_name, family_name, sex, age_years, blood_type, address_country, address_governorate, address_city, emergency_contact_name, emergency_contact_phone')
        .eq('id', patientId)
        .maybeSingle();
  }

  Future<String?> findUserIdByEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return null;

    final result = await _supabase.rpc('find_user_id_by_email', params: {'_email': trimmed});
    if (result == null) return null;
    return result.toString();
  }

  Future<String> grantPermission({
    required CaregiverPermissionModel permission,
    required String performedByUserId,
  }) async {
    final inserted = await _supabase.from('caregiver_permissions').insert(permission.toInsertMap()).select('id').single();
    final newId = inserted['id'] as String;

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

    await _supabase.from('caregiver_permissions').update(permission.toUpdateMap()).eq('id', permission.id!);

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
    await _supabase.from('caregiver_permissions').update({'status': 'revoked'}).eq('id', id);

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