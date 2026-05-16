import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/attachment_model.dart';

class AttachmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<AttachmentModel>> fetchByPatient(String patientId) async {
    final rows = await _supabase
        .from('attachments')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => AttachmentModel.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
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
      return inserted['id'].toString();
    }

    await _supabase.from('attachments').update(payload.toUpdateMap()).eq('id', payload.id!);
    return payload.id!;
  }

  Future<void> delete({
    required String patientId,
    required String id,
  }) async {
    final row = await _supabase
        .from('attachments')
        .select('storage_path, file_name')
        .eq('id', id)
        .maybeSingle();

    await _supabase.from('attachments').delete().eq('id', id);

    if (row != null) {
      final storagePath = row['storage_path']?.toString();
      if (storagePath != null && storagePath.isNotEmpty) {
        await _supabase.storage.from('attachments').remove([storagePath]);
      }
    }
  }
}
