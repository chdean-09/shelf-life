import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import 'api_client.dart';

/// Service handling authentication (email/password + Google OAuth).
class AuthService {
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  User? _currentUser;
  User? get currentUser => _currentUser;

  /// Check if user is currently logged in.
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.jwtTokenKey);
    return token != null;
  }

  /// Register with email and password.
  Future<User> register(String email, String password) async {
    final response = await _apiClient.register(email, password);
    return _handleAuthResponse(response.data);
  }

  /// Login with email and password.
  Future<User> login(String email, String password) async {
    final response = await _apiClient.login(email, password);
    return _handleAuthResponse(response.data);
  }

  /// Sign in with Google.
  Future<User> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Google sign-in was cancelled');
    }

    final auth = await account.authentication;
    if (auth.idToken == null) {
      throw Exception('Failed to get Google ID token');
    }

    final response = await _apiClient.googleSignIn(auth.idToken!);
    return _handleAuthResponse(response.data);
  }

  /// Logout — clear stored credentials.
  Future<void> logout() async {
    await _storage.delete(key: AppConstants.jwtTokenKey);
    await _storage.delete(key: AppConstants.userIdKey);
    await _storage.delete(key: AppConstants.userEmailKey);
    _currentUser = null;

    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore Google sign-out errors
    }
  }

  /// Handle auth response — store token and user info.
  Future<User> _handleAuthResponse(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);

    await _storage.write(key: AppConstants.jwtTokenKey, value: token);
    await _storage.write(
        key: AppConstants.userIdKey, value: user.id.toString());
    await _storage.write(key: AppConstants.userEmailKey, value: user.email);

    _currentUser = user;
    return user;
  }

  /// Get stored user email (for display when offline).
  Future<String?> getStoredEmail() async {
    return await _storage.read(key: AppConstants.userEmailKey);
  }
}
