import 'model_utils.dart';

// Represents a user within the emergency health record system. --> maps to the 'users' table in the database.
class UserModel {
  final String? id;
  final String authUserId;
  final String fullName;
  final String? phone;
  final String? email;
  final String role; // The role assigned to the user (owner, clinician, caregiver, guardian).
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

  // Create a UserModel instance from a Map (typically from a database query result).
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

  // Convert the UserModel to a Map suitable for inserting a new record into the database.
  Map<String, dynamic> toInsertMap() => cleanMap({
    // Used by the auth bootstrap / profile sync path.
    // The DB defaults role to owner but keeping it preserves the current app flow and makes service side inserts explicit.
    'auth_user_id': authUserId,
    'full_name': fullName,
    'phone': phone,
    'email': email,
    'role': role,
  });

  // Convert the UserModel to a Map suitable for updating an existing record.
  // Only includes fields that are typically allowed to be updated by the user.
  Map<String, dynamic> toUpdateMap() => cleanMap({
    // The current DB grants authenticated users updates only for full_name and phone.
    'full_name': fullName,
    'phone': phone,
  });

  // Convert the UserModel to a Map. Defaults to the insertion map format.
  Map<String, dynamic> toMap() => toInsertMap();
}
