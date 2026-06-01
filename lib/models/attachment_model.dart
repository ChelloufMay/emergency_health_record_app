import 'model_utils.dart';

// Represents an attachment or document associated with a patient's record. --> maps to the 'attachments' table in the database.
class AttachmentModel {
  final String? id;
  final String patientId;
  final String fileName;
  final String fileKind;
  final String? fileType;
  final String storagePath;
  final DateTime? documentDate;
  final String? description;
  final String? uploadedByUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AttachmentModel({
    this.id,
    required this.patientId,
    required this.fileName,
    required this.fileKind,
    required this.storagePath,
    this.fileType,
    this.documentDate,
    this.description,
    this.uploadedByUserId,
    this.createdAt,
    this.updatedAt,
  });

  // Formats a DateTime to a YYYY-MM-DD string format for database compatibility.
  static String? _dateOnly(DateTime? value) {
    if (value == null) return null;
    return value.toIso8601String().split('T').first;
  }

  factory AttachmentModel.fromMap(Map map) {
    return AttachmentModel(
      id: map['id']?.toString(),
      patientId: map['patient_id']?.toString() ?? '',
      fileName: map['file_name']?.toString() ?? '',
      fileKind: map['file_kind']?.toString() ?? 'other',
      fileType: map['file_type']?.toString(),
      storagePath: map['storage_path']?.toString() ?? '',
      documentDate: asDateTime(map['document_date']),
      description: map['description']?.toString(),
      uploadedByUserId: map['uploaded_by_user_id']?.toString(),
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() => cleanMap({
    'patient_id': patientId,
    'file_name': fileName,
    'file_kind': fileKind,
    'file_type': fileType,
    'storage_path': storagePath,
    'document_date': _dateOnly(documentDate),
    'description': description,
    'uploaded_by_user_id': uploadedByUserId,
  });

  Map<String, dynamic> toUpdateMap() => cleanMap({
    // Ownership fields stay fixed.
    'file_name': fileName,
    'file_kind': fileKind,
    'file_type': fileType,
    'storage_path': storagePath,
    'document_date': _dateOnly(documentDate),
    'description': description,
  });

  Map<String, dynamic> toMap() => toInsertMap();
}
