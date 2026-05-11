import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Creates the Supabase Auth user and stores name + phone in metadata.
  /// The database trigger creates public.users automatically.
  ///
  /// The optional role metadata is future-proofing only.
  /// Your current DB trigger still creates the public.users row by itself.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String fullName = '',
    String? phone,
    String role = 'owner',
  }) async {
    final safeFullName =
    fullName.trim().isEmpty ? email.split('@').first : fullName.trim();

    return _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: 'healthapp://auth-callback',
      data: {
        'full_name': safeFullName,
        'role': role,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;
}