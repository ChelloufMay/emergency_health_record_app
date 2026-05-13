import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) {
    return _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
    );
  }

  Future<void> signOut() => _supabase.auth.signOut();
}