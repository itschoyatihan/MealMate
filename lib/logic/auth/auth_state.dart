import 'package:equatable/equatable.dart';

import '../../models/user.dart';

enum AuthStatus {
  /// Session restore has not finished yet.
  unknown,
  authenticated,
  unauthenticated,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isSubmitting = false,
    this.errorMessage,
  });

  static const Object _unset = Object();

  final AuthStatus status;
  final User? user;
  final bool isSubmitting;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isGuest => status == AuthStatus.unauthenticated;
  bool get isRestoring => status == AuthStatus.unknown && !isSubmitting;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool clearUser = false,
    bool? isSubmitting,
    Object? errorMessage = _unset,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, user, isSubmitting, errorMessage];
}
