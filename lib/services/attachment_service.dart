import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/attachment_model.dart';
import 'audit_service.dart';

class AttachmentService {
  static const String _bucketName = 'attachments';

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
      // Update the DB row only; the storage object itself is separate.
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

  Future<String> uploadAttachment({
    required String patientId,
    required String uploadedByUserId,
    required PlatformFile file,
    required String fileKind,
    String? fileName,
    String? description,
  }) async {
    final bytes = file.bytes;
    if (bytes == null) {
      throw StateError(
        'The selected file does not contain bytes. Pick the file with withData: true.',
      );
    }

    // Keep the saved filename safe for both Storage and DB text fields.
    final safeFileName = _sanitizeFileName(
      (fileName ?? file.name).trim().isEmpty ? file.name : (fileName ?? file.name),
    );

    // This path is important:
    // - it starts with the patient id
    // - it matches the storage policy
    // - it is stored in the attachments table as-is
    final storagePath =
        '$patientId/${DateTime.now().microsecondsSinceEpoch}_$safeFileName';

    final mimeType = _guessContentType(safeFileName);
    final today = DateTime.now().toIso8601String().split('T').first;

    try {
      // Upload the actual file bytes first.
      await _supabase.storage.from(_bucketName).uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(
          contentType: mimeType,
          upsert: false,
        ),
      );

      // Then insert the metadata row that points to that storage object.
      final result = await _supabase.from('attachments').insert({
        'patient_id': patientId,
        'file_name': safeFileName,
        'file_kind': fileKind,
        'file_type': mimeType,
        'storage_path': storagePath,
        'document_date': today,
        'description':
        (description != null && description.trim().isNotEmpty)
            ? description.trim()
            : null,
        'uploaded_by_user_id': uploadedByUserId,
      }).select('id').single();

      final newId = result['id'] as String;

      await _audit.log(
        patientId: patientId,
        performedByUserId: uploadedByUserId,
        action: 'create',
        entityType: 'attachments',
        entityId: newId,
        fieldName: 'file_name',
        newValue: safeFileName,
      );

      return newId;
    } catch (e) {
      // If the DB insert fails after upload, remove the uploaded file so Storage and the table do not drift out of sync.
      try {
        await _supabase.storage.from(_bucketName).remove([storagePath]);
      } catch (_) {
        // ignore cleanup failure
      }
      rethrow;
    }
  }

  Future<String> getAttachmentSignedUrl(String storagePath) async {
    // The DB storage_path must be the same value used here.
    return _supabase.storage
        .from(_bucketName)
        .createSignedUrl(storagePath, 60 * 10);
  }

  Future<void> deleteAttachment({
    required String id,
    required String patientId,
    required String performedByUserId,
    required String fileName,
    required String storagePath,
  }) async {
    // Delete the Storage object first, then the DB row.
    // This keeps the file and metadata in sync.
    await _supabase.storage.from(_bucketName).remove([storagePath]);

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

  String _sanitizeFileName(String input) {
    final cleaned = input.trim().replaceAll(RegExp(r'[\\\/:*?"<>|]'), '_');
    return cleaned.isEmpty ? 'attachment_file' : cleaned;
  }

  String _guessContentType(String fileName) {
    final lower = fileName.toLowerCase();

    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    if (lower.endsWith('.tif') || lower.endsWith('.tiff')) {
      return 'image/tiff';
    }

    return 'application/octet-stream';
  }
}