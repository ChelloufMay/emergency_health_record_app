import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String fullName = '',
    String? phone,
  }) async {
    final safeFullName =
    fullName.trim().isEmpty ? email.split('@').first : fullName.trim();

    // CHANGED: keep auth creation separate from domain/profile logic.
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

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // CHANGED: password recovery for any role.
  // This sends the reset link to the same deep-link flow used by the app.
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'healthapp://auth-callback',
    );
  }

  // CHANGED: shared helper for password updates inside settings.
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword.trim()),
    );
  }

  // CHANGED: secure deletion request via Edge Function.
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

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
}