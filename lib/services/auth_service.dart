import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String fullName = '',
    String? phone,
  }) async {
    final safeFullName = fullName.trim().isEmpty
        ? email.split('@').first
        : fullName.trim();

    // The auth user is created here; the database sync/trigger layer fills public.users.
    return _supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'healthapp://auth-callback',
      data: {
        'full_name': safeFullName,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;

  Session? get currentSession => _supabase.auth.currentSession;
}
