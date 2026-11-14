import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the bearer token in platform secure storage
/// (Keychain/Keystore/DPAPI/Secret Service).
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _accessTokenKey = 'mealmate.access_token';

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: _accessTokenKey);

  Future<void> saveToken(String token) {
    if (token.trim().isEmpty) {
      throw ArgumentError.value(token, 'token', 'Token must not be empty');
    }
    return _storage.write(key: _accessTokenKey, value: token);
  }

  Future<void> clearToken() => _storage.delete(key: _accessTokenKey);
}
