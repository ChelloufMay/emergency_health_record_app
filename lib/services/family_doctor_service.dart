import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/address_model.dart';
import '../models/family_doctor_model.dart';
import '../models/family_doctor_with_address_model.dart';

class FamilyDoctorService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _trimToNull(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  Future<FamilyDoctorWithAddressModel?> fetchForPatient(String patientId) async {
    final profileRow = await _supabase
        .from('patient_profiles')
        .select('family_doctor_id')
        .eq('id', patientId)
        .maybeSingle();

    if (profileRow == null) return null;

    final doctorId = profileRow['family_doctor_id'] as String?;
    if (doctorId == null) return null;

    final doctorRow = await _supabase
        .from('family_doctors')
        .select()
        .eq('id', doctorId)
        .maybeSingle();

    if (doctorRow == null) return null;

    final addressId = doctorRow['address_id'] as String?;
    Map<String, dynamic>? addressRow;
    if (addressId != null) {
      final rawAddress = await _supabase
          .from('addresses')
          .select()
          .eq('id', addressId)
          .maybeSingle();
      if (rawAddress != null) {
        addressRow = Map<String, dynamic>.from(rawAddress);
      }
    }

    return FamilyDoctorWithAddressModel.fromMap({
      ...Map<String, dynamic>.from(doctorRow),
      if (addressRow != null) ...addressRow,
    });
  }

  Future<String> saveForPatient({
    required String patientId,
    required FamilyDoctorModel doctor,
    Map<String, dynamic>? addressFields,
    required String performedByUserId,
  }) async {
    final profileRow = await _supabase
        .from('patient_profiles')
        .select('family_doctor_id')
        .eq('id', patientId)
        .maybeSingle();

    final currentDoctorId = doctor.id ?? profileRow?['family_doctor_id'] as String?;

    String? existingAddressId;
    if (currentDoctorId != null) {
      final existingDoctor = await _supabase
          .from('family_doctors')
          .select('address_id')
          .eq('id', currentDoctorId)
          .maybeSingle();
      existingAddressId = existingDoctor?['address_id']?.toString();
    }

    String? addressIdToUse = doctor.addressId ?? existingAddressId;

    if (addressFields != null && addressFields.isNotEmpty) {
      final country = _trimToNull(addressFields['country']?.toString()) ?? 'Unknown';

      final addressModel = AddressModel(
        id: addressIdToUse,
        country: country,
        governorate: _trimToNull(addressFields['governorate']?.toString()),
        city: _trimToNull(addressFields['city']?.toString()),
        avenue: _trimToNull(addressFields['avenue']?.toString()),
        street: _trimToNull(addressFields['street']?.toString()),
        postalCode: _trimToNull(addressFields['postal_code']?.toString()),
        extraDetails: _trimToNull(addressFields['extra_details']?.toString()),
      );

      final hasAnyValue = [
        addressModel.country,
        addressModel.governorate,
        addressModel.city,
        addressModel.avenue,
        addressModel.street,
        addressModel.postalCode,
        addressModel.extraDetails,
      ].any((v) => v != null && v.toString().isNotEmpty);

      if (hasAnyValue) {
        if (addressModel.id == null || addressModel.id!.isEmpty) {
          final insertedAddress = await _supabase
              .from('addresses')
              .insert(addressModel.toInsertMap())
              .select('id')
              .single();
          addressIdToUse = insertedAddress['id'].toString();
        } else {
          await _supabase.from('addresses').update(addressModel.toUpdateMap()).eq('id', addressModel.id!);
          addressIdToUse = addressModel.id;
        }
      }
    }

    final doctorPayload = FamilyDoctorModel(
      id: currentDoctorId,
      fullName: doctor.fullName,
      phone: doctor.phone,
      addressId: addressIdToUse,
      medicalLicenseNumber: doctor.medicalLicenseNumber,
      firstSeenDate: doctor.firstSeenDate,
      notes: doctor.notes,
      createdByUserId: doctor.createdByUserId,
    );

    String doctorId;
    if (currentDoctorId == null) {
      final insertedDoctor = await _supabase
          .from('family_doctors')
          .insert(doctorPayload.toInsertMap())
          .select('id')
          .single();
      doctorId = insertedDoctor['id'].toString();
    } else {
      doctorId = currentDoctorId;
      await _supabase.from('family_doctors').update(doctorPayload.toUpdateMap()).eq('id', doctorId);
    }

    // The family doctor link lives on public.patient_profiles, so that update stays owner-only.
    await _supabase.from('patient_profiles').update({'family_doctor_id': doctorId}).eq('id', patientId);

    return doctorId;
  }

  Future<void> deleteForPatient({
    required String patientId,
    required String doctorId,
    required String performedByUserId,
  }) async {
    final doctorRow = await _supabase
        .from('family_doctors')
        .select('address_id, full_name')
        .eq('id', doctorId)
        .maybeSingle();

    if (doctorRow == null) return;

    final addressId = doctorRow['address_id'] as String?;
    await _supabase.from('family_doctors').delete().eq('id', doctorId);
    await _supabase.from('patient_profiles').update({'family_doctor_id': null}).eq('id', patientId);

    if (addressId != null) {
      await _supabase.from('addresses').delete().eq('id', addressId);
    }
  }
}
