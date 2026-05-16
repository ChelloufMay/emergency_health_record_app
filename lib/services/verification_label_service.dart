import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/verification_label_model.dart';

class VerificationLabelService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<VerificationLabelModel>> fetchByPatient(String patientId) async {
    final rows = await _supabase
        .from('verification_labels')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => VerificationLabelModel.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<String> save(VerificationLabelModel label) async {
    if (label.id == null || label.id!.isEmpty) {
      final row = await _supabase
          .from('verification_labels')
          .insert(label.toInsertMap())
          .select('id')
          .single();
      return row['id'].toString();
    }

    await _supabase
        .from('verification_labels')
        .update(label.toUpdateMap())
        .eq('id', label.id!);

    return label.id!;
  }

  Future<void> delete(String id) async {
    await _supabase.from('verification_labels').delete().eq('id', id);
  }
}
