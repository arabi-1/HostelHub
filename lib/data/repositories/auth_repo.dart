import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/env.dart';
import '../supabase_client.dart';

class AuthRepo {
  final SupabaseClient? _client;

  AuthRepo([SupabaseClient? client])
      : _client = client ?? (Env.isConfigured ? supabaseClientOrNull : null);

  User? get currentUser => _client?.auth.currentUser;
  Session? get currentSession => _client?.auth.currentSession;
  Stream<AuthState> get authStateChanges =>
      _client != null ? _client.auth.onAuthStateChange : const Stream.empty();

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final client = _client ?? supabaseClient;
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final client = _client ?? supabaseClient;
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  Future<void> signOut() async {
    final client = _client ?? supabaseClient;
    await client.auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final client = _client ?? supabaseClient;
    await client.auth.resetPasswordForEmail(email);
  }

  Future<void> verifyOtpAndResetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final client = _client ?? supabaseClient;
    await client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
    await client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> deleteAccount() async {
    final client = _client ?? supabaseClient;
    await client.rpc('delete_my_account');
    await signOut();
  }
}
