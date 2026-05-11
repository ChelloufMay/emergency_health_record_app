import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/caregiver_profile_model.dart';
import 'audit_service.dart';
import 'patient_service.dart';

class CaregiverProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();
  final PatientService _patientService = PatientService();

  Future<CaregiverProfileModel?> fetchProfile() async {
    final appUserId = await _patientService.ensureAppUserId();
    if (appUserId == null) return null;

    final row = await _supabase
        .from('caregiver_profiles')
        .select()
        .eq('user_id', appUserId)
        .maybeSingle();

    if (row == null) return null;
    return CaregiverProfileModel.fromMap(row);
  }

  /// Creates a shell row if the caregiver has no profile yet.
  /// This solves the "profile is empty" problem by giving the caregiver
  /// something to edit instead of showing a blank state forever.
  Future<CaregiverProfileModel> ensureProfileShell() async {
    final appUserId = await _patientService.ensureAppUserId();
    if (appUserId == null) {
      throw Exception('No linked app user row was found.');
    }

    final existing = await fetchProfile();
    if (existing != null) return existing;

    final userRow = await _patientService.fetchCurrentAppUserRow();
    final fullName = userRow?['full_name']?.toString().trim();

    final inserted = await _supabase.from('caregiver_profiles').insert({
      'user_id': appUserId,
      'full_name': (fullName == null || fullName.isEmpty)
          ? 'Caregiver'
          : fullName,
      'mobility': 'independent',
    }).select().single();

    return CaregiverProfileModel.fromMap(inserted);
  }

  Future<String> saveProfile({
    required CaregiverProfileModel profile,
    required String performedByUserId,
    Map<String, String?>? addressFields,
  }) async {
    final appUserId = await _patientService.ensureAppUserId();
    if (appUserId == null) {
      throw Exception('No linked app user row was found.');
    }

    // Save or update the address first, then link it back to the profile.
    final addressId = await _upsertAddress(
      addressId: profile.addressId,
      addressFields: addressFields,
    );

    final payload = {
      'user_id': appUserId,
      'full_name': profile.fullName,
      'relationship_to_patient': profile.relationshipToPatient,
      'phone': profile.phone,
      'address_id': addressId,
      'proximity': profile.proximity,
      'attendance': profile.attendance,
      'can_drive': profile.canDrive,
      'mobility': profile.mobility,
    };

    final existing = await _supabase
        .from('caregiver_profiles')
        .select('id')
        .eq('user_id', appUserId)
        .maybeSingle();

    String caregiverProfileId;

    if (existing == null) {
      final inserted = await _supabase
          .from('caregiver_profiles')
          .insert(payload)
          .select('id')
          .single();

      caregiverProfileId = inserted['id'] as String;
    } else {
      caregiverProfileId = existing['id'] as String;

      await _supabase
          .from('caregiver_profiles')
          .update(payload)
          .eq('id', caregiverProfileId);
    }

    await _audit.log(
      patientId: caregiverProfileId,
      performedByUserId: performedByUserId,
      action: existing == null ? 'create' : 'update',
      entityType: 'caregiver_profiles',
      entityId: caregiverProfileId,
      fieldName: 'full_name',
      newValue: profile.fullName,
    );

    if (addressId != null) {
      await _audit.log(
        patientId: caregiverProfileId,
        performedByUserId: performedByUserId,
        action: 'update',
        entityType: 'addresses',
        entityId: addressId,
        fieldName: 'address_id',
        newValue: addressId,
      );
    }

    return caregiverProfileId;
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