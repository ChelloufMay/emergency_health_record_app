import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/surgery_model.dart';
import 'audit_service.dart';

class SurgeryService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();

  Future<List<SurgeryModel>> fetchByPatient(String patientId) async {
    final rows = await _supabase
        .from('surgeries')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List).map((row) => SurgeryModel.fromMap(row as Map)).toList();
  }

  Future<String> save({
    required SurgeryModel surgery,
    required String patientId,
    required String performedByUserId,
  }) async {
    final payload = SurgeryModel(
      id: surgery.id,
      patientId: patientId,
      surgeryName: surgery.surgeryName,
      surgeryDate: surgery.surgeryDate,
      place: surgery.place,
      prostheticOrImplant: surgery.prostheticOrImplant,
      notes: surgery.notes,
    );

    if (payload.id == null || payload.id!.isEmpty) {
      final inserted = await _supabase.from('surgeries').insert(payload.toInsertMap()).select('id').single();
      final id = inserted['id'].toString();

      await _audit.log(
        patientId: patientId,
        performedByUserId: performedByUserId,
        action: 'create',
        entityType: 'surgeries',
        entityId: id,
        fieldName: 'surgery_name',
        newValue: payload.surgeryName,
      );

      return id;
    }

    await _supabase.from('surgeries').update(payload.toUpdateMap()).eq('id', payload.id!);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'update',
      entityType: 'surgeries',
      entityId: payload.id!,
      fieldName: 'surgery_name',
      newValue: payload.surgeryName,
    );

    return payload.id!;
  }

  Future<void> delete({
    required String patientId,
    required String id,
    required String performedByUserId,
  }) async {
    await _supabase.from('surgeries').delete().eq('id', id);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'delete',
      entityType: 'surgeries',
      entityId: id,
    );
  }
}