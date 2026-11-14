import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'constants/app_theme.dart';
import 'logic/auth/auth_bloc.dart';
import 'logic/auth/auth_event.dart';
import 'repositories/auth_repository.dart';
import 'repositories/remote_auth_repository.dart';
import 'services/api_client.dart';
import 'services/token_storage.dart';
import 'ui/splash_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  final authRepository = RemoteAuthRepository(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
  );
  runApp(MealMateApp(authRepository: authRepository, apiClient: apiClient));
}

class MealMateApp extends StatelessWidget {
  const MealMateApp({
    super.key,
    required this.authRepository,
    required this.apiClient,
  });

  final AuthRepository authRepository;
  final ApiClient apiClient;
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<ApiClient>.value(
      value: apiClient,
      child: BlocProvider(
        create: (_) => AuthBloc(authRepository)..add(const AuthStarted()),
        child: MaterialApp(
          title: 'MealMate',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const SplashPage(),
        ),
      ),
    );
  }
}
