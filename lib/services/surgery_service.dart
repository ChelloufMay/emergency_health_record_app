import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/surgery_model.dart';
import 'audit_service.dart';

class SurgeryService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();

  Future<List<SurgeryModel>> fetchSurgeries(String patientId) async {
    final rows = await _supabase
        .from('surgeries')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => SurgeryModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<String> saveSurgery({
    required SurgeryModel surgery,
    required String performedByUserId,
    String? existingId,
  }) async {
    if (existingId != null) {
      await _supabase.from('surgeries').update(surgery.toMap()).eq('id', existingId);

      await _audit.log(
        patientId: surgery.patientId,
        performedByUserId: performedByUserId,
        action: 'update',
        entityType: 'surgeries',
        entityId: existingId,
        fieldName: 'surgery_name',
        newValue: surgery.surgeryName,
      );

      return existingId;
    } else {
      final result = await _supabase
          .from('surgeries')
          .insert(surgery.toMap())
          .select('id')
          .single();

      final newId = result['id'] as String;

      await _audit.log(
        patientId: surgery.patientId,
        performedByUserId: performedByUserId,
        action: 'create',
        entityType: 'surgeries',
        entityId: newId,
        fieldName: 'surgery_name',
        newValue: surgery.surgeryName,
      );

      return newId;
    }
  }

  Future<void> deleteSurgery({
    required String id,
    required String patientId,
    required String performedByUserId,
    required String surgeryName,
  }) async {
    await _supabase.from('surgeries').delete().eq('id', id);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'delete',
      entityType: 'surgeries',
      entityId: id,
      fieldName: 'surgery_name',
      oldValue: surgeryName,
    );
  }
}