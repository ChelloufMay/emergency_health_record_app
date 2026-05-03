import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lifestyle_model.dart';
import 'audit_service.dart';

class LifestyleService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();

  Future<LifestyleModel?> fetchLifestyle(String patientId) async {
    final row = await _supabase
        .from('lifestyle_factors')
        .select()
        .eq('patient_id', patientId)
        .maybeSingle();

    if (row == null) return null;
    return LifestyleModel.fromMap(row);
  }

  Future<void> saveLifestyle({
    required LifestyleModel lifestyle,
    required String performedByUserId,
  }) async {
    final existing = await _supabase
        .from('lifestyle_factors')
        .select('id')
        .eq('patient_id', lifestyle.patientId)
        .maybeSingle();

    if (existing == null) {
      final inserted = await _supabase
          .from('lifestyle_factors')
          .insert(lifestyle.toMap())
          .select('id')
          .single();

      await _audit.log(
        patientId: lifestyle.patientId,
        performedByUserId: performedByUserId,
        action: 'create',
        entityType: 'lifestyle_factors',
        entityId: inserted['id'] as String,
        fieldName: 'socioeconomic_class',
        newValue: lifestyle.socioeconomicClass,
      );
    } else {
      await _supabase
          .from('lifestyle_factors')
          .update(lifestyle.toMap())
          .eq('patient_id', lifestyle.patientId);

      await _audit.log(
        patientId: lifestyle.patientId,
        performedByUserId: performedByUserId,
        action: 'update',
        entityType: 'lifestyle_factors',
        entityId: existing['id'] as String,
        fieldName: 'socioeconomic_class',
        newValue: lifestyle.socioeconomicClass,
      );
    }
  }
}