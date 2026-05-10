class AttachmentModel {
  // Keep the DB id here so fetched rows map cleanly.
  final String id;

  final String patientId;
  final String fileName;

  // Must match the DB enum-like values: lab_result, xray, scan, pdf, image, other
  final String fileKind;

  final String? fileType;

  // This must match the Supabase Storage object path exactly.
  // The storage policy expects the path to start with patientId/.
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
      id: map['id']?.toString() ?? '',
      patientId: map['patient_id']?.toString() ?? '',
      fileName: map['file_name']?.toString() ?? '',
      fileKind: map['file_kind']?.toString() ?? 'other',
      fileType: map['file_type']?.toString(),
      storagePath: map['storage_path']?.toString() ?? '',
      documentDate: map['document_date'] != null
          ? DateTime.tryParse(map['document_date'].toString())
          : null,
      description: map['description']?.toString(),
      uploadedByUserId: map['uploaded_by_user_id']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // Payload for the attachments table.
  // The uploadedByUserId is passed in explicitly by the service.
  // id / created_at / updated_at stay database-controlled.
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