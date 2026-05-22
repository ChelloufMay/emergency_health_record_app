import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/verification_label_model.dart';
import 'service_exceptions.dart';

class VerificationLabelService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<VerificationLabelModel>> fetchByPatient(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return [];

    final rows = await _supabase
        .from('verification_labels')
        .select()
        .eq('patient_id', pid)
        .order('created_at', ascending: false);

    return (rows as List)
        .map(
          (row) => VerificationLabelModel.fromMap(
        Map<String, dynamic>.from(row as Map),
      ),
    )
        .toList();
  }

  Future<String> save(VerificationLabelModel label) async {
    final patientId = requireText(label.patientId, 'patientId');
    final entityType = requireText(label.entityType, 'Entity type');
    final entityId = requireText(label.entityId, 'Entity ID');
    final fieldName = requireText(label.fieldName, 'Field name');

    // Keep the status aligned with the DB enum-like values.
    final status = label.status.trim().isEmpty ? 'unverified' : label.status.trim();
    const allowedStatuses = {
      'unverified',
      'user_entered',
      'caregiver_entered',
      'clinician_verified',
    };
    final normalizedStatus = allowedStatuses.contains(status) ? status : 'unverified';

    // Only clinician-verified labels are allowed to keep verification metadata.
    final isClinicianVerified = normalizedStatus == 'clinician_verified';

    final payload = VerificationLabelModel(
      id: label.id,
      patientId: patientId,
      entityType: entityType,
      entityId: entityId,
      fieldName: fieldName,
      status: normalizedStatus,
      verifiedByUserId: isClinicianVerified ? trimToNull(label.verifiedByUserId) : null,
      verifiedAt: isClinicianVerified
          ? (label.verifiedAt ?? DateTime.now())
          : null,
      comment: trimToNull(label.comment),
      enteredByUserId: trimToNull(label.enteredByUserId),
      enteredByRole: trimToNull(label.enteredByRole),
      enteredByCredentials: trimToNull(label.enteredByCredentials),
    );

    try {
      if (payload.id == null || payload.id!.isEmpty) {
        final row = await _supabase
            .from('verification_labels')
            .insert(payload.toInsertMap())
            .select('id')
            .single();
        return row['id'].toString();
      }

      await _supabase
          .from('verification_labels')
          .update(payload.toUpdateMap())
          .eq('id', payload.id!);

      return payload.id!;
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Verification label save'));
    }
  }

  Future<void> delete({required String patientId, required String id}) async {
    final pid = requireText(patientId, 'patientId');
    final rowId = requireText(id, 'id');

    try {
      await _supabase
          .from('verification_labels')
          .delete()
          .eq('id', rowId)
          .eq('patient_id', pid);
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Verification label delete'));
    }
  }
}