import 'package:equatable/equatable.dart';

import 'user.dart';

/// A signed-in session: the bearer token plus the account it belongs to.
class AuthSession extends Equatable {
  const AuthSession({required this.token, required this.user});

  final String token;
  final User user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = json['token'] as String?;
    final userJson = json['user'];

    if (token == null || token.isEmpty || userJson is! Map) {
      throw const FormatException('Malformed authentication response.');
    }

    return AuthSession(
      token: token,
      user: User.fromJson(Map<String, dynamic>.from(userJson)),
    );
  }

  @override
  List<Object?> get props => [token, user];
}
