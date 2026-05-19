import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final fb.User? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    fb.User? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthController extends Notifier<AuthState> {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  @override
  AuthState build() {
    _auth.authStateChanges().listen((fb.User? user) {
      state = AuthState(user: user, isLoading: false);
    });
    return AuthState(user: _auth.currentUser);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } on fb.FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message ?? 'Authentication failed.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred.',
      );
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final credentials = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credentials.user != null) {
        await credentials.user!.updateDisplayName(name.trim());
        await credentials.user!.sendEmailVerification();
        await credentials.user!.reload();
      }
      return true;
    } on fb.FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message ?? 'Registration failed.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred.',
      );
      return false;
    }
  }

  Future<bool> checkEmailVerification({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.reload();
        final updatedUser = _auth.currentUser;
        if (!silent || (updatedUser?.emailVerified ?? false)) {
          state = AuthState(user: updatedUser, isLoading: false);
        }
        return updatedUser?.emailVerified ?? false;
      }
      if (!silent) {
        state = state.copyWith(isLoading: false);
      }
      return false;
    } catch (e) {
      if (!silent) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to check verification status. Please try again.',
        );
      }
      return false;
    }
  }

  Future<bool> resendVerificationEmail() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.sendEmailVerification();
        state = state.copyWith(isLoading: false);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No active user found to verify.',
      );
      return false;
    } on fb.FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message ?? 'Failed to resend verification email.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(() {
      return AuthController();
    });
