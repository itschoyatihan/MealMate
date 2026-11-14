import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/auth_repository.dart';
import '../../services/api_exception.dart';
import 'auth_event.dart';
import 'auth_state.dart';

const _genericErrorMessage = 'Something went wrong. Please try again.';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authRepository) : super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthErrorDismissed>(_onErrorDismissed);
    on<AuthProfileNameUpdated>(_onProfileNameUpdated);
  }

  final AuthRepository _authRepository;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    try {
      final session = await _authRepository.restoreSession();
      if (session == null) {
        emit(const AuthState(status: AuthStatus.unauthenticated));
        return;
      }
      emit(AuthState(status: AuthStatus.authenticated, user: session.user));
    } catch (_) {
      // Offline startup should still allow guest planning.
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.isSubmitting) return;

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    try {
      final session = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthState(status: AuthStatus.authenticated, user: session.user));
    } on ApiException catch (error) {
      emit(
        AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        const AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: _genericErrorMessage,
        ),
      );
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.isSubmitting) return;

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    try {
      final session = await _authRepository.register(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      emit(AuthState(status: AuthStatus.authenticated, user: session.user));
    } on ApiException catch (error) {
      emit(
        AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        const AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: _genericErrorMessage,
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.logout();
    } catch (_) {
      // Local token is cleared by the repository; never block sign-out.
    } finally {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  void _onErrorDismissed(AuthErrorDismissed event, Emitter<AuthState> emit) {
    emit(state.copyWith(errorMessage: null));
  }

  void _onProfileNameUpdated(
    AuthProfileNameUpdated event,
    Emitter<AuthState> emit,
  ) {
    final currentUser = state.user;

    if (!state.isAuthenticated || currentUser == null) return;

    emit(state.copyWith(user: currentUser.copyWith(name: event.name)));
  }
}
