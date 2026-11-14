import 'package:flutter/foundation.dart';

/// REST endpoints exposed by the MealMate Express API.
///
/// The base URL defaults to localhost for desktop/web and to the Android
/// emulator loopback alias. Override it for a physical device or deployment:
///
/// ```bash
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.20:4000/api
/// ```
abstract final class ApiEndpoints {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static const String _desktopBaseUrl = 'http://localhost:4000/api';
  static const String _androidEmulatorBaseUrl = 'http://10.0.2.2:4000/api';

  static String get baseUrl {
    final configured = _configuredBaseUrl.trim();
    final resolved = configured.isNotEmpty
        ? configured
        : switch (defaultTargetPlatform) {
            TargetPlatform.android => _androidEmulatorBaseUrl,
            _ => _desktopBaseUrl,
          };

    return resolved.endsWith('/')
        ? resolved.substring(0, resolved.length - 1)
        : resolved;
  }

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';

  // Profile
  static const String updateProfile = '/users/me';
  static const String changePassword = '/users/me/password';
}
