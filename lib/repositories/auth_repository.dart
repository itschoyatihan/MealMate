import '../models/auth_session.dart';
import '../models/user.dart';

/// Stable authentication contract used by the auth BLoC.
/// The UI never talks to Dio directly.
abstract interface class AuthRepository {
  Future<AuthSession> login({required String email, required String password});

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  });

  /// Restores a persisted session on startup, or returns null when there is
  /// no valid token. An expired token is cleared automatically.
  Future<AuthSession?> restoreSession();

  Future<void> logout();

  Future<User> updateProfile({required String name});

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
