import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/patient_profile_model.dart';
import 'audit_service.dart';
import 'patient_service.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();
  final PatientService _patientService = PatientService();

  Future<PatientProfileModel?> fetchProfile() async {
    final identity = await _patientService.resolveIdentity();
    if (identity == null) return null;

    final row = await _supabase
        .from('patient_profiles')
        .select()
        .eq('id', identity.patientId)
        .maybeSingle();

    if (row == null) return null;
    return PatientProfileModel.fromMap(row);
  }

  Future<String?> saveProfile({
    required PatientProfileModel profile,
    required String performedByUserId,
  }) async {
    final existing = await _supabase
        .from('patient_profiles')
        .select('id')
        .eq('id', profile.id)
        .maybeSingle();

    if (existing == null) {
      final inserted = await _supabase
          .from('patient_profiles')
          .insert(profile.toMap())
          .select('id')
          .single();

      final newId = inserted['id'] as String;

      await _audit.log(
        patientId: profile.id,
        performedByUserId: performedByUserId,
        action: 'create',
        entityType: 'patient_profiles',
        entityId: newId,
        fieldName: 'first_name',
        newValue: '${profile.firstName} ${profile.familyName}',
      );

      return newId;
    } else {
      await _supabase
          .from('patient_profiles')
          .update(profile.toMap())
          .eq('id', profile.id);

      await _audit.log(
        patientId: profile.id,
        performedByUserId: performedByUserId,
        action: 'update',
        entityType: 'patient_profiles',
        entityId: profile.id,
        fieldName: 'first_name',
        newValue: '${profile.firstName} ${profile.familyName}',
      );

      return profile.id;
    }
  }

  Future<String?> ensureProfileExists({
    required String userId,
    required String firstName,
    required String familyName,
    String sex = 'unknown',
  }) async {
    final existing = await _supabase
        .from('patient_profiles')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    final inserted = await _supabase.from('patient_profiles').insert({
      'user_id': userId,
      'first_name': firstName,
      'family_name': familyName,
      'sex': sex,
    }).select('id').single();

    return inserted['id'] as String;
  }
}