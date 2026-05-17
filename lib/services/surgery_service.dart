import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/surgery_model.dart';

class SurgeryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<SurgeryModel>> fetchByPatient(String patientId) async {
    final rows = await _supabase
        .from('surgeries')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => SurgeryModel.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<String> save({
    required SurgeryModel surgery,
    required String patientId,
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
      return inserted['id'].toString();
    }

    await _supabase.from('surgeries').update(payload.toUpdateMap()).eq('id', payload.id!);
    return payload.id!;
  }

  Future<void> delete({
    required String patientId,
    required String id,
  }) async {
    await _supabase.from('surgeries').delete().eq('id', id).eq('patient_id', patientId);
  }
}
