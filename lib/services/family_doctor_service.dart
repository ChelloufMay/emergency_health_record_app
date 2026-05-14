import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/family_doctor_model.dart';
import 'audit_service.dart';

class FamilyDoctorService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();

  String? _trimToNull(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  Future<FamilyDoctorModel?> fetchForPatient(String patientId) async {
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
      final fetched = await _supabase.from('addresses').select().eq('id', addressId).maybeSingle();
      if (fetched != null) {
        addressRow = Map<String, dynamic>.from(fetched);
      }
    }

    return FamilyDoctorModel.fromMap({
      ...doctorRow,
      if (addressRow != null) ...addressRow,
    });
  }

  Future<String> saveForPatient({
    required String patientId,
    required FamilyDoctorModel doctor,
    required String performedByUserId,
  }) async {
    final profileRow = await _supabase
        .from('patient_profiles')
        .select('family_doctor_id')
        .eq('id', patientId)
        .maybeSingle();

    final currentDoctorId = doctor.id ?? profileRow?['family_doctor_id'] as String?;
    final country = _trimToNull(doctor.country);
    if (country == null) {
      throw Exception('Doctor office country is required.');
    }

    final addressPayload = {
      'country': country,
      'governorate': _trimToNull(doctor.governorate),
      'city': _trimToNull(doctor.city),
      'avenue': _trimToNull(doctor.avenue),
      'street': _trimToNull(doctor.street),
      'postal_code': _trimToNull(doctor.postalCode),
      'extra_details': _trimToNull(doctor.extraDetails),
      'created_by_user_id': performedByUserId,
    };

    String addressId;
    if (doctor.addressId == null) {
      final insertedAddress = await _supabase
          .from('addresses')
          .insert(addressPayload)
          .select('id')
          .single();
      addressId = insertedAddress['id'] as String;
    } else {
      await _supabase.from('addresses').update(addressPayload).eq('id', doctor.addressId!);
      addressId = doctor.addressId!;
    }

    final doctorPayload = {
      ...doctor.toDoctorMap(addressIdOverride: addressId),
      'created_by_user_id': performedByUserId,
    };

    String doctorId;
    if (currentDoctorId == null) {
      final insertedDoctor = await _supabase
          .from('family_doctors')
          .insert(doctorPayload)
          .select('id')
          .single();
      doctorId = insertedDoctor['id'] as String;

      await _audit.log(
        patientId: patientId,
        performedByUserId: performedByUserId,
        action: 'create',
        entityType: 'family_doctors',
        entityId: doctorId,
        fieldName: 'full_name',
        newValue: doctor.fullName,
      );
    } else {
      doctorId = currentDoctorId;
      await _supabase.from('family_doctors').update(doctorPayload).eq('id', doctorId);

      await _audit.log(
        patientId: patientId,
        performedByUserId: performedByUserId,
        action: 'update',
        entityType: 'family_doctors',
        entityId: doctorId,
        fieldName: 'full_name',
        newValue: doctor.fullName,
      );
    }

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
        .select('address_id, full_name, created_by_user_id')
        .eq('id', doctorId)
        .maybeSingle();
    if (doctorRow == null) return;

    final addressId = doctorRow['address_id'] as String?;
    final doctorName = doctorRow['full_name'] as String? ?? '';
    final creatorId = doctorRow['created_by_user_id']?.toString();

    await _supabase.from('family_doctors').delete().eq('id', doctorId);
    await _supabase.from('patient_profiles').update({'family_doctor_id': null}).eq('id', patientId);

    if (addressId != null && creatorId == performedByUserId) {
      await _supabase.from('addresses').delete().eq('id', addressId);
    }

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'delete',
      entityType: 'family_doctors',
      entityId: doctorId,
      fieldName: 'full_name',
      oldValue: doctorName,
    );
  }
}