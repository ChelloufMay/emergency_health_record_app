import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/verification_label_model.dart';
import 'service_exceptions.dart';

class VerificationLabelService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const Set<String> _allowedStatuses = {
    'unverified',
    'user_entered',
    'caregiver_entered',
    'guardian_edited',
    'clinician_verified',
  };

  static const Map<String, String> _defaultStatusByRole = {
    'owner': 'user_entered',
    'patient': 'user_entered',
    'caregiver': 'caregiver_entered',
    'guardian': 'guardian_edited',
    'clinician': 'clinician_verified',
  };

  String _normalizeRole(String? role) {
    return role == null ? '' : role.trim().toLowerCase();
  }

  String _normalizeStatus(String? status) {
    final value = status?.trim() ?? '';
    if (value.isEmpty) return 'unverified';
    return _allowedStatuses.contains(value) ? value : 'unverified';
  }

  String _roleDefaultStatus(String? role) {
    return _defaultStatusByRole[_normalizeRole(role)] ?? 'unverified';
  }

  bool _roleCanUseStatus(String? role, String status) {
    final normalizedRole = _normalizeRole(role);
    if (normalizedRole == 'clinician') {
      return _allowedStatuses.contains(status);
    }

    final defaultStatus = _roleDefaultStatus(normalizedRole);
    return status == 'unverified' || status == defaultStatus;
  }

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

    final enteredByRole = trimToNull(label.enteredByRole);
    final normalizedStatus = _normalizeStatus(label.status);

    // Role-aware normalization:
    // - clinicians can write any supported status
    // - everyone else can only persist their own role-specific status or reset to unverified
    final statusToPersist = _roleCanUseStatus(enteredByRole, normalizedStatus)
        ? normalizedStatus
        : _roleDefaultStatus(enteredByRole);

    final isClinicianVerified = statusToPersist == 'clinician_verified';

    final payload = VerificationLabelModel(
      id: label.id,
      patientId: patientId,
      entityType: entityType,
      entityId: entityId,
      fieldName: fieldName,
      status: statusToPersist,
      verifiedByUserId:
      isClinicianVerified ? trimToNull(label.verifiedByUserId) : null,
      verifiedAt: isClinicianVerified
          ? (label.verifiedAt ?? DateTime.now())
          : null,
      comment: trimToNull(label.comment),
      enteredByUserId: trimToNull(label.enteredByUserId),
      enteredByRole: enteredByRole,
      enteredByCredentials: trimToNull(
        label.enteredByCredentials ?? enteredByRole,
      ),
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
