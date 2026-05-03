import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/family_doctor_model.dart';
import 'audit_service.dart';

class FamilyDoctorService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();

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
    return FamilyDoctorModel.fromMap(doctorRow);
  }

  Future<String> saveForPatient({
    required String patientId,
    required FamilyDoctorModel doctor,
    required String performedByUserId,
  }) async {
    String doctorId;

    if (doctor.id == null) {
      final inserted = await _supabase
          .from('family_doctors')
          .insert(doctor.toMap())
          .select('id')
          .single();

      doctorId = inserted['id'] as String;

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
      doctorId = doctor.id!;

      await _supabase
          .from('family_doctors')
          .update(doctor.toMap())
          .eq('id', doctorId);

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

    await _supabase
        .from('patient_profiles')
        .update({'family_doctor_id': doctorId})
        .eq('id', patientId);

    return doctorId;
  }

  Future<void> deleteForPatient({
    required String patientId,
    required String doctorId,
    required String performedByUserId,
  }) async {
    await _supabase.from('family_doctors').delete().eq('id', doctorId);

    await _supabase
        .from('patient_profiles')
        .update({'family_doctor_id': null})
        .eq('id', patientId);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'delete',
      entityType: 'family_doctors',
      entityId: doctorId,
      fieldName: 'full_name',
    );
  }
}