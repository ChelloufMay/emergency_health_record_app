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
      id: map['id']?.toString() ?? '',
      authUserId: map['auth_user_id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      phone: map['phone']?.toString(),
      email: map['email']?.toString(),
      role: map['role']?.toString() ?? 'owner',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
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