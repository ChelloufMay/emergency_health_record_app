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

    // Address fields are saved first into public.addresses, then the resulting address id is linked back to the patient profile.
    Map<String, String?>? addressFields,
  }) async {
    final appUserId = await _patientService.ensureAppUserId();
    if (appUserId == null) {
      throw Exception('No linked app user row was found.');
    }

    // Make sure the save always belongs to the authenticated app user.
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
      addressId: profile.addressId,
      emergencyContactName: profile.emergencyContactName,
      emergencyContactPhone: profile.emergencyContactPhone,
      insurancePlan: profile.insurancePlan,
      covidVaccineType: profile.covidVaccineType,
      familyDoctorId: profile.familyDoctorId,
    );

    final addressId = await _upsertAddress(
      addressId: safeProfile.addressId,
      addressFields: addressFields,
    );

    // This is the intended path:
    // the RPC should accept _address_id and _family_doctor_id too.
    // In case the DB function has not been updated yet, the fallback below will still save the core profile and then patch the links afterward.
    String? savedId;
    try {
      final patientId = await _supabase.rpc(
        'save_my_patient_profile',
        params: {
          '_legal_id': safeProfile.legalId,
          '_first_name': safeProfile.firstName,
          '_family_name': safeProfile.familyName,
          '_sex': safeProfile.sex,
          '_date_of_birth':
          safeProfile.dateOfBirth?.toIso8601String().split('T').first,
          '_blood_type': safeProfile.bloodType,
          '_phone': safeProfile.phone,
          '_emergency_contact_name': safeProfile.emergencyContactName,
          '_emergency_contact_phone': safeProfile.emergencyContactPhone,
          '_insurance_plan': safeProfile.insurancePlan,
          '_covid_vaccine_type': safeProfile.covidVaccineType,

          // New RPC params for the updated database function.
          '_address_id': addressId,
          '_family_doctor_id': safeProfile.familyDoctorId,
        },
      );

      savedId = patientId?.toString();
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();

      // Fallback for the older database function signature: save the profile with the legacy RPC call, then patch the link fields.
      final looksLikeSignatureMismatch =
          message.contains('function public.save_my_patient_profile') ||
              message.contains('no function matches') ||
              message.contains('could not find the function');

      if (!looksLikeSignatureMismatch) {
        rethrow;
      }

      final patientId = await _supabase.rpc(
        'save_my_patient_profile',
        params: {
          '_legal_id': safeProfile.legalId,
          '_first_name': safeProfile.firstName,
          '_family_name': safeProfile.familyName,
          '_sex': safeProfile.sex,
          '_date_of_birth':
          safeProfile.dateOfBirth?.toIso8601String().split('T').first,
          '_blood_type': safeProfile.bloodType,
          '_phone': safeProfile.phone,
          '_emergency_contact_name': safeProfile.emergencyContactName,
          '_emergency_contact_phone': safeProfile.emergencyContactPhone,
          '_insurance_plan': safeProfile.insurancePlan,
          '_covid_vaccine_type': safeProfile.covidVaccineType,
        },
      );

      savedId = patientId?.toString();
    }

    if (savedId == null) {
      throw Exception('Profile save failed.');
    }

    // Ensure the patient row stores the address link even if the legacy RPC was still in place when this function ran.
    if (addressId != null || safeProfile.familyDoctorId != null) {
      await _supabase.from('patient_profiles').update({
        if (addressId != null) 'address_id': addressId,
        if (safeProfile.familyDoctorId != null)
          'family_doctor_id': safeProfile.familyDoctorId,
      }).eq('id', savedId);
    }

    // Audit the main profile save.
    await _audit.log(
      patientId: savedId,
      performedByUserId: performedByUserId,
      action: 'update',
      entityType: 'patient_profiles',
      entityId: savedId,
      fieldName: 'first_name',
      newValue: '${safeProfile.firstName} ${safeProfile.familyName}',
    );

    // Audit the address link separately so the history is clearer.
    if (addressId != null) {
      await _audit.log(
        patientId: savedId,
        performedByUserId: performedByUserId,
        action: 'update',
        entityType: 'addresses',
        entityId: addressId,
        fieldName: 'address_id',
        newValue: addressId,
      );
    }

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

  Future<String?> _upsertAddress({
    required String? addressId,
    required Map<String, String?>? addressFields,
  }) async {
    if (addressFields == null) return addressId;

    final country = _clean(addressFields['country']);
    final governorate = _clean(addressFields['governorate']);
    final city = _clean(addressFields['city']);
    final avenue = _clean(addressFields['avenue']);
    final street = _clean(addressFields['street']);
    final postalCode = _clean(addressFields['postal_code']);
    final extraDetails = _clean(addressFields['extra_details']);

    final hasAnyValue = [
      country,
      governorate,
      city,
      avenue,
      street,
      postalCode,
      extraDetails,
    ].any((value) => value != null && value.isNotEmpty);

    // If the form is fully empty, keep the existing address link as-is.
    if (!hasAnyValue) return addressId;

    final payload = <String, dynamic>{
      'country': country ?? 'Unknown',
      'governorate': governorate,
      'city': city,
      'avenue': avenue,
      'street': street,
      'postal_code': postalCode,
      'extra_details': extraDetails,
    };

    if (addressId != null && addressId.isNotEmpty) {
      await _supabase.from('addresses').update(payload).eq('id', addressId);
      return addressId;
    }

    final inserted = await _supabase
        .from('addresses')
        .insert(payload)
        .select('id')
        .single();

    return inserted['id']?.toString();
  }

  String? _clean(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
