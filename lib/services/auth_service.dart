import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> signUp({
    required String email,
    required String password,
    String fullName = '',
    String? phone,
    String role = 'owner',
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final authUser = response.user;
    if (authUser == null) {
      throw Exception('Account creation failed.');
    }

    final safeFullName =
    fullName.trim().isEmpty ? email.split('@').first : fullName.trim();

    await _supabase.from('users').insert({
      'auth_user_id': authUser.id,
      'full_name': safeFullName,
      'phone': phone,
      'email': email,
      'role': role,
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;
}