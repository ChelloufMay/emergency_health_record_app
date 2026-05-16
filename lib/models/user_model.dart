import 'model_utils.dart';

class UserModel {
  final String? id;
  final String authUserId;
  final String fullName;
  final String? phone;
  final String? email;
  final String role; // DB enum: user_role.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    this.id,
    required this.authUserId,
    required this.fullName,
    this.phone,
    this.email,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromMap(Map map) {
    return UserModel(
      id: map['id']?.toString(),
      authUserId: map['auth_user_id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      phone: map['phone']?.toString(),
      email: map['email']?.toString(),
      role: map['role']?.toString() ?? 'owner',
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() => cleanMap({
    // Used by the auth bootstrap / profile sync path.
    // The DB defaults role to owner, but keeping it here preserves the current app flow and makes service-side inserts explicit.
    'auth_user_id': authUserId,
    'full_name': fullName,
    'phone': phone,
    'email': email,
    'role': role,
  });

  Map<String, dynamic> toUpdateMap() => cleanMap({
    // The current DB grants authenticated users updates only for full_name and phone, so the model only sends those fields.
    'full_name': fullName,
    'phone': phone,
  });

  Map<String, dynamic> toMap() => toInsertMap();
}