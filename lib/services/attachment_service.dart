import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attachment_model.dart';
import 'audit_service.dart';

class AttachmentService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditService _audit = AuditService();

  Future<List<AttachmentModel>> fetchByPatient(String patientId) async {
    final rows = await _supabase
        .from('attachments')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List).map((row) => AttachmentModel.fromMap(row as Map)).toList();
  }

  String buildStoragePath({
    required String patientId,
    required String fileName,
  }) {
    final safeName = fileName.trim().replaceAll(RegExp(r'\s+'), '_');
    return '$patientId/$safeName';
  }

  Future<String> save({
    required AttachmentModel attachment,
    required String patientId,
    required String performedByUserId,
  }) async {
    final payload = AttachmentModel(
      id: attachment.id,
      patientId: patientId,
      fileName: attachment.fileName,
      fileKind: attachment.fileKind,
      fileType: attachment.fileType,
      storagePath: attachment.storagePath.isNotEmpty
          ? attachment.storagePath
          : buildStoragePath(patientId: patientId, fileName: attachment.fileName),
      documentDate: attachment.documentDate,
      description: attachment.description,
      uploadedByUserId: attachment.uploadedByUserId ?? performedByUserId,
    );

    if (payload.id == null || payload.id!.isEmpty) {
      final inserted = await _supabase.from('attachments').insert(payload.toInsertMap()).select('id').single();
      final id = inserted['id'].toString();

      await _audit.log(
        patientId: patientId,
        performedByUserId: performedByUserId,
        action: 'create',
        entityType: 'attachments',
        entityId: id,
        fieldName: 'file_name',
        newValue: payload.fileName,
      );

      return id;
    }

    await _supabase.from('attachments').update(payload.toUpdateMap()).eq('id', payload.id!);

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'update',
      entityType: 'attachments',
      entityId: payload.id!,
      fieldName: 'file_name',
      newValue: payload.fileName,
    );

    return payload.id!;
  }

  Future<void> delete({
    required String patientId,
    required String id,
    required String performedByUserId,
  }) async {
    final row = await _supabase.from('attachments').select('storage_path, file_name').eq('id', id).maybeSingle();

    await _supabase.from('attachments').delete().eq('id', id);

    if (row != null) {
      final storagePath = row['storage_path']?.toString();
      if (storagePath != null && storagePath.isNotEmpty) {
        await _supabase.storage.from('attachments').remove([storagePath]);
      }
    }

    await _audit.log(
      patientId: patientId,
      performedByUserId: performedByUserId,
      action: 'delete',
      entityType: 'attachments',
      entityId: id,
    );
  }
}