import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/address_model.dart';
import '../models/patient_profile_model.dart';
import 'patient_service.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;
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
    return PatientProfileModel.fromMap(Map<String, dynamic>.from(row));
  }

  Future<String> saveProfile({
    required PatientProfileModel profile,
    required String performedByUserId,
    Map<String, dynamic>? addressFields,
  }) async {
    if (performedByUserId.trim().isEmpty) {
      throw Exception('Missing performedByUserId.');
    }

    final appUserId = await _patientService.ensureAppUserId(
      fullName: '${profile.firstName} ${profile.familyName}',
      phone: profile.phone,
    );

    if (appUserId == null) {
      throw Exception('No linked app user row was found.');
    }

    final safeProfile = PatientProfileModel(
      id: profile.id,
      userId: appUserId,
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

    final savedPatientId = await _supabase
        .schema('public')
        .rpc(
          'save_my_patient_profile',
          params: {
            '_first_name': safeProfile.firstName,
            '_family_name': safeProfile.familyName,
            '_sex': safeProfile.sex,
            '_date_of_birth': safeProfile.dateOfBirth
                ?.toIso8601String()
                .split('T')
                .first,
            '_blood_type': safeProfile.bloodType,
            '_phone': safeProfile.phone,
            '_emergency_contact_name': safeProfile.emergencyContactName,
            '_emergency_contact_phone': safeProfile.emergencyContactPhone,
            '_insurance_plan': safeProfile.insurancePlan,
            '_covid_vaccine_type': safeProfile.covidVaccineType,
          },
        );

    final savedId = savedPatientId?.toString();
    if (savedId == null || savedId.isEmpty) {
      throw Exception('Profile save failed.');
    }

    final addressId = await _upsertAddress(
      addressId: safeProfile.addressId,
      addressFields: addressFields,
    );

    if (addressId != null || safeProfile.familyDoctorId != null) {
      final updateData = <String, dynamic>{};

      if (addressId != null) {
        updateData['address_id'] = addressId;
      }
      if (safeProfile.familyDoctorId != null) {
        updateData['family_doctor_id'] = safeProfile.familyDoctorId;
      }

      if (updateData.isNotEmpty) {
        await _supabase
            .from('patient_profiles')
            .update(updateData)
            .eq('id', savedId);
      }
    }

    return savedId;
  }

  Future<String> ensureProfileExists({
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

    if (existing != null) return existing['id'] as String;

    final inserted = await _supabase
        .from('patient_profiles')
        .insert({
          'user_id': userId,
          'first_name': firstName,
          'family_name': familyName,
          'sex': sex,
        })
        .select('id')
        .single();

    return inserted['id'] as String;
  }

  Future<String?> _upsertAddress({
    required String? addressId,
    required Map<String, dynamic>? addressFields,
  }) async {
    if (addressFields == null || addressFields.isEmpty) return addressId;

    final model = AddressModel(
      id: addressId,
      country: addressFields['country']?.toString().trim().isNotEmpty == true
          ? addressFields['country'].toString().trim()
          : 'Unknown',
      governorate: addressFields['governorate']?.toString(),
      city: addressFields['city']?.toString(),
      avenue: addressFields['avenue']?.toString(),
      street: addressFields['street']?.toString(),
      postalCode: addressFields['postal_code']?.toString(),
      extraDetails: addressFields['extra_details']?.toString(),
    );

    final hasAnyValue = [
      model.country,
      model.governorate,
      model.city,
      model.avenue,
      model.street,
      model.postalCode,
      model.extraDetails,
    ].any((v) => v != null && v.toString().isNotEmpty);

    if (!hasAnyValue) return addressId;

    if (addressId != null && addressId.isNotEmpty) {
      await _supabase
          .from('addresses')
          .update(model.toUpdateMap())
          .eq('id', addressId);
      return addressId;
    }

    final inserted = await _supabase
        .from('addresses')
        .insert(model.toInsertMap())
        .select('id')
        .single();
    return inserted['id']?.toString();
  }
}
