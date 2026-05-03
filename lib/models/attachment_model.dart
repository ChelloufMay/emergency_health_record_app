class AttachmentModel {
  final String id;
  final String patientId;
  final String fileName;
  final String fileKind; // lab_result, xray, scan, pdf, image, other
  final String? fileType;
  final String storagePath;
  final DateTime? documentDate;
  final String? description;
  final String? uploadedByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttachmentModel({
    required this.id,
    required this.patientId,
    required this.fileName,
    required this.fileKind,
    this.fileType,
    required this.storagePath,
    this.documentDate,
    this.description,
    this.uploadedByUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttachmentModel.fromMap(Map<String, dynamic> map) {
    return AttachmentModel(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      fileName: map['file_name'] as String,
      fileKind: map['file_kind'] as String? ?? 'other',
      fileType: map['file_type'] as String?,
      storagePath: map['storage_path'] as String,
      documentDate: map['document_date'] != null
          ? DateTime.tryParse(map['document_date'].toString())
          : null,
      description: map['description'] as String?,
      uploadedByUserId: map['uploaded_by_user_id'] as String?,
      createdAt: DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap({required String uploadedByUserId}) {
    return {
      'patient_id': patientId,
      'file_name': fileName,
      'file_kind': fileKind,
      'file_type': fileType,
      'storage_path': storagePath,
      'document_date': documentDate?.toIso8601String().split('T').first,
      'description': description,
      'uploaded_by_user_id': uploadedByUserId,
    };
  }
}