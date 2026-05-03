class UserModel {
  final String id;
  final String authUserId;
  final String fullName;
  final String? phone;
  final String? email;
  final String role; // owner, caregiver, clinician, guardian
  final DateTime createdAt;
  final DateTime updatedAt;

  String? verificationStatus;

  UserModel({
    required this.id,
    required this.authUserId,
    required this.fullName,
    this.phone,
    this.email,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      authUserId: map['auth_user_id'] as String,
      fullName: map['full_name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      role: map['role'] as String? ?? 'owner',
      createdAt: DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'auth_user_id': authUserId,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'role': role,
    };
  }
}