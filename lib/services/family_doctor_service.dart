import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/family_doctor_model.dart';
import '../models/family_doctor_with_address_model.dart';
import 'service_exceptions.dart';

class FamilyDoctorService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _trimToNull(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  Future<FamilyDoctorWithAddressModel?> fetchForPatient(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return null;

    final profileRow = await _supabase
        .from('patient_profiles')
        .select('family_doctor_id')
        .eq('id', pid)
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
    required String performedByUserId, // kept for client-side consistency
  }) async {
    final pid = requireText(patientId, 'patientId');
    final fullName = requireText(doctor.fullName, 'Family doctor name');

    try {
      final result = await _supabase.rpc(
        'save_family_doctor_for_patient',
        params: {
          '_patient_id': pid,
          '_doctor_id': doctor.id,
          '_full_name': fullName,
          '_phone': _trimToNull(doctor.phone),
          '_address_id': doctor.addressId,
          '_country': _trimToNull(addressFields?['country']?.toString()),
          '_governorate': _trimToNull(addressFields?['governorate']?.toString()),
          '_city': _trimToNull(addressFields?['city']?.toString()),
          '_avenue': _trimToNull(addressFields?['avenue']?.toString()),
          '_street': _trimToNull(addressFields?['street']?.toString()),
          '_postal_code': _trimToNull(addressFields?['postal_code']?.toString()),
          '_extra_details': _trimToNull(addressFields?['extra_details']?.toString()),
          '_medical_license_number': _trimToNull(doctor.medicalLicenseNumber),
          '_first_seen_date': doctor.firstSeenDate?.toIso8601String().split('T').first,
          '_notes': _trimToNull(doctor.notes),
        },
      );
      return result.toString();
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Family doctor save'));
    }
  }

  Future<void> deleteForPatient({
    required String patientId,
    required String doctorId,
    required String performedByUserId, // kept for client-side consistency
  }) async {
    final pid = requireText(patientId, 'patientId');
    final rowId = requireText(doctorId, 'doctorId');

    try {
      await _supabase.rpc(
        'delete_family_doctor_for_patient',
        params: {'_patient_id': pid, '_doctor_id': rowId},
      );
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Family doctor delete'));
    }
  }
}