import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Provider for the auth service instance.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Auth state: holds the current user or null if not logged in.
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.data(null)) {
    _checkLoginStatus();
  }

  /// Check if already logged in on app start.
  Future<void> _checkLoginStatus() async {
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      final email = await _authService.getStoredEmail();
      if (email != null) {
        // We don't have full user data locally, but we know they're logged in
        state = AsyncValue.data(User(
          id: 0,
          email: email,
          createdAt: DateTime.now(),
        ));
      }
    }
  }

  /// Register with email + password.
  Future<void> register(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      final user = await _authService.register(email, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Login with email + password.
  Future<void> login(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      final user = await _authService.login(email, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Sign in with Google.
  Future<void> signInWithGoogle() async {
    try {
      state = const AsyncValue.loading();
      final user = await _authService.signInWithGoogle();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Logout.
  Future<void> logout() async {
    await _authService.logout();
    state = const AsyncValue.data(null);
  }
}

/// Provider for auth state.
final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// Convenience provider: true if user is logged in.
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.valueOrNull != null;
});
