import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealmate/logic/auth/auth_bloc.dart';
import 'package:mealmate/logic/auth/auth_event.dart';
import 'package:mealmate/logic/auth/auth_state.dart';
import 'package:mealmate/models/auth_session.dart';
import 'package:mealmate/models/user.dart';
import 'package:mealmate/repositories/auth_repository.dart';
import 'package:mealmate/services/api_exception.dart';

const _user = User(
  id: '65f1c0ffee',
  name: 'Aung Aung',
  email: 'aung@example.com',
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.restoredSession, this.error});

  final AuthSession? restoredSession;
  final Object? error;

  bool logoutCalled = false;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    if (error != null) throw error!;
    return const AuthSession(token: 'token', user: _user);
  }

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (error != null) throw error!;
    return const AuthSession(token: 'token', user: _user);
  }

  @override
  Future<AuthSession?> restoreSession() async => restoredSession;

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<User> updateProfile({required String name}) async => _user;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}
}

void main() {
  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'becomes guest when no session is stored',
      build: () => AuthBloc(_FakeAuthRepository()),
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [const AuthState(status: AuthStatus.unauthenticated)],
    );

    blocTest<AuthBloc, AuthState>(
      'restores a persisted session on startup',
      build: () => AuthBloc(
        _FakeAuthRepository(
          restoredSession: const AuthSession(token: 'token', user: _user),
        ),
      ),
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [
        const AuthState(status: AuthStatus.authenticated, user: _user),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'authenticates after a successful login',
      build: () => AuthBloc(_FakeAuthRepository()),
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          email: 'aung@example.com',
          password: 'secret123',
        ),
      ),
      expect: () => [
        const AuthState(isSubmitting: true),
        const AuthState(status: AuthStatus.authenticated, user: _user),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'surfaces the server message when login fails',
      build: () => AuthBloc(
        _FakeAuthRepository(
          error: const ApiException(
            'Incorrect email or password.',
            statusCode: 401,
          ),
        ),
      ),
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          email: 'aung@example.com',
          password: 'wrong-password',
        ),
      ),
      expect: () => [
        const AuthState(isSubmitting: true),
        const AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Incorrect email or password.',
        ),
      ],
    );

    test('clears the session on logout', () async {
      final repository = _FakeAuthRepository();
      final bloc = AuthBloc(repository);

      bloc.add(const AuthLogoutRequested());
      await bloc.stream.firstWhere((state) => state.isGuest);

      expect(repository.logoutCalled, isTrue);
      expect(bloc.state.isGuest, isTrue);
      expect(bloc.state.user, isNull);

      await bloc.close();
    });
  });
}
