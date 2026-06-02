import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/allergy_model.dart';
import 'audit_write_service.dart';
import 'service_exceptions.dart';

// A service that handles CRUD operations for patient allergy records.
class AllergyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetches all allergy records for a specific patient.
  Future<List<AllergyModel>> fetchByPatient(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return [];

    final rows = await _supabase
        .from('allergies')
        .select()
        .eq('patient_id', pid)
        .order('created_at', ascending: false);

    return (rows as List)
        .map(
          (row) => AllergyModel.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  // Saves/ creates/ updates) an allergy record and records an audit log.
  Future<String> save({
    required AllergyModel allergy,
    required String patientId,
    String? actorUserId,
    String? actorRole,
  }) async {
    final pid = requireText(patientId, 'patientId');
    final allergen = requireText(allergy.allergenName, 'Allergen name');

    final payload = AllergyModel(
      id: allergy.id,
      patientId: pid,
      allergenName: allergen,
      allergyType: allergy.allergyType.trim().isEmpty
          ? 'other'
          : allergy.allergyType.trim(),
      reaction: trimToNull(allergy.reaction),
      severity: trimToNull(allergy.severity),
      source: allergy.source.trim().isEmpty ? 'user' : allergy.source.trim(),
    );

    try {
      if (payload.id == null || payload.id!.isEmpty) {
        final inserted = await _supabase
            .from('allergies')
            .insert(payload.toInsertMap())
            .select('id')
            .single();

        final newId = inserted['id'].toString();
        await AuditWriteService.instance.recordIfNeeded(
          patientId: pid,
          action: 'create',
          entityType: 'allergies',
          entityId: newId,
          performedByUserId: actorUserId,
          actorRole: actorRole,
        );
        return newId;
      }

      await _supabase
          .from('allergies')
          .update(payload.toUpdateMap())
          .eq('id', payload.id!);

      await AuditWriteService.instance.recordIfNeeded(
        patientId: pid,
        action: 'update',
        entityType: 'allergies',
        entityId: payload.id,
        performedByUserId: actorUserId,
        actorRole: actorRole,
      );
      return payload.id!;
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Allergy save'));
    }
  }

  // Deletes an allergy record and records an audit log.
  Future<void> delete({
    required String patientId,
    required String id,
    String? actorUserId,
    String? actorRole,
  }) async {
    final pid = requireText(patientId, 'patientId');
    final rowId = requireText(id, 'id');

    try {
      await _supabase
          .from('allergies')
          .delete()
          .eq('id', rowId)
          .eq('patient_id', pid);

      await AuditWriteService.instance.recordIfNeeded(
        patientId: pid,
        action: 'delete',
        entityType: 'allergies',
        entityId: rowId,
        performedByUserId: actorUserId,
        actorRole: actorRole,
      );
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Allergy delete'));
    }
  }
}
