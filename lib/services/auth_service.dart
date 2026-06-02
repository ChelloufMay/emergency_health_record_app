import 'package:supabase_flutter/supabase_flutter.dart';

// Handles authentication tasks using Supabase Auth.
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Signs up a new user with the provided email, password, and optional metadata.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String fullName = '',
    String? phone,
  }) async {
    final safeFullName =
    fullName.trim().isEmpty ? email.split('@').first : fullName.trim();

    // keep auth creation separate from domain/profile logic.
    // The DB sync layer fills public.users and related tables.
    return _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: 'healthapp://auth-callback',
      data: {
        'full_name': safeFullName,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
    );
  }

  // Signs in an existing user with email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Signs out the currently authenticated user
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
  
  // Sends a password reset email to the specified user.
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'healthapp://auth-callback?type=recovery',
    );
  }
  
  // Updates the current user's password.
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword.trim()),
    );
  }
  
  // Submits a request to delete the user's account, optionally providing a reason.
  Future<void> requestAccountDeletion({String? reason}) async {
    final res = await _supabase.functions.invoke(
      'request-account-deletion',
      body: {
        'reason': reason?.trim().isEmpty == true ? null : reason?.trim(),
      },
    );
    if (res.status < 200 || res.status >= 300) {
      throw Exception('Deletion request failed');
    }
  }

  // Returns the currently authenticated user, if any.
  User? get currentUser => _supabase.auth.currentUser;

  // Returns the current authentication session, if any.
  Session? get currentSession => _supabase.auth.currentSession;
}