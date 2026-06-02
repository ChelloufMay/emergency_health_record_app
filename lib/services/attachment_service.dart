import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/attachment_model.dart';
import 'service_exceptions.dart';

// Manages patient attachments: file uploads to storage and database records.
class AttachmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetches all attachment records for a specific patient.
  Future<List<AttachmentModel>> fetchByPatient(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return [];

    final rows = await _supabase
        .from('attachments')
        .select()
        .eq('patient_id', pid)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => AttachmentModel.fromMap(Map.from(row as Map)))
        .toList();
  }

  // Builds a unique storage path for an attachment.
  String buildStoragePath({
    required String patientId,
    required String fileName,
    String? extension,
  }) {
    final pid = requireText(patientId, 'patientId');
    final safeName = requireText(fileName, 'File name')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final ext = (extension ?? '').trim();
    final safeExt =
    ext.isEmpty ? '' : '.${ext.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')}';

    return '$pid/${DateTime.now().millisecondsSinceEpoch}_$safeName$safeExt';
  }

  // Uploads a binary file to Supabase storage.
  Future<String> uploadFile({
    required String patientId,
    required String fileName,
    required Uint8List bytes,
    String? extension,
  }) async {
    final storagePath = buildStoragePath(
      patientId: patientId,
      fileName: fileName,
      extension: extension,
    );

    try {
      await _supabase.storage.from('attachments').uploadBinary(
        storagePath,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
      return storagePath;
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Attachment upload'));
    } on StorageException catch (e) {
      throw Exception('Attachment upload failed: ${e.message}');
    }
  }

  // Saves/ creates/ updates an attachment record in the database.
  Future<String> save({
    required AttachmentModel attachment,
    required String patientId,
    required String performedByUserId,
  }) async {
    final pid = requireText(patientId, 'patientId');
    final uploaderId = requireText(performedByUserId, 'performedByUserId');
    final fileName = requireText(attachment.fileName, 'File name');
    final fileKind =
    attachment.fileKind.trim().isEmpty ? 'other' : attachment.fileKind.trim();
    final storagePath = attachment.storagePath.trim().isNotEmpty
        ? attachment.storagePath.trim()
        : buildStoragePath(patientId: pid, fileName: fileName);

    if (!storagePath.startsWith('$pid/')) {
      throw ArgumentError('Storage path must start with the patient ID.');
    }

    final payload = AttachmentModel(
      id: attachment.id,
      patientId: pid,
      fileName: fileName,
      fileKind: fileKind,
      fileType: trimToNull(attachment.fileType),
      storagePath: storagePath,
      documentDate: attachment.documentDate,
      description: trimToNull(attachment.description),
      uploadedByUserId: attachment.uploadedByUserId ?? uploaderId,
    );

    try {
      if (payload.id == null || payload.id!.isEmpty) {
        final inserted = await _supabase
            .from('attachments')
            .insert(payload.toInsertMap())
            .select('id')
            .single();
        return inserted['id'].toString();
      }

      await _supabase
          .from('attachments')
          .update(payload.toUpdateMap())
          .eq('id', payload.id!);
      return payload.id!;
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Attachment save'));
    }
  }

  // Generates a temporary signed URL or a public URL for accessing an attachment.
  Future<String> getOpenUrl(String storagePath) async {
    final path = requireText(storagePath, 'storagePath');

    try {
      return await _supabase.storage.from('attachments').createSignedUrl(
        path,
        60 * 10,
      );
    } on StorageException {
      return _supabase.storage.from('attachments').getPublicUrl(path);
    }
  }

  // Deletes an attachment record and its corresponding file in storage.
  Future<void> delete({required String patientId, required String id}) async {
    final pid = requireText(patientId, 'patientId');
    final rowId = requireText(id, 'id');

    try {
      final row = await _supabase
          .from('attachments')
          .select('storage_path')
          .eq('id', rowId)
          .maybeSingle();

      await _supabase
          .from('attachments')
          .delete()
          .eq('id', rowId)
          .eq('patient_id', pid);

      final storagePath = row?['storage_path']?.toString();
      if (storagePath != null && storagePath.isNotEmpty) {
        await _supabase.storage.from('attachments').remove([storagePath]);
      }
    } on PostgrestException catch (e) {
      throw Exception(readablePostgrestMessage(e, 'Attachment delete'));
    } on StorageException catch (e) {
      throw Exception('Attachment file delete failed: ${e.message}');
    }
  }
}