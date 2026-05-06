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

    final patientId = await _supabase.rpc(
      'save_my_patient_profile',
      params: {
        '_legal_id': safeProfile.legalId,
        '_first_name': safeProfile.firstName,
        '_family_name': safeProfile.familyName,
        '_sex': safeProfile.sex,
        '_date_of_birth': safeProfile.dateOfBirth?.toIso8601String().split('T').first,
        '_blood_type': safeProfile.bloodType,
        '_phone': safeProfile.phone,
        '_emergency_contact_name': safeProfile.emergencyContactName,
        '_emergency_contact_phone': safeProfile.emergencyContactPhone,
        '_insurance_plan': safeProfile.insurancePlan,
        '_covid_vaccine_type': safeProfile.covidVaccineType,
      },
    );

    final savedId = patientId?.toString();
    if (savedId == null) {
      throw Exception('Profile save failed.');
    }

    await _audit.log(
      patientId: savedId,
      performedByUserId: performedByUserId,
      action: 'update',
      entityType: 'patient_profiles',
      entityId: savedId,
      fieldName: 'first_name',
      newValue: '${safeProfile.firstName} ${safeProfile.familyName}',
    );

    return savedId;
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