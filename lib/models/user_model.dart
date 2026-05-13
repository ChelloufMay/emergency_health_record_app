import 'model_utils.dart';

class UserModel {
  final String? id;
  final String authUserId;
  final String fullName;
  final String? phone;
  final String? email;
  final String role;
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
    'auth_user_id': authUserId,
    'full_name': fullName,
    'phone': phone,
    'email': email,
    'role': role,
  });

  Map<String, dynamic> toUpdateMap() => cleanMap({
    'full_name': fullName,
    'phone': phone,
    'email': email,
    'role': role,
  });

  Map<String, dynamic> toMap() => toInsertMap();
}