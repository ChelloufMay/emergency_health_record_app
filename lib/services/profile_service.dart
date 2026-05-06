import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/patient_profile_model.dart';
import 'audit_service.dart';
import 'patient_service.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();
  final PatientService _patientService = PatientService();

  Future<PatientProfileModel?> fetchProfile() async {
    final appUserId = await _patientService.ensureAppUserId();
    if (appUserId == null) return null;

    final row = await _supabase
        .from('patient_profiles')
        .select()
        .eq('user_id', appUserId)
        .maybeSingle();

    if (row == null) return null;
    return PatientProfileModel.fromMap(row);
  }

  Future<String?> saveProfile({
    required PatientProfileModel profile,
    required String performedByUserId,
  }) async {
    final appUserId = await _patientService.ensureAppUserId();
    if (appUserId == null) {
      throw Exception('No linked app user row was found.');
    }

    final safeProfile = PatientProfileModel(
      id: profile.id,
      userId: appUserId,
      legalId: profile.legalId,
      firstName: profile.firstName,
      familyName: profile.familyName,
      sex: profile.sex,
      dateOfBirth: profile.dateOfBirth,
      bloodType: profile.bloodType,
      phone: profile.phone,
      emergencyContactName: profile.emergencyContactName,
      emergencyContactPhone: profile.emergencyContactPhone,
      insurancePlan: profile.insurancePlan,
      covidVaccineType: profile.covidVaccineType,
      familyDoctorId: profile.familyDoctorId,
    );

    final saved = await _supabase
        .from('patient_profiles')
        .upsert(safeProfile.toInsertMap(), onConflict: 'user_id')
        .select('id')
        .single();

    final patientId = saved['id'] as String;

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'update',
      entityType: 'patient_profiles',
      entityId: patientId,
      fieldName: 'first_name',
      newValue: '${safeProfile.firstName} ${safeProfile.familyName}',
    );

    return patientId;
  }

  Future<String?> ensureProfileExists({
    required String userId,
    required String firstName,
    required String familyName,
    String sex = 'unknown',
    String? legalId,
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
      'legal_id': legalId,
      'first_name': firstName,
      'family_name': familyName,
      'sex': sex,
    }).select('id').single();

    return inserted['id'] as String;
  }
}