class GuardianProfileModel {
  final String id;
  final String userId;
  final String fullName;
  final String? relationshipToPatient;
  final String? legalAuthorityNote;
  final String? phone;
  final String? addressId;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GuardianProfileModel({
    required this.id,
    required this.userId,
    required this.fullName,
    this.relationshipToPatient,
    this.legalAuthorityNote,
    this.phone,
    this.addressId,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory GuardianProfileModel.fromJson(Map<String, dynamic> json) {
    return GuardianProfileModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      relationshipToPatient: json['relationship_to_patient']?.toString(),
      legalAuthorityNote: json['legal_authority_note']?.toString(),
      phone: json['phone']?.toString(),
      addressId: json['address_id']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }
}