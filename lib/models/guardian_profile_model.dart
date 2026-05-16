import 'model_utils.dart';

class GuardianProfileModel {
  final String? id;
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
    this.id,
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

  factory GuardianProfileModel.fromMap(Map map) {
    return GuardianProfileModel(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      relationshipToPatient: map['relationship_to_patient']?.toString(),
      legalAuthorityNote: map['legal_authority_note']?.toString(),
      phone: map['phone']?.toString(),
      addressId: map['address_id']?.toString(),
      notes: map['notes']?.toString(),
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() => cleanMap({
    'user_id': userId,
    'full_name': fullName,
    'relationship_to_patient': relationshipToPatient,
    'legal_authority_note': legalAuthorityNote,
    'phone': phone,
    'address_id': addressId,
    'notes': notes,
  });

  Map<String, dynamic> toUpdateMap() => cleanMap({
    // user_id is the ownership key and should stay fixed.
    'full_name': fullName,
    'relationship_to_patient': relationshipToPatient,
    'legal_authority_note': legalAuthorityNote,
    'phone': phone,
    'address_id': addressId,
    'notes': notes,
  });

  Map<String, dynamic> toMap() => toInsertMap();
}