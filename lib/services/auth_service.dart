import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Creates the Supabase Auth user and stores name + phone in metadata.
  ///
  /// Important:
  /// - public.users is created automatically by the database trigger now.
  /// - The redirect URL must be allowed in Supabase Auth settings.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String fullName = '',
    String? phone,
  }) async {
    // Keep a safe display name even if the user leaves the field blank.
    final safeFullName =
    fullName.trim().isEmpty ? email.split('@').first : fullName.trim();

    return _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      // This must match:
      // 1) the Supabase Redirect URLs allow-list
      // 2) the native deep-link setup in Android/iOS
      emailRedirectTo: 'healthapp://auth-callback',
      data: {
        'full_name': safeFullName,
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