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

  Future<AddressModel?> fetchAddress(String? addressId) async {
    if (addressId == null || addressId.trim().isEmpty) return null;

    final row = await _supabase
        .from('addresses')
        .select()
        .eq('id', addressId)
        .maybeSingle();

    if (row == null) return null;
    return AddressModel.fromMap(Map<String, dynamic>.from(row));
  }

  Future<String> saveCoreProfile({
    required PatientProfileModel profile,
    required String performedByUserId,
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

    // Important: call the PRIVATE schema version directly.
    // Your public wrapper is STABLE/read-only, which is what triggers the
    // "cannot execute INSERT in a read-only transaction" error.
    final patientId = await _supabase.schema('private_api').rpc(
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

    final savedId = patientId?.toString();
    if (savedId == null || savedId.isEmpty) {
      throw Exception('Profile save failed.');
    }

    return savedId;
  }

  Future<String?> saveAddress({
    required Map<String, dynamic> addressFields,
    String? addressId,
  }) async {
    final model = AddressModel(
      id: addressId,
      country: (addressFields['country']?.toString().trim().isNotEmpty == true)
          ? addressFields['country'].toString().trim()
          : 'Tunisia',
      governorate: addressFields['governorate']?.toString().trim().isEmpty == true
          ? null
          : addressFields['governorate']?.toString().trim(),
      city: addressFields['city']?.toString().trim().isEmpty == true
          ? null
          : addressFields['city']?.toString().trim(),
      avenue: addressFields['avenue']?.toString().trim().isEmpty == true
          ? null
          : addressFields['avenue']?.toString().trim(),
      street: addressFields['street']?.toString().trim().isEmpty == true
          ? null
          : addressFields['street']?.toString().trim(),
      postalCode: addressFields['postal_code']?.toString().trim().isEmpty == true
          ? null
          : addressFields['postal_code']?.toString().trim(),
      extraDetails:
      addressFields['extra_details']?.toString().trim().isEmpty == true
          ? null
          : addressFields['extra_details']?.toString().trim(),
    );

    final hasAnyValue = [
      model.country,
      model.governorate,
      model.city,
      model.avenue,
      model.street,
      model.postalCode,
      model.extraDetails,
    ].any((v) => v != null && v.toString().trim().isNotEmpty);

    if (!hasAnyValue) return addressId;

    if (addressId != null && addressId.isNotEmpty) {
      await _supabase.from('addresses').update(model.toUpdateMap()).eq('id', addressId);
      return addressId;
    }

    final inserted = await _supabase
        .from('addresses')
        .insert(model.toInsertMap())
        .select('id')
        .single();

    return inserted['id']?.toString();
  }

  Future<void> linkAddressToProfile({
    required String patientId,
    String? addressId,
  }) async {
    if (addressId == null || addressId.trim().isEmpty) return;

    await _supabase.from('patient_profiles').update({
      'address_id': addressId,
    }).eq('id', patientId);
  }
}