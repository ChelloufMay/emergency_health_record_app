import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attachment_model.dart';
import 'audit_service.dart';

class AttachmentService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();

  Future<List<AttachmentModel>> fetchAttachments(String patientId) async {
    final rows = await _supabase
        .from('attachments')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => AttachmentModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<String> saveAttachment({
    required AttachmentModel attachment,
    required String uploadedByUserId,
    String? existingId,
  }) async {
    if (existingId != null) {
      await _supabase
          .from('attachments')
          .update(attachment.toMap(uploadedByUserId: uploadedByUserId))
          .eq('id', existingId);

      await _audit.log(
        patientId: attachment.patientId,
        performedByUserId: uploadedByUserId,
        action: 'update',
        entityType: 'attachments',
        entityId: existingId,
        fieldName: 'file_name',
        newValue: attachment.fileName,
      );

      return existingId;
    } else {
      final result = await _supabase
          .from('attachments')
          .insert(attachment.toMap(uploadedByUserId: uploadedByUserId))
          .select('id')
          .single();

      final newId = result['id'] as String;

      await _audit.log(
        patientId: attachment.patientId,
        performedByUserId: uploadedByUserId,
        action: 'create',
        entityType: 'attachments',
        entityId: newId,
        fieldName: 'file_name',
        newValue: attachment.fileName,
      );

      return newId;
    }
  }

  Future<void> deleteAttachment({
    required String id,
    required String patientId,
    required String performedByUserId,
    required String fileName,
  }) async {
    await _supabase.from('attachments').delete().eq('id', id);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'delete',
      entityType: 'attachments',
      entityId: id,
      fieldName: 'file_name',
      oldValue: fileName,
    );
  }
}