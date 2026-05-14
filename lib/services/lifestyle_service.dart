import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lifestyle_model.dart';
import 'audit_service.dart';

class LifestyleService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();

  Future<LifestyleModel?> fetchByPatient(String patientId) async {
    final row = await _supabase.from('lifestyle_factors').select().eq('patient_id', patientId).maybeSingle();
    if (row == null) return null;
    return LifestyleModel.fromMap(row);
  }

  Future<String> save({
    required LifestyleModel lifestyle,
    required String patientId,
    required String performedByUserId,
  }) async {
    final payload = LifestyleModel(
      id: lifestyle.id,
      patientId: patientId,
      livesAlone: lifestyle.livesAlone,
      hasCaregiver: lifestyle.hasCaregiver,
      stairsInHome: lifestyle.stairsInHome,
      socioeconomicClass: lifestyle.socioeconomicClass,
      workStatus: lifestyle.workStatus,
      smoking: lifestyle.smoking,
      packsPerDay: lifestyle.packsPerDay,
      smokingYears: lifestyle.smokingYears,
      drugs: lifestyle.drugs,
      drugType: lifestyle.drugType,
      drugQuantity: lifestyle.drugQuantity,
      chicha: lifestyle.chicha,
      chichaYears: lifestyle.chichaYears,
      alcoholFrequency: lifestyle.alcoholFrequency,
      foodQuality: lifestyle.foodQuality,
      milkType: lifestyle.milkType,
      waterType: lifestyle.waterType,
    );

    final existing = await _supabase.from('lifestyle_factors').select('id').eq('patient_id', patientId).maybeSingle();

    if (existing == null) {
      final inserted = await _supabase.from('lifestyle_factors').insert(payload.toInsertMap()).select('id').single();
      final id = inserted['id'].toString();

      await _audit.log(
        patientId: patientId,
        performedByUserId: performedByUserId,
        action: 'create',
        entityType: 'lifestyle_factors',
        entityId: id,
        fieldName: 'socioeconomic_class',
        newValue: payload.socioeconomicClass,
      );

      return id;
    }

    final id = existing['id'].toString();
    await _supabase.from('lifestyle_factors').update(payload.toUpdateMap()).eq('patient_id', patientId);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'update',
      entityType: 'lifestyle_factors',
      entityId: id,
      fieldName: 'socioeconomic_class',
      newValue: payload.socioeconomicClass,
    );

    return id;
  }

  Future<void> delete({
    required String patientId,
    required String performedByUserId,
  }) async {
    final existing = await _supabase.from('lifestyle_factors').select('id').eq('patient_id', patientId).maybeSingle();
    if (existing == null) return;

    final id = existing['id'].toString();
    await _supabase.from('lifestyle_factors').delete().eq('patient_id', patientId);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'delete',
      entityType: 'lifestyle_factors',
      entityId: id,
    );
  }
}