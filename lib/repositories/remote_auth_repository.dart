import '../constants/api_endpoints.dart';
import '../models/auth_session.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/token_storage.dart';
import 'auth_repository.dart';

/// Auth repository backed by the Express API and secure local token storage.
class RemoteAuthRepository implements AuthRepository {
  const RemoteAuthRepository({
    required this.apiClient,
    required this.tokenStorage,
  });

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final body = await apiClient.post(
      ApiEndpoints.login,
      data: {'email': email.trim(), 'password': password},
      authenticated: false,
    );
    return _persistSession(body);
  }

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final body = await apiClient.post(
      ApiEndpoints.register,
      data: {'name': name.trim(), 'email': email.trim(), 'password': password},
      authenticated: false,
    );
    return _persistSession(body);
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final token = await tokenStorage.readToken();
    if (token == null || token.isEmpty) return null;

    try {
      final body = await apiClient.get(ApiEndpoints.me);
      final user = _userFromBody(body);
      return AuthSession(token: token, user: user);
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        await tokenStorage.clearToken();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.post(ApiEndpoints.logout);
    } on ApiException {
      // Best effort: revoking the local token is what matters for the client.
    } finally {
      await tokenStorage.clearToken();
    }
  }

  @override
  Future<User> updateProfile({required String name}) async {
    final body = await apiClient.patch(
      ApiEndpoints.updateProfile,
      data: {'name': name.trim()},
    );
    return _userFromBody(body);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await apiClient.patch(
      ApiEndpoints.changePassword,
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  Future<AuthSession> _persistSession(Map<String, dynamic> body) async {
    final data = _dataFromBody(body);
    final AuthSession session;

    try {
      session = AuthSession.fromJson(data);
    } on FormatException {
      throw const ApiException('Unexpected response from the server.');
    }

    await tokenStorage.saveToken(session.token);
    return session;
  }

  User _userFromBody(Map<String, dynamic> body) {
    final data = _dataFromBody(body);
    final userJson = data['user'];

    if (userJson is! Map) {
      throw const ApiException('Unexpected response from the server.');
    }

    return User.fromJson(Map<String, dynamic>.from(userJson));
  }

  Map<String, dynamic> _dataFromBody(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is! Map) {
      throw const ApiException('Unexpected response from the server.');
    }
    return Map<String, dynamic>.from(data);
  }
}
