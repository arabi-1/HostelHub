import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/profile.dart';
import '../../../data/repositories/auth_repo.dart';
import '../../../data/repositories/profile_repo.dart';

// Repository Providers
final authRepoProvider = Provider<AuthRepo>((ref) => AuthRepo());
final profileRepoProvider = Provider<ProfileRepo>((ref) => ProfileRepo());

// Stream of Auth State changes (persisted session, sign-in, sign-out)
final authStateStreamProvider = StreamProvider<AuthState>((ref) {
  final authRepo = ref.watch(authRepoProvider);
  return authRepo.authStateChanges;
});

// Current User Provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateStreamProvider);
  return authState.value?.session?.user ?? ref.watch(authRepoProvider).currentUser;
});

// Current Profile Provider
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final profileRepo = ref.watch(profileRepoProvider);
  return profileRepo.getProfile(user.id);
});

// Auth Controller State
class AuthStateModel {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const AuthStateModel({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  AuthStateModel copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return AuthStateModel(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class AuthController extends Notifier<AuthStateModel> {
  @override
  AuthStateModel build() {
    return const AuthStateModel();
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(authRepoProvider);
      await repo.signIn(email: email.trim(), password: password);
      ref.invalidate(currentProfileProvider);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(authRepoProvider);
      await repo.signUp(
        email: email.trim(),
        password: password,
        fullName: fullName.trim(),
      );
      ref.invalidate(currentProfileProvider);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(authRepoProvider);
      await repo.signOut();
      ref.invalidate(currentProfileProvider);
      state = const AuthStateModel();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(authRepoProvider);
      await repo.sendPasswordResetEmail(email.trim());
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> verifyOtpAndResetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(authRepoProvider);
      await repo.verifyOtpAndResetPassword(
        email: email.trim(),
        token: token.trim(),
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(authRepoProvider);
      await repo.deleteAccount();
      ref.invalidate(currentProfileProvider);
      state = const AuthStateModel();
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateProfile(Profile updated) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(profileRepoProvider);
      await repo.updateProfile(updated);
      ref.invalidate(currentProfileProvider);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthStateModel>(
  AuthController.new,
);
