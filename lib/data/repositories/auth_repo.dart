import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';

class AuthRepo {
  final SupabaseClient _client;

  AuthRepo([SupabaseClient? client]) : _client = client ?? supabaseClient;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.auth.signUp(
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
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> verifyOtpAndResetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> deleteAccount() async {
    await _client.rpc('delete_my_account');
    await signOut();
  }
}
