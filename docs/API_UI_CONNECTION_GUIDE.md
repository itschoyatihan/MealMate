# MealMate — Flutter `lib/` API Layer နှင့် UI ချိတ်ဆက်ပုံ လမ်းညွှန်

> ဒီ document က `PROJECT1/lib/` အတွင်းရှိ API endpoint, service, repository, model, BLoC နှင့် UI page များ ဘယ်လိုဆက်စပ်နေသည်ကို construction အလိုက် ရှင်းပြထားသည်။  
> နောက်ပိုင်း UI page များကို backend နှင့် ချိတ်ဆက်ရာတွင် လိုက်နာနိုင်သော pattern များလည်း ပါဝင်သည်။

---

## Table of Contents

1. [Mental Model](#1-mental-model)
2. [Composition Root — `lib/main.dart`](#2-composition-root--libmaindart)
3. [Endpoint Constants — `lib/constants/api_endpoints.dart`](#3-endpoint-constants--libconstantsapi_endpointsdart)
4. [Transport Layer — `lib/services/api_client.dart`](#4-transport-layer--libservicesapi_clientdart)
5. [Error Layer — `lib/services/api_exception.dart`](#5-error-layer--libservicesapi_exceptiondart)
6. [Model Layer — `lib/models/`](#6-model-layer--libmodels)
7. [Repository Layer — `lib/repositories/`](#7-repository-layer--librepositories)
8. [BLoC Layer — `lib/logic/auth/`](#8-bloc-layer--liblogicauth)
9. [UI Layer — လက်ရှိ တကယ်ချိတ်ထားပုံ](#9-ui-layer--လက်ရှိ-တကယ်ချိတ်ထားပုံ)
10. [Backend Contract](#10-backend-contract)
11. [နောက်ထပ် Page များ ချိတ်နည်း — Concrete Pattern](#11-နောက်ထပ်-page-များ-ချိတ်နည်း--concrete-pattern)
12. [လက်ရှိ Code ၏ အားသာချက် / အားနည်းချက်](#12-လက်ရှိ-code-၏-အားသာချက်--အားနည်းချက်)
13. [ဘယ်အစီအစဉ်နှင့် ချိတ်သင့်လဲ](#13-ဘယ်အစီအစဉ်နှင့်-ချိတ်သင့်လဲ)
14. [အမှားများလေ့ရှိသော အချက်များ — Checklist](#14-အမှားများလေ့ရှိသော-အချက်များ--checklist)
15. [အနှစ်ချုပ်](#15-အနှစ်ချုပ်)
16. [Appendix — Endpoint Quick Reference](#appendix--endpoint-quick-reference)

---

## 1. Mental Model

ဒီ project ရဲ့ API ချိတ်ဆက်ပုံကို အလွှာ (၆) လွှာခွဲကြည့်နိုင်ပါတယ်။

```text
Flutter UI (Page/Widget)
        │   event / callback
        ▼
BLoC (AuthBloc သာ လက်ရှိရှိ)  ──►  Repository (AuthRepository)
        │                                      │
        └──────────────┬───────────────────────┘
                       ▼
                  ApiClient (Dio wrapper)
                       │  baseUrl + Bearer token
                       ▼
                Express Route + Controller
                       │
                       ▼
                Model (raw SQL / pg)
                       │
                       ▼
                   PostgreSQL
                       │
                       ▼
        { success: true, data: {...} }  (JSON envelope)
                       │
                       ▼
     ApiClient က body တစ်ခုလုံး return
                       │
                       ▼
     Repository က body['data'] ကို ဆွဲထုတ်
                       │
                       ▼
     Model class (User, Food, Plan ...)
                       │
                       ▼
     BLoC State / setState → UI ပြန်ဆွဲ
```

ဒီ project မှာ **လမ်းကြောင်းနှစ်ခု** ရှိတယ်ဆိုတာ သတိထားပါ။

1. **Auth လမ်းကြောင်း (အပြည့်အစုံချိတ်ထား)**  
   `UI → AuthBloc → AuthRepository → ApiClient → Backend`
2. **Budget လမ်းကြောင်း (တိုတိုချိတ်ထား)**  
   `UI → ApiClient → Backend` (Repository/BLoC မဖြတ်)

ကျန်တဲ့ Foods, Plans, Favorites, Expenses, History, Reports တွေက **UI ပဲရှိပြီး API မချိတ်ရသေးပါ**။ ဒါကြောင့် နောက်ပိုင်းချိတ်တဲ့အခါ အပေါ်က လမ်းကြောင်းနှစ်ခုထဲက ဘယ်ပုံစံလိုက်မလဲ ဆုံးဖြတ်ရပါမယ်။

---

## 2. Composition Root — `lib/main.dart`

`main.dart` က **အားလုံးကို တစ်နေရာတည်းမှာ တည်ဆောက်ပြီး အောက်ကို ဖြန့်ပေးတဲ့နေရာ** ဖြစ်ပါတယ်။

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);

  final authRepository = RemoteAuthRepository(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
  );

  runApp(MealMateApp(
    authRepository: authRepository,
    apiClient: apiClient,
  ));
}
```

Construction အစီအစဉ်က အရေးကြီးပါတယ်။

```text
TokenStorage
    │
    ▼
ApiClient(tokenStorage)
    │
    ▼
RemoteAuthRepository(apiClient, tokenStorage)
    │
    ▼
AuthBloc(authRepository)
```

ပြီးတော့ Provider tree က ဒီလို ဖြစ်ပါတယ်။

```dart
RepositoryProvider<ApiClient>.value(
  value: apiClient,
  child: BlocProvider(
    create: (_) => AuthBloc(authRepository)..add(const AuthStarted()),
    child: MaterialApp(
      home: const SplashPage(),
    ),
  ),
)
```

ဆိုလိုတာက —

- `ApiClient` က **app တစ်ခုလုံးအတွက် instance တစ်ခုတည်း**။ ဘယ် page ကမဆို `context.read<ApiClient>()` နဲ့ ယူနိုင်တယ်။
- `AuthBloc` က **app တစ်ခုလုံးအတွက် instance တစ်ခုတည်း**။ `context.watch<AuthBloc>()` နဲ့ login state ကို စောင့်ကြည့်နိုင်တယ်။
- App စတာနဲ့ `AuthStarted` event ကို ချက်ချင်း ပို့တယ်။ အဲဒါက secure storage ထဲက token ကို ဖတ်ပြီး `GET /auth/me` ခေါ်ကာ session ကို ပြန်တည်ဆောက်တယ်။

`SplashPage` က ၃ စက္ကန့်နေပြီး `HomePage` ကို `pushReplacement` လုပ်တယ်။ ဒီအချိန်မှာ `AuthStarted` က ပြီးသွားပြီဖြစ်လို့ Home က logged-in/guest state ကို မှန်ကန်စွာ ပြသနိုင်တယ်။

---

## 3. Endpoint Constants — `lib/constants/api_endpoints.dart`

Endpoint တွေက **string path တွေပဲ** ဖြစ်ပါတယ်။ အဲဒီ path ကို `ApiClient` ရဲ့ Dio က baseUrl နဲ့ ပေါင်းပြီး request လုပ်တယ်။

```dart
abstract final class ApiEndpoints {
  static const String _configuredBaseUrl =
      String.fromEnvironment('API_BASE_URL');

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
```

ဒီနေရာမှာ သိထားရမယ့်အချက်တွေ —

- Windows/Web ဆို `http://localhost:4000/api`
- Android Emulator ဆို `http://10.0.2.2:4000/api` (emulator ထဲက `localhost` က emulator ကိုယ်တိုင်ကို ညွှန်တာမို့)
- Physical device ဆို ကိုယ့် PC ရဲ့ LAN IP ကို ပေးရမယ်။

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:4000/api
```

- Path တွေက `/auth/login` လို relative ပဲ။ Dio က `baseUrl + path` ကို ပေါင်းပေးတယ်။
- လက်ရှိ constant ထဲမှာ **auth/profile ပဲ ရှိပါတယ်**။ Budget က `home_page.dart` ထဲမှာ `'/budget'` လို့ hardcode ထားတယ်။ နောက်ပိုင်း ကျန်တဲ့ endpoint တွေကိုလည်း ဒီ file ထဲ ထည့်ဖို့ ကောင်းပါတယ်။

```dart
// Suggested additions
static const String foods = '/foods';
static String food(String id) => '/foods/$id';

static const String favorites = '/favorites';
static String favorite(String foodId) => '/favorites/$foodId';

static const String budget = '/budget';
static const String plans = '/plans';
static const String expenses = '/expenses';
static const String history = '/history';
static const String reports = '/reports';
static const String guestTransfer = '/guest-transfer';
```

---

## 4. Transport Layer — `lib/services/api_client.dart`

ဒီ class က **Dio ကို ဖုံးထားတဲ့ thin wrapper** ပါ။ တာဝန်သုံးခုရှိတယ်။

1. Base URL, timeout, JSON header သတ်မှတ်တယ်။
2. Request တိုင်းမှာ Bearer token ထည့်တယ်။
3. Dio error ကို `ApiException` အဖြစ် ပြောင်းတယ်။

### 4.1 Dio Configuration

```dart
Dio(
  BaseOptions(
    baseUrl: baseUrl ?? ApiEndpoints.baseUrl,
    connectTimeout: AppConstants.apiConnectTimeout,
    receiveTimeout: AppConstants.apiReceiveTimeout,
    sendTimeout: AppConstants.apiSendTimeout,
    contentType: Headers.jsonContentType,
    responseType: ResponseType.json,
    headers: const {'Accept': 'application/json'},
  ),
)
```

### 4.2 Token ထည့်ပုံ

```dart
Future<void> _attachAccessToken(
  RequestOptions options,
  RequestInterceptorHandler handler,
) async {
  if (options.extra['skipAuth'] != true) {
    final token = await tokenStorage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
  }
  handler.next(options);
}
```

ဒါက **request တိုင်းမတိုင်မီ** secure storage ကနေ token ဖတ်ပြီး header ထည့်တယ်။ ဒါကြောင့် repository တွေက token ကို ကိုယ်တိုင် ကိုင်စရာမလိုပါ။

Login/Register လုပ်တဲ့အခါ token မရှိသေးလို့ `authenticated: false` ပေးရတယ်။ အဲဒါက `extra['skipAuth'] = true` ဖြစ်သွားပြီး token မထည့်တော့ဘူး။

```dart
Options _options(bool authenticated) {
  return Options(extra: {'skipAuth': !authenticated});
}
```

### 4.3 Generic Methods

```dart
Future<Map<String, dynamic>> get(String path, {
  Map<String, dynamic>? queryParameters,
  bool authenticated = true,
});

Future<Map<String, dynamic>> post(String path, {
  Object? data,
  bool authenticated = true,
});

Future<Map<String, dynamic>> put(...);
Future<Map<String, dynamic>> patch(...);
Future<Map<String, dynamic>> delete(...);
```

အားလုံးက `_run()` ကို ဖြတ်တယ်။

```dart
Future<Map<String, dynamic>> _run(
  Future<Response<dynamic>> Function() request,
) async {
  try {
    final response = await request();
    final body = response.data;

    if (body is Map) return Map<String, dynamic>.from(body);
    return <String, dynamic>{};
  } on DioException catch (error) {
    throw ApiException.fromDio(error);
  }
}
```

**အရေးကြီးဆုံးအချက်:** `ApiClient` က backend ရဲ့ **response body တစ်ခုလုံး** ကို return တယ်။

```json
{
  "success": true,
  "data": {
    "user": {}
  }
}
```

ဆိုတော့ repository/model က `body['data']` ကို ဆွဲထုတ်ရတယ်။ `ApiClient` က `data` ကို အလိုအလျောက် မခွဲပေးပါ။

### 4.4 လက်ရှိ အားနည်းချက်

`ApiClient` က **401 ကို global မကိုင်ပါ**။ `restoreSession()` တစ်နေရာတည်းမှာပဲ 401 ဆို token ဖျက်တယ်။ ကျန်တဲ့ API ခေါ်တဲ့အခါ 401 ရရင် UI ကို login ပို့တဲ့ mechanism မရှိသေးပါ။ နောက်ပိုင်း interceptor တစ်ခု ထပ်ထည့်ဖို့ လိုပါမယ်။

---

## 5. Error Layer — `lib/services/api_exception.dart`

Dio error တွေကို UI ဖတ်နိုင်တဲ့ error အဖြစ် ပြောင်းပေးတယ်။

```dart
class ApiFieldError {
  const ApiFieldError({required this.field, required this.message});

  final String field;
  final String message;
}

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.details = const [],
  });

  final String message;
  final int? statusCode;
  final List<ApiFieldError> details;

  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409;
}
```

Backend က error ကို ဒီလို ပြန်တယ်။

```json
{
  "success": false,
  "message": "Validation failed.",
  "details": [
    { "field": "amount", "message": "Enter a budget greater than 0." }
  ]
}
```

`ApiException.fromDio()` က —

- timeout → "server took too long"
- connection error → "could not reach server"
- `badResponse` → backend ရဲ့ `message` နဲ့ `details` ကို ဆွဲထုတ်
- status code ကို `statusCode` ထဲ ထည့်

ဒါကြောင့် UI မှာ —

```dart
try {
  await repository.savePlan(...);
} on ApiException catch (e) {
  if (e.isConflict) {
    // show conflict dialog
  } else {
    showSnackBar(e.message);
  }
}
```

ပြီးတော့ `e.details` ကို form field error တွေအောက်မှာ ပြနိုင်တယ်။

---

## 6. Model Layer — `lib/models/`

Model class တွေက **JSON → Dart object** ပြောင်းတဲ့နေရာ ဖြစ်တယ်။

### 6.1 `User`

```dart
factory User.fromJson(Map<String, dynamic> json) {
  final rawId = json['id'] ?? json['_id'];

  return User(
    id: rawId?.toString() ?? '',
    name: (json['name'] as String? ?? '').trim(),
    email: (json['email'] as String? ?? '').trim(),
    role: UserRole.fromApi(json['role']),
    isActive: json['isActive'] as bool? ?? true,
    lastLoginAt: _parseDate(json['lastLoginAt']),
    createdAt: _parseDate(json['createdAt']),
    updatedAt: _parseDate(json['updatedAt']),
  );
}
```

### 6.2 `AuthSession`

```dart
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
```

### 6.3 နောက်ပိုင်း လိုအပ်မယ့် model များ

Backend က ပြန်တဲ့ field တွေအတိုင်း ဆောက်ရပါမယ်။

**Food** (`GET /foods`):

```json
{
  "id": "uuid",
  "name": "Mohinga",
  "shopName": "Shop A",
  "location": "Hlaing",
  "category": "Soups",
  "price": 2000,
  "imagePath": "assets/img/mohinga.jpg",
  "isActive": true,
  "createdAt": "2026-11-12T00:00:00.000Z",
  "updatedAt": "2026-11-12T00:00:00.000Z"
}
```

**Plan** (`GET /plans`, `POST /plans`):

```json
{
  "id": "uuid",
  "date": "2026-11-12",
  "method": "manual",
  "plannedTotal": 8000,
  "budgetAtSave": 10000,
  "items": [
    {
      "food": "food-uuid",
      "name": "Mohinga",
      "shopName": "Shop A",
      "category": "Soups",
      "imagePath": "assets/img/mohinga.jpg",
      "price": 2000,
      "quantity": 2,
      "mealType": "breakfast",
      "lineTotal": 4000
    }
  ]
}
```

ဒီနေရာမှာ **အရေးကြီးတဲ့ အချက်** ရှိတယ်။ Plan item ထဲက `"food"` က food object မဟုတ်ဘဲ **food id string** ဖြစ်တယ်။ `POST /plans` မှာ ပို့ရမယ့် field က `foodId` ဖြစ်တယ်။

---

## 7. Repository Layer — `lib/repositories/`

Repository က **UI/BLoC နဲ့ API အကြား contract** ပါ။ UI က Dio ကို တိုက်ရိုက် မသိရပါ။

### 7.1 Interface

```dart
abstract interface class AuthRepository {
  Future<AuthSession> login({
    required String email,
    required String password,
  });

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  });

  Future<AuthSession?> restoreSession();

  Future<void> logout();

  Future<User> updateProfile({required String name});

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
```

### 7.2 Remote Implementation

```dart
class RemoteAuthRepository implements AuthRepository {
  const RemoteAuthRepository({
    required this.apiClient,
    required this.tokenStorage,
  });

  final ApiClient apiClient;
  final TokenStorage tokenStorage;
```

#### Login

```dart
@override
Future<AuthSession> login({
  required String email,
  required String password,
}) async {
  final body = await apiClient.post(
    ApiEndpoints.login,
    data: {
      'email': email.trim(),
      'password': password,
    },
    authenticated: false,
  );

  return _persistSession(body);
}
```

Flow က —

```text
POST /api/auth/login
  body: { email, password }
        │
        ▼
Backend: user ရှာတယ် → bcrypt စစ်တယ် → JWT ထုတ်တယ်
        │
        ▼
{ success: true, data: { token, user } }
        │
        ▼
_persistSession()
  - body['data'] ဆွဲ
  - AuthSession.fromJson()
  - tokenStorage.saveToken()
```

#### Register

```dart
@override
Future<AuthSession> register({
  required String name,
  required String email,
  required String password,
}) async {
  final body = await apiClient.post(
    ApiEndpoints.register,
    data: {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
    },
    authenticated: false,
  );

  return _persistSession(body);
}
```

#### Restore Session

```dart
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
```

App စတာနဲ့ —

```text
TokenStorage.readToken()
   │
   ├─ null → guest (unauthenticated)
   │
   └─ token ရှိ → GET /api/auth/me
                    │
                    ├─ 200 → authenticated
                    └─ 401 → token ဖျက် → unauthenticated
```

#### Logout

```dart
@override
Future<void> logout() async {
  try {
    await apiClient.post(ApiEndpoints.logout);
  } on ApiException {
    // Best effort: local token removal is what matters for the client.
  } finally {
    await tokenStorage.clearToken();
  }
}
```

Backend က stateless JWT ဖြစ်လို့ server-side revoke မလုပ်ပါ။ Client က token ဖျက်လိုက်တာနဲ့ logout ဖြစ်ပါတယ်။

#### Envelope ဆွဲထုတ်တဲ့ Helper

```dart
Map<String, dynamic> _dataFromBody(Map<String, dynamic> body) {
  final data = body['data'];

  if (data is! Map) {
    throw const ApiException('Unexpected response from the server.');
  }

  return Map<String, dynamic>.from(data);
}
```

ဒီ helper က **API envelope ကို ကိုင်တဲ့နေရာ** ပါ။ နောက် repository တွေအတွက်လည်း ဒီလို helper/base class ထားဖို့ အကြံပြုပါတယ်။

---

## 8. BLoC Layer — `lib/logic/auth/`

### 8.1 Event

```dart
sealed class AuthEvent extends Equatable {
  const AuthEvent();
}

final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

final class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

final class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
```

### 8.2 State

```dart
enum AuthStatus {
  unknown,          // session restore မပြီးသေး
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

  final AuthStatus status;
  final User? user;
  final bool isSubmitting;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isGuest => status == AuthStatus.unauthenticated;
  bool get isRestoring => status == AuthStatus.unknown && !isSubmitting;
}
```

### 8.3 Bloc

```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authRepository) : super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthErrorDismissed>(_onErrorDismissed);
  }

  final AuthRepository _authRepository;
```

Login handler —

```dart
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

    emit(AuthState(
      status: AuthStatus.authenticated,
      user: session.user,
    ));
  } on ApiException catch (error) {
    emit(AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: error.message,
    ));
  } catch (_) {
    emit(const AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: 'Something went wrong. Please try again.',
    ));
  }
}
```

ဒီနေရာမှာ အရေးကြီးတဲ့ state transition နှစ်ခု ရှိတယ်။

- Request ပို့ချိန်: `isSubmitting: true` → button disable, loading ပြ
- အောင်မြင်: `status: authenticated`, `user: session.user`
- မအောင်မြင်: `status: unauthenticated`, `errorMessage: ...`

---

## 9. UI Layer — လက်ရှိ တကယ်ချိတ်ထားပုံ

### 9.1 Splash → Home

`SplashPage` က API မခေါ်ပါ။ ၃ စက္ကန့်နေပြီး `HomePage` ကို သွားတယ်။

```dart
Timer(const Duration(seconds: 3), () {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(builder: (_) => const HomePage()),
  );
});
```

### 9.2 Login Page

Login button နှိပ်ရင် —

```dart
void _logIn() {
  if (!_formKey.currentState!.validate()) return;

  context.read<AuthBloc>().add(
    AuthLoginRequested(
      email: _email.text.trim(),
      password: _password.text,
    ),
  );
}
```

UI က `BlocConsumer` နဲ့ နားထောင်တယ်။

```dart
BlocConsumer<AuthBloc, AuthState>(
  listenWhen: (previous, current) =>
      previous.status != current.status && current.isAuthenticated,
  listener: (context, _) => _onAuthenticated(),
  builder: (context, authState) {
    // UI ဆောက်
  },
)
```

`_onAuthenticated()` က —

```dart
void _onAuthenticated() {
  if (!mounted) return;

  final navigator = Navigator.of(context);

  if (navigator.canPop()) {
    navigator.popUntil((route) => route.isFirst);
  } else {
    navigator.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomePage()),
    );
  }
}
```

Form ထဲမှာ error ပြပုံ —

```dart
if (authState.errorMessage != null) ...[
  _ErrorBanner(message: authState.errorMessage!),
],
```

Button disable ပုံ —

```dart
onPressed: authState.isSubmitting ? null : _logIn,
```

ဒါက **standard BLoC UI pattern** ပါ။ နောက် feature တွေအတွက်လည်း အတူတူ လုပ်နိုင်တယ်။

### 9.3 Signup Page

Signup ကလည်း အတူတူပါ။

```dart
context.read<AuthBloc>().add(
  AuthRegisterRequested(
    name: _name.text.trim(),
    email: _email.text.trim(),
    password: _password.text,
  ),
);
```

`listenWhen` က authenticated ဖြစ်သွားတာနဲ့ Home ကို ပြန်ပို့တယ်။

### 9.4 Home Page — Auth State ကို ဖတ်ပုံ

```dart
Widget _content(BuildContext context, bool desktop) {
  final authState = context.watch<AuthBloc>().state;
  final isLoggedIn = authState.isAuthenticated;
  final userName = authState.user?.name;
  // ...
}
```

`context.watch<AuthBloc>()` က state ပြောင်းတိုင်း `HomePage` ကို ပြန်ဆွဲစေတယ်။ ဒါကြောင့် login/logout လုပ်တာနဲ့ —

- "Guest Mode" banner ပျောက်/ပေါ်
- "WELCOME, {name}!" ပြောင်း
- Profile button က "Guest" → user name
- Reports/Expenses/History က login required ပြ/မ

ဒါတွေ အလိုအလျောက် ဖြစ်တယ်။

### 9.5 Budget — တိုက်ရိုက် API ခေါ်ထားတဲ့ တစ်နေရာတည်း

`home_page.dart` ထဲမှာ —

```dart
Future<void> _saveBudgetToBackend(
  BuildContext context,
  int amount,
) async {
  final api = context.read<ApiClient>();

  final response = await api.put(
    '/budget',
    data: {
      'date': _todayDate(),
      'amount': amount,
    },
  );

  if (response['success'] != true) {
    throw StateError('Budget could not be saved.');
  }
}
```

ဒီနေရာမှာ —

- `ApiClient` ကို `context.read` နဲ့ တိုက်ရိုက်ယူ
- `PUT /budget` ကို တိုက်ရိုက်ခေါ်
- `date` ကို `YYYY-MM-DD` format နဲ့ ပို့
- response ရဲ့ `success` ကို စစ်

ပြီးတော့ `openBudget()` ထဲမှာ logged-in ဆိုမှ backend ကို သိမ်းတယ်။

```dart
Future<bool> saveBudget(int amount) async {
  try {
    if (isLoggedIn) {
      await _saveBudgetToBackend(context, amount);
    }

    GuestBudget.save(amount);
    return true;
  } catch (error) {
    return false;
  }
}
```

ဒီ design မှာ **guest နဲ့ logged-in ကို ခွဲထားတယ်**။

- Guest → `GuestBudget` (memory only, app restart ဆို ပျောက်)
- Logged-in → backend `PUT /budget` + local `GuestBudget` ကို display အတွက် သိမ်း

ဒါပေမယ့် **လက်ရှိ logged-in user အတွက် backend က budget ကို ပြန်မဖတ်ပါ**။ App ပြန်ဖွင့်ရင် `GuestBudget` null ဖြစ်နေမှာမို့ backend မှာ budget ရှိပေမယ့် UI က "Set your budget" ပြနေမယ်။ ဒါကို နောက်ပိုင်း `GET /budget` နဲ့ ဖြေရှင်းရမယ်။

### 9.6 Plan — လက်ရှိ local only

Plan ကို `HomePage` ရဲ့ static `ValueNotifier` ထဲမှာပဲ သိမ်းတယ်။

```dart
static final ValueNotifier<Object?> _savedTodayPlan =
    ValueNotifier<Object?>(null);
```

Save လုပ်တဲ့အခါ —

```dart
Future<void> _savePlan(BuildContext homeContext, Object plan) async {
  _savedTodayPlan.value = plan;

  final homeRoute = ModalRoute.of(homeContext);
  if (homeRoute != null) {
    Navigator.of(homeContext)
        .popUntil((route) => identical(route, homeRoute));
  }
}
```

ဒီမှာ backend မခေါ်ပါ။ `AutoPlanPage`/`ManualPage` က `onSave` callback ပေးလိုက်တာကို Home က လက်ခံပြီး memory ထဲ ထည့်တာပါ။

**ဒါပေမယ့် ဒီ callback က အလွန်ကောင်းတဲ့ seam ဖြစ်တယ်။** နောက်ပိုင်း backend ချိတ်ဖို့ `_savePlan()` ထဲမှာ repository call ထည့်ရုံပါ။

### 9.7 Foods — local sample catalog

`foods_page.dart` မှာ —

```dart
const List<FoodCatalogItem> sampleFoodCatalog = [
  FoodCatalogItem(
    id: 'food_001',
    name: 'Mohinga',
    price: 2000,
    shopName: 'Shop A',
    location: 'Hlaing',
    category: 'Soups',
    imagePath: 'assets/img/mohinga.jpg',
  ),
  // ...
];
```

ပြီးတော့ `FoodsPage` က —

```dart
this.foods = sampleFoodCatalog,
this.initialFavoriteIds = const {},
```

ဆိုတဲ့ props နဲ့ local data ကို လက်ခံတယ်။ Favorites ကလည်း —

```dart
final Set<String> _favoriteIds;
```

ဆိုတဲ့ local `Set` ပဲ။ `_toggleFavorite()` က `setState` နဲ့ local ပြောင်းတယ်။ API မခေါ်ပါ။

**ဒီ UI ကို backend ချိတ်တဲ့အခါ အရေးကြီးဆုံးအချက်:**

`sampleFoodCatalog` ရဲ့ id တွေက `'food_001'` လို string တွေ ဖြစ်တယ်။ Backend က **UUID** လိုချင်တယ်။ ဒါကြောင့် Foods page ကို backend catalog နဲ့ မချိတ်ဘဲ Plan ကို backend သိမ်းဖို့ ကြိုးစားရင် —

```json
{ "foodId": "food_001" }
```

ဆိုတာ backend မှာ `422` ဖြစ်မယ်။ ဒါကြောင့် **Foods catalog ကို API နဲ့ အရင်ချိတ်ရမယ်**။

### 9.8 Auto/Manual Planner — local algorithm

`AutoGenerator` က local algorithm ပါ။

```dart
final result = _generator.generate(
  catalog: widget.catalog,
  selected: _selected,
  budget: widget.dailyBudget,
  previous: _draft,
);
```

`ManualPage` ကလည်း local draft ကို စီမံတယ်။

```dart
draft = {
  for (final type in MealType.values)
    type: List.of(widget.initialPlan?.meals[type] ?? const <ManualItem>[]),
};
```

Save လုပ်တဲ့အခါ `widget.onSave!(ManualPlan(...))` ကို ခေါ်တယ်။ ဒါကလည်း backend ချိတ်ဖို့ seam ပါ။

### 9.9 My Plan

`MyPlanPage` က presentation only ပါ။

```dart
final ValueListenable<Object?> savedPlan;

final VoidCallback onChooseAutomatic;
final VoidCallback onChooseManual;
final VoidCallback onEdit;
final Future<void> Function() onDelete;
```

ဒါကြောင့် plan data ကို ကိုယ်တိုင် မခေါ်ပါ။ Home က ပေးတဲ့ notifier ကို ဖတ်ပြီး ပြတယ်။

### 9.10 လက်ရှိ API မချိတ်ရသေးတဲ့ UI

| Feature | UI ရှိ/မရှိ | API ချိတ်ထား? |
|---|---|---|
| Login / Register | ရှိ | ချိတ်ထား |
| Session restore | ရှိ | ချိတ်ထား |
| Logout | ရှိ | ချိတ်ထား |
| Budget save | ရှိ | ချိတ်ထား (logged-in only) |
| Budget load | မရှိ | မချိတ်ရသေး |
| Foods catalog | ရှိ (local sample) | မချိတ်ရသေး |
| Favorites | ရှိ (local Set) | မချိတ်ရသေး |
| Auto plan save | ရှိ (local notifier) | မချိတ်ရသေး |
| Manual plan save | ရှိ (local notifier) | မချိတ်ရသေး |
| Plan load / delete | မရှိ | မချိတ်ရသေး |
| Expenses | မရှိ (snackbar only) | မချိတ်ရသေး |
| History | မရှိ | မချိတ်ရသေး |
| Reports | မရှိ | မချိတ်ရသေး |
| Guest transfer | မရှိ | မချိတ်ရသေး |
| Profile update | မရှိ (dialog only) | မချိတ်ရသေး |
| Change password | မရှိ | မချိတ်ရသေး |

---

## 10. Backend Contract

UI ချိတ်တဲ့အခါ လိုက်နာရမယ့် အချက်များ။

### 10.1 Base URL

```text
Windows/Web : http://localhost:4000/api
Android Emu : http://10.0.2.2:4000/api
Physical    : http://<PC-LAN-IP>:4000/api
```

### 10.2 Success Envelope

```json
{
  "success": true,
  "data": {}
}
```

Repository က `body['data']` ကို ဆွဲထုတ်ရမယ်။

### 10.3 Error Envelope

```json
{
  "success": false,
  "message": "Validation failed.",
  "details": [
    { "field": "amount", "message": "Enter a budget greater than 0." }
  ]
}
```

`details` ကို form field error အနေနဲ့ သုံးနိုင်တယ်။

### 10.4 Status Code အဓိပ္ပာယ်

| Code | အဓိပ္ပာယ် | UI က ဘာလုပ်ရမလဲ |
|---|---|---|
| 200 | အောင်မြင် | data ပြ |
| 201 | အသစ်ဖန်တီးပြီး | data ပြ |
| 400 | request မှား | message ပြ |
| 401 | token မရှိ/သက်တမ်းကုန် | login ပို့၊ token ဖျက် |
| 403 | ခွင့်မရှိ (admin only) | message ပြ |
| 404 | data မရှိ | empty state ပြ (error မဟုတ်) |
| 409 | conflict | dialog နဲ့ မေးပြီး ပြန် resubmit |
| 422 | validation/business rule | `details` ပြ |
| 429 | rate limit | ခဏစောင့်ပါ |
| 500 | server error | retry/message |

**အရေးကြီး:** `GET /budget` နဲ့ `GET /plans` က data မရှိရင် `404` ပြန်တယ်။ ဒါက error မဟုတ်ဘဲ **"ဒီနေ့အတွက် မရှိသေးဘူး"** ဆိုတဲ့ empty state ပါ။ UI မှာ error banner မပြဘဲ "Set budget"/"No plan yet" ပြရမယ်။

### 10.5 Date

- Backend က `YYYY-MM-DD` ပဲ လက်ခံတယ်။
- `DateTime.now().toIso8601String()` က `2026-11-12T...` ဆိုတဲ့ time ပါတယ်။ **မသုံးရပါ**။

```dart
String apiDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
```

- Backend ရဲ့ "today" က `Asia/Yangon` timezone ပါ။ Client device timezone ကွာနေရင် date မတူနိုင်တယ်။ ဒါကြောင့် "ဒီနေ့" အတွက် `date` ကို မပို့ဘဲ server default ကို သုံးတာ ပိုလုံခြုံပါတယ်။

```dart
// Today's budget — let the server decide "today"
await api.put('/budget', data: {'amount': amount});
```

### 10.6 Money

- အားလုံး **whole MMK integer**။
- Decimal မပို့ပါ။

### 10.7 Food ID

- Backend food id က **UUID**။
- `food_001` လို sample id တွေ မသုံးရပါ။

### 10.8 Plan Rules

- Plan မသိမ်းခင် **budget ရှိရမယ်**။ မရှိရင် `422`။
- `auto` plan က budget ထက် မကျော်ရဘူး။ ကျော်ရင် `422`။
- `manual` plan က budget ကျော်လို့ရတယ်။ response မှာ `overBudget: true` ပြန်တယ်။
- Auto plan က **meal type တစ်ခုကို item တစ်ခု၊ quantity 1** ပဲ။
- Plan သိမ်းတာက expense မဖန်တီးဘူး။

### 10.9 Bearer Token

- Login/Register ကလွဲရင် အားလုံး `Authorization: Bearer <token>` လိုတယ်။
- `ApiClient` က အလိုအလျောက် ထည့်ပေးတယ်။

---

## 11. နောက်ထပ် Page များ ချိတ်နည်း — Concrete Pattern

အောက်က pattern ကို feature တစ်ခုချင်းစီအတွက် ထပ်ခါသုံးနိုင်ပါတယ်။

```text
Endpoint constant
      ↓
Model (fromJson)
      ↓
Repository interface + Remote implementation
      ↓
BLoC (optional, but recommended for complex pages)
      ↓
UI (loading / error / empty / success)
```

### 11.1 Foods Page ကို API ချိတ်ခြင်း

#### Step 1 — Model

```dart
class Food {
  const Food({
    required this.id,
    required this.name,
    required this.price,
    required this.shopName,
    required this.location,
    required this.category,
    this.imagePath,
  });

  final String id;
  final String name;
  final int price;
  final String shopName;
  final String location;
  final String category;
  final String? imagePath;

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      shopName: json['shopName'] as String? ?? '',
      location: json['location'] as String? ?? '',
      category: json['category'] as String? ?? 'Others',
      imagePath: json['imagePath'] as String?,
    );
  }
}
```

#### Step 2 — Repository

```dart
abstract interface class FoodRepository {
  Future<List<Food>> fetchFoods({
    String? category,
    String? search,
    String? sort,
    int page = 1,
    int limit = 50,
  });
}
```

```dart
class RemoteFoodRepository implements FoodRepository {
  const RemoteFoodRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<Food>> fetchFoods({
    String? category,
    String? search,
    String? sort,
    int page = 1,
    int limit = 50,
  }) async {
    final body = await _apiClient.get(
      ApiEndpoints.foods,
      queryParameters: {
        if (category != null && category != 'All') 'category': category,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (sort != null) 'sort': sort,
        'page': page,
        'limit': limit,
      },
      authenticated: false, // catalog browsing is public
    );

    final data = body['data'];
    if (data is! Map) {
      throw const ApiException('Unexpected response from the server.');
    }

    final list = data['foods'] as List<dynamic>? ?? const [];

    return list
        .whereType<Map>()
        .map((json) => Food.fromJson(Map<String, dynamic>.from(json)))
        .toList(growable: false);
  }
}
```

#### Step 3 — Provider

`main.dart` မှာ repository ကို ထည့်ပါ။

```dart
final foodRepository = RemoteFoodRepository(apiClient);

RepositoryProvider<ApiClient>.value(
  value: apiClient,
  child: MultiRepositoryProvider(
    providers: [
      RepositoryProvider<FoodRepository>.value(value: foodRepository),
    ],
    child: BlocProvider(
      create: (_) => AuthBloc(authRepository)..add(const AuthStarted()),
      child: MaterialApp(...),
    ),
  ),
)
```

#### Step 4 — BLoC (optional)

Foods page က search/category/favorite state တွေ များတဲ့အတွက် BLoC နဲ့ ခွဲတာ ကောင်းပါတယ်။

```dart
sealed class FoodsEvent extends Equatable {
  const FoodsEvent();
}

final class FoodsRequested extends FoodsEvent {
  const FoodsRequested({
    this.category = 'All',
    this.search = '',
  });

  final String category;
  final String search;
}

final class FoodsSearchChanged extends FoodsEvent {
  const FoodsSearchChanged(this.query);

  final String query;
}

class FoodsState extends Equatable {
  const FoodsState({
    this.status = FoodsStatus.initial,
    this.foods = const [],
    this.errorMessage,
  });

  final FoodsStatus status;
  final List<Food> foods;
  final String? errorMessage;
}
```

```dart
class FoodsBloc extends Bloc<FoodsEvent, FoodsState> {
  FoodsBloc(this._repository) : super(const FoodsState()) {
    on<FoodsRequested>(_onRequested);
    on<FoodsSearchChanged>(_onSearchChanged);
  }

  final FoodRepository _repository;

  Future<void> _onRequested(
    FoodsRequested event,
    Emitter<FoodsState> emit,
  ) async {
    emit(state.copyWith(status: FoodsStatus.loading));

    try {
      final foods = await _repository.fetchFoods(
        category: event.category,
        search: event.search,
      );

      emit(state.copyWith(
        status: FoodsStatus.success,
        foods: foods,
        errorMessage: null,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(
        status: FoodsStatus.failure,
        errorMessage: error.message,
      ));
    }
  }
}
```

#### Step 5 — UI States

```dart
BlocBuilder<FoodsBloc, FoodsState>(
  builder: (context, state) {
    if (state.status == FoodsStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == FoodsStatus.failure) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.errorMessage ?? 'Could not load foods.'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                context.read<FoodsBloc>().add(const FoodsRequested());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.foods.isEmpty) {
      return const Center(child: Text('No foods found.'));
    }

    return ListView.builder(
      itemCount: state.foods.length,
      itemBuilder: (context, index) {
        final food = state.foods[index];
        return ListTile(
          title: Text(food.name),
          subtitle: Text('${food.shopName} · ${food.price} Ks'),
        );
      },
    );
  },
)
```

#### Step 6 — Existing props ကို အစားထိုးခြင်း

`FoodsPage` ရဲ့ —

```dart
this.foods = sampleFoodCatalog,
this.initialFavoriteIds = const {},
```

ကို API data နဲ့ အစားထိုးပါ။ ဒါပေမယ့် `FoodCatalogItem` နဲ့ `Food` က field တူတာမို့ `FoodCatalogItem` ကို ဖျက်ပြီး `Food` ကို သုံးတာ ပိုရှင်းပါတယ်။

**အရေးကြီး:** Plan save လုပ်တဲ့အခါ `food.id` က backend UUID ဖြစ်ရမယ်။

### 11.2 Plan ကို Backend သိမ်းခြင်း

#### Step 1 — Payload Mapping

AutoPlan ကို —

```dart
Map<String, dynamic> autoPlanPayload(AutoPlan plan) {
  return {
    'method': 'auto',
    'items': [
      for (final entry in plan.meals.entries)
        {
          'foodId': entry.value.id,
          'quantity': 1, // auto plans always use quantity 1
          'mealType': entry.key.name, // breakfast/lunch/snacks/dinner
        },
    ],
  };
}
```

ManualPlan ကို —

```dart
Map<String, dynamic> manualPlanPayload(ManualPlan plan) {
  return {
    'method': 'manual',
    'items': [
      for (final entry in plan.meals.entries)
        for (final item in entry.value)
          {
            'foodId': item.food.id,
            'quantity': item.quantity,
            'mealType': entry.key.name,
          },
    ],
  };
}
```

`MealType` enum ရဲ့ `name` က backend ရဲ့ `breakfast|lunch|snacks|dinner` နဲ့ ကိုက်ညီတယ်။

#### Step 2 — Repository

```dart
abstract interface class PlanRepository {
  Future<void> savePlan({
    required DateTime date,
    required String method,
    required List<Map<String, dynamic>> items,
  });

  Future<PlanResponse?> fetchPlan({DateTime? date});
  Future<void> deletePlan({DateTime? date});
}
```

```dart
class RemotePlanRepository implements PlanRepository {
  const RemotePlanRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<void> savePlan({
    required DateTime date,
    required String method,
    required List<Map<String, dynamic>> items,
  }) async {
    await _apiClient.post(
      ApiEndpoints.plans,
      data: {
        'date': apiDate(date),
        'method': method,
        'items': items,
      },
    );
  }
}
```

#### Step 3 — HomePage Callback ကို ချိတ်ခြင်း

လက်ရှိ —

```dart
Future<void> _savePlan(BuildContext homeContext, Object plan) async {
  _savedTodayPlan.value = plan;
  // ...
}
```

ကို —

```dart
Future<void> _savePlan(BuildContext homeContext, Object plan) async {
  final repository = homeContext.read<PlanRepository>();

  try {
    if (plan is AutoPlan) {
      await repository.savePlan(
        date: plan.date,
        method: 'auto',
        items: autoPlanPayload(plan)['items'] as List<Map<String, dynamic>>,
      );
    } else if (plan is ManualPlan) {
      await repository.savePlan(
        date: plan.date,
        method: 'manual',
        items: manualPlanPayload(plan)['items'] as List<Map<String, dynamic>>,
      );
    }

    _savedTodayPlan.value = plan;

    final homeRoute = ModalRoute.of(homeContext);
    if (homeRoute != null) {
      Navigator.of(homeContext)
          .popUntil((route) => identical(route, homeRoute));
    }
  } on ApiException catch (error) {
    if (!homeContext.mounted) return;

    ScaffoldMessenger.of(homeContext).showSnackBar(
      SnackBar(content: Text(error.message)),
    );
  }
}
```

#### Step 4 — App စတာနဲ့ Plan ပြန်ဖတ်ခြင်း

```dart
Future<void> _loadTodayPlan(BuildContext context) async {
  try {
    final response = await context.read<PlanRepository>().fetchPlan();
    if (response != null) {
      _savedTodayPlan.value = response.toLocalPlan();
    }
  } on ApiException catch (error) {
    if (error.statusCode == 404) {
      _savedTodayPlan.value = null; // no plan yet — normal
      return;
    }
    // show error
  }
}
```

`GET /plans` က `data.plan`, `data.budget`, `data.remaining`, `data.overBudget` ပြန်တယ်။ Backend plan item ရဲ့ field `food` က food id ဖြစ်တာကို သတိထားပါ။

### 11.3 Budget ကို ပြန်ဖတ်ခြင်း

လက်ရှိ အတိုချိတ်ထားတဲ့ `PUT /budget` ကို `BudgetRepository` ထဲ ရွှေ့ပြီး `GET /budget` ပါ ထည့်ပါ။

```dart
class RemoteBudgetRepository implements BudgetRepository {
  const RemoteBudgetRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<int?> fetchBudget({DateTime? date}) async {
    try {
      final body = await _apiClient.get(
        ApiEndpoints.budget,
        queryParameters: date == null ? null : {'date': apiDate(date)},
      );

      final data = body['data'];
      if (data is! Map) return null;

      final budget = data['budget'];
      if (budget is! Map) return null;

      return (budget['amount'] as num?)?.toInt();
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null; // no budget yet
      rethrow;
    }
  }

  @override
  Future<void> saveBudget({
    required int amount,
    DateTime? date,
  }) async {
    await _apiClient.put(
      ApiEndpoints.budget,
      data: {
        if (date != null) 'date': apiDate(date),
        'amount': amount,
      },
    );
  }
}
```

ပြီးတော့ logged-in user အတွက် `HomePage` က `GET /budget` ကို ခေါ်ပြီး `GuestBudget` ကို sync လုပ်ပါ။

```dart
if (isLoggedIn) {
  final amount = await budgetRepository.fetchBudget();
  if (amount != null) GuestBudget.save(amount);
}
```

ဒါဆို app ပြန်ဖွင့်တာနဲ့ backend budget ကို ပြနိုင်မယ်။

### 11.4 Favorites ချိတ်ခြင်း

```dart
Future<Set<String>> fetchFavoriteIds() async {
  final body = await apiClient.get(ApiEndpoints.favorites);
  final data = body['data'];
  if (data is! Map) return {};

  final list = data['favorites'] as List<dynamic>? ?? const [];

  return list
      .whereType<Map>()
      .map((favorite) {
        final food = favorite['food'];
        if (food is Map) return food['id']?.toString() ?? '';
        return '';
      })
      .where((id) => id.isNotEmpty)
      .toSet();
}

Future<void> addFavorite(String foodId) async {
  await apiClient.post(
    ApiEndpoints.favorites,
    data: {'foodId': foodId},
  );
}

Future<void> removeFavorite(String foodId) async {
  await apiClient.delete(ApiEndpoints.favorite(foodId));
}
```

`POST /favorites` က ရှိပြီးသား food ဆို `409` ပြန်တယ်။

```dart
on ApiException catch (error) {
  if (error.isConflict) {
    // already favorited — safe to ignore or refresh
  } else {
    rethrow;
  }
}
```

### 11.5 Expenses / History / Reports

ဒီသုံးခုက read/write pattern ရိုးရှင်းပါတယ်။

**Expenses**

```dart
// GET /expenses?date=YYYY-MM-DD
final body = await apiClient.get(
  ApiEndpoints.expenses,
  queryParameters: {'date': apiDate(date)},
);

// 404 = no expenses recorded for that date
```

```dart
// POST /expenses
await apiClient.post(
  ApiEndpoints.expenses,
  data: {
    'date': apiDate(date),
    'items': [
      {
        'name': name,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'mealType': mealType,
      },
    ],
  },
);
```

Rules:

- Future date မရဘူး။
- Catalog နဲ့ မသက်ဆိုင်ဘူး။
- Plan နဲ့ မသက်ဆိုင်ဘူး။
- တစ်နေ့လုံးကို atomically replace လုပ်တယ်။

**History**

```dart
final body = await apiClient.get(
  ApiEndpoints.history,
  queryParameters: {
    'from': apiDate(from),
    'to': apiDate(to),
    'page': 1,
    'limit': 30,
  },
);
```

Response:

```json
{
  "data": {
    "days": [
      {
        "date": "2026-11-12",
        "total": 6000,
        "byMealType": {
          "breakfast": 2000,
          "lunch": 4000
        }
      }
    ],
    "summary": {
      "from": "2026-10-14",
      "to": "2026-11-12",
      "dayCount": 1,
      "totalSpent": 6000,
      "averagePerDay": 6000
    }
  }
}
```

**Reports**

```dart
final body = await apiClient.get(
  ApiEndpoints.reports,
  queryParameters: {
    'period': 'weekly', // daily | weekly | monthly
    'from': apiDate(from),
    'to': apiDate(to),
  },
);
```

Reports က **expenses ကနေပဲ** တွက်တယ်။ Plan/budget မပါဘူး။

### 11.6 Guest Transfer

Login/Signup အောင်မြင်တာနဲ့ guest data ကို account ထဲ ရွှေ့နိုင်တယ်။

```dart
Future<void> transferGuestData({
  required int? guestBudget,
  required Map<String, dynamic>? guestPlan,
}) async {
  await apiClient.post(
    ApiEndpoints.guestTransfer,
    data: {
      if (guestBudget != null) 'budget': {'amount': guestBudget},
      if (guestPlan != null) 'plan': guestPlan,
    },
  );
}
```

Account မှာ data ရှိပြီးသားဆို backend က `409` ပြန်တယ်။

```json
{
  "success": false,
  "message": "Account data conflicts with guest data for this date. Resubmit with resolution ...",
  "details": [
    { "field": "budget", "message": "The account already has a budget..." },
    { "field": "plan", "message": "The account already has a saved meal plan..." }
  ]
}
```

ဒီအခါ UI က dialog နဲ့ မေးပြီး ပြန် resubmit လုပ်ရတယ်။

```dart
on ApiException catch (error) {
  if (!error.isConflict) rethrow;

  final replace = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Guest Data Found'),
      content: Text(error.message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep Account'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Replace with Guest'),
        ),
      ],
    ),
  );

  if (replace == null) return;

  await apiClient.post(
    ApiEndpoints.guestTransfer,
    data: {
      // ...same payload...
      'resolution': replace ? 'replace-with-guest' : 'keep-account',
    },
  );
}
```

---

## 12. လက်ရှိ Code ၏ အားသာချက် / အားနည်းချက်

### အားသာချက်

- `main.dart` က composition root အနေနဲ့ ရှင်းရှင်းလင်းလင်း ရှိတယ်။
- `ApiClient` က token injection နဲ့ error conversion ကို ဗဟိုချုပ်ထားတယ်။
- Auth က repository + BLoC နဲ့ အပြည့်အစုံချိတ်ထားတယ်။
- Planner/Page တွေက **callback/props** နဲ့ ရေးထားတာမို့ backend ချိတ်ဖို့ seam ကောင်းတွေ ရှိတယ်။
- `ApiException.details` က backend field error တွေနဲ့ တိုက်ရိုက်ကိုက်တယ်။

### အားနည်းချက်

- Auth ကလွဲရင် ကျန်တဲ့ feature တွေမှာ repository/BLoC မရှိသေးဘူး။
- Budget က `ApiClient` ကို UI ထဲက တိုက်ရိုက်ခေါ်တယ်။ နောက်ပိုင်း feature တွေ များလာရင် UI ထဲမှာ API code တွေ ရှုပ်လာနိုင်တယ်။
- Logged-in user ရဲ့ budget/plan ကို app စတာနဲ့ backend ကနေ ပြန်မဖတ်ဘူး။
- Foods catalog က local sample ဖြစ်နေတာမို့ backend plan save နဲ့ တိုက်ရိုက် မကိုက်ဘူး။
- 401 ကို global မကိုင်ဘူး။
- `HomePage` က `StatelessWidget` ဖြစ်ပြီး static `ValueNotifier` တွေ သုံးတယ်။ Backend state ပါ ထည့်လာရင် StatefulWidget/Bloc ကို ပြောင်းတာ ပိုသင့်တော်ပါတယ်။
- Profile update/password change UI မရှိသေးဘူး။
- Reports/Expenses/History က "not implemented" snackbar ပဲ။

---

## 13. ဘယ်အစီအစဉ်နဲ့ ချိတ်သင့်လဲ

အကောင်းဆုံး အစီအစဉ်က —

1. **Endpoint constants + Models**
   - `Food`, `Plan`, `PlanItem`, `Budget`, `Expense`, `HistoryDay`, `ReportBucket`
2. **FoodRepository + Foods page**
   - `GET /foods` ကို အရင်ချိတ်
   - sample id တွေကို backend UUID တွေနဲ့ အစားထိုး
3. **BudgetRepository**
   - `GET /budget` + `PUT /budget`
   - logged-in user အတွက် app စတာနဲ့ load
4. **PlanRepository**
   - `GET /plans`, `POST /plans`, `DELETE /plans`
   - `onSave` callback ကို backend ချိတ်
5. **Favorites**
   - `GET/POST/DELETE /favorites`
6. **Expenses + History + Reports**
   - Expenses ကို အရင်ချိတ် (ဒါမှ history/reports မှာ data ပေါ်မယ်)
7. **Guest transfer**
   - login/signup အောင်မြင်တာနဲ့ guest data ရွှေ့
8. **Profile update + password change**
9. **Global 401 handling**
   - `ApiClient` မှာ 401 ရရင် token ဖျက်ပြီး `AuthLogoutRequested` ပို့တဲ့ interceptor

---

## 14. အမှားများလေ့ရှိသော အချက်များ — Checklist

- [ ] `body['data']` ကို ဆွဲထုတ်ဖို့ မေ့နေခြင်း
- [ ] `DateTime.toIso8601String()` ကို date အဖြစ် ပို့ခြင်း (`YYYY-MM-DD` မဟုတ်)
- [ ] `food_001` လို sample ID ကို backend ကို ပို့ခြင်း (UUID လိုတယ်)
- [ ] Plan မသိမ်းခင် budget မတင်ထားခြင်း (`422`)
- [ ] `GET /budget`/`GET /plans` ရဲ့ `404` ကို error အနေနဲ့ ပြခြင်း
- [ ] Login/Register မှာ `authenticated: false` မပေးခြင်း
- [ ] `await` ပြီးနောက် `context` ကို `mounted` မစစ်ဘဲ သုံးခြင်း
- [ ] `ApiClient` က `data` မဟုတ်ဘဲ body တစ်ခုလုံး ပြန်တာကို မေ့နေခြင်း
- [ ] Auto plan မှာ meal type တစ်ခုကို item နှစ်ခု ပို့ခြင်း (`422`)
- [ ] Manual plan က budget ကျော်လို့ရတာကို မသိခြင်း (`overBudget` warning)
- [ ] Plan သိမ်းတာနဲ့ expense ပါ ဖန်တီးမယ်လို့ ထင်ခြင်း (မဖန်တီးဘူး)
- [ ] 401 ကို global မကိုင်ဘဲ page တစ်ခုချင်း လုပ်နေခြင်း
- [ ] Physical device မှာ `localhost` သုံးခြင်း
- [ ] Guest data ကို login ပြီးနောက် မရွှေ့ခြင်း

---

## 15. အနှစ်ချုပ်

ဒီ project ရဲ့ API ချိတ်ဆက်ပုံကို တစ်ကြောင်းတည်း ပြောရရင် —

```text
main.dart က TokenStorage → ApiClient → Repository → AuthBloc ကို တည်ဆောက်
ApiClient က baseUrl + Bearer token + error conversion ကို ကိုင်
AuthRepository က endpoint ခေါ်ပြီး body['data'] ကို model အဖြစ် ပြောင်
AuthBloc က event → loading → success/error state ပြောင်
UI က BlocConsumer/BlocBuilder/watch နဲ့ state ကို ဖတ်ပြီး ပြ
```

လက်ရှိ **Auth နဲ့ Budget save** ပဲ အပြည့်အစုံချိတ်ထားပြီး ကျန်တဲ့ feature တွေက UI-only ဖြစ်ပါတယ်။ ဒါပေမယ့် UI တွေက `onSave`, `onFavoritesChanged`, `savedPlan`, `foods` စတဲ့ **props/callback** တွေနဲ့ ရေးထားတာမို့ backend ချိတ်တဲ့အခါ page တွေကို အပြင်ကြီး ပြင်စရာမလိုဘဲ callback ထဲမှာ repository call ထည့်ရုံနဲ့ ချိတ်နိုင်ပါတယ်။

အရေးကြီးဆုံး အစီအစဉ်က **Foods catalog → Budget → Plans → Favorites → Expenses → History/Reports → Guest transfer** ဆိုတဲ့ အစီအစဉ်ပါ။ အဲဒီအစီအစဉ်အတိုင်း သွားရင် dependency တွေ မရှုပ်ဘဲ တစ်ဆင့်ချင်း အလုပ်လုပ်တဲ့ UI ကို ရနိုင်ပါတယ်။

---

## Appendix — Endpoint Quick Reference

### Auth & Profile

| Method | Path | Body | Auth |
|---|---|---|---|
| POST | `/auth/register` | `{ name, email, password }` | No |
| POST | `/auth/login` | `{ email, password }` | No |
| GET | `/auth/me` | — | Yes |
| POST | `/auth/logout` | — | Yes |
| PATCH | `/users/me` | `{ name }` | Yes |
| PATCH | `/users/me/password` | `{ currentPassword, newPassword }` | Yes |

### Foods

| Method | Path | Body / Query | Auth |
|---|---|---|---|
| GET | `/foods` | `?category=&search=&sort=&page=&limit=` | No |
| GET | `/foods/:id` | — | No |
| POST | `/foods` | `{ name, shopName, location?, category, price, imagePath? }` | Admin |
| PATCH | `/foods/:id` | partial fields | Admin |
| DELETE | `/foods/:id` | — | Admin |

### Favorites

| Method | Path | Body | Auth |
|---|---|---|---|
| GET | `/favorites` | — | Yes |
| POST | `/favorites` | `{ foodId }` | Yes |
| DELETE | `/favorites/:foodId` | — | Yes |

### Budget

| Method | Path | Body / Query | Auth |
|---|---|---|---|
| GET | `/budget` | `?date=YYYY-MM-DD` | Yes |
| PUT | `/budget` | `{ date?, amount }` | Yes |

### Plans

| Method | Path | Body / Query | Auth |
|---|---|---|---|
| GET | `/plans` | `?date=YYYY-MM-DD` | Yes |
| POST | `/plans` | `{ date?, method: auto\|manual, items: [{ foodId, quantity, mealType }] }` | Yes |
| DELETE | `/plans` | `?date=YYYY-MM-DD` | Yes |

### Expenses

| Method | Path | Body / Query | Auth |
|---|---|---|---|
| GET | `/expenses` | `?date=YYYY-MM-DD` | Yes |
| POST | `/expenses` | `{ date?, items: [{ name, quantity, unitPrice, mealType }] }` | Yes |
| DELETE | `/expenses` | `?date=YYYY-MM-DD` | Yes |

### History / Reports

| Method | Path | Query | Auth |
|---|---|---|---|
| GET | `/history` | `?from=&to=&page=&limit=` | Yes |
| GET | `/reports` | `?period=daily\|weekly\|monthly&from=&to=` | Yes |

### Guest Transfer

| Method | Path | Body | Auth |
|---|---|---|---|
| POST | `/guest-transfer` | `{ date?, budget?: { amount }, plan?: { method, items }, resolution? }` | Yes |

---

*Document generated from the MealMate Flutter + Express/PostgreSQL project structure.*
