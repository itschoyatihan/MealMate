# MealMate — လက်ရှိ Project တိုးတက်မှု အခြေအနေ ခွဲခြမ်းစိတ်ဖြာချက်

> ဒီ document က `PROJECT1` ရဲ့ လက်ရှိ source code (Flutter `lib/` နှင့် Express/PostgreSQL `backend/`) ကို တိုက်ရိုက်ဖတ်ပြီး ရေးထားတဲ့ progress report ဖြစ်ပါတယ်။  
> ရည်ရွယ်ချက်က — ဘယ်အပိုင်း ပြီးပြီလဲ၊ ဘယ်အပိုင်း မပြီးသေးလဲ၊ ချိတ်ပြီးသားအပိုင်းတွေ ဘယ်လိုတည်ဆောက်ထားလဲ၊ ဘာအားနည်းချက်တွေ ရှိလဲ၊ နောက်ထပ် checkpoint တွေ ဘာတွေလဲ ဆိုတာကို တစ်နေရာတည်းမှာ ရှင်းရှင်းလင်းလင်း ဖတ်နိုင်ဖို့ပါ။

**စစ်ဆေးသည့်ရက်စွဲ:** 2026-11-12  
**Code အခြေအနေ:** Local working copy (git repo မဟုတ်)  
**Backend:** PostgreSQL သို့ ပြောင်းပြီး၊ endpoint အားလုံး mount ပြီး၊ smoke check 67 ခု pass

---

## 1. တစ်ကြောင်းတည်း အနှစ်ချုပ်

```text
Backend (API + PostgreSQL)        ████████████████████  100%  ပြီး
Flutter UI screens                ██████████████░░░░░░   69%  ပြီး
Flutter ↔ API integration         ██████████░░░░░░░░░░   50%  ပြီး
Automated tests                   ████░░░░░░░░░░░░░░░░   20%  ပြီး
```

လက်ရှိ project က **"အလုပ်လုပ်တဲ့ vertical slice နှစ်ခု + တစ်ဝက်စီပြီးသော slice သုံးခု"** အဆင့်မှာ ရှိပါတယ်။

- **အပြည့်အစုံ အလုပ်လုပ်နေတာ:** Authentication, Daily Budget, Foods Catalog, Favorites, Meal Plan Save/Load
- **UI ရှိပေမယ့် API မချိတ်သေးတာ:** Plan Delete, Profile edit, Change password
- **လုံးဝ မရေးရသေးတာ:** Expenses page, History page, Reports page, Guest data transfer

ဆိုလိုတာက — **ကျောင်းသားတစ်ယောက် register/login လုပ်ပြီး budget ထည့်၊ food catalog ကြည့်၊ favorite လုပ်ပြီး ဒီနေ့အတွက် auto/manual plan သိမ်း/ပြန်ဖတ် လုပ်တဲ့ အထိ အစအဆုံး အလုပ်လုပ်နိုင်ပါပြီ။** ဒါပေမယ့် သိမ်းထားတဲ့ plan ကို server ကနေ ဖျက်တာ၊ expense မှတ်တာ၊ history/report ကြည့်တာ၊ guest data ကို account ထဲ ရွှေ့တာတွေ မရှိသေးပါ။

---

## 2. စစ်ဆေးခဲ့သော Source Files

| အလွှာ | ဖိုင် | အခြေအနေ |
|---|---|---|
| Composition root | `lib/main.dart` | ပြီး |
| Endpoint constants | `lib/constants/api_endpoints.dart` | Auth/Profile ပဲ ပါ |
| Transport | `lib/services/api_client.dart` | ပြီး |
| Error | `lib/services/api_exception.dart` | ပြီး |
| Token | `lib/services/token_storage.dart` | ပြီး |
| Models | `lib/models/user.dart`, `auth_session.dart` | Auth ပဲ ပြီး |
| Repositories | `auth_repository`, `remote_auth_repository`, `food_repository`, `mealplan_repository` | food/plan က interface မရှိ |
| BLoC | `lib/logic/auth/` | Auth ပဲ ရှိ |
| UI | `lib/ui/` (page 11 ခု) | တစ်ချို့ API ချိတ်ပြီး |
| Backend | `backend/` | route အားလုံး ရှိ၊ controller အားလုံး ရှိ |
| Tests | `test/logic/auth_bloc_test.dart`, `test/models/user_test.dart` | ၂ ဖိုင်ပဲ ရှိ |

---

## 3. UI ရေးပြီးသား / မရေးရသေးတဲ့ အပိုင်း

### 3.1 ရေးပြီးသား UI (11 screens)

| # | Screen | ဖိုင် | လုပ်ဆောင်ချက် |
|---|---|---|---|
| 1 | Splash | `splash_page.dart` | ၃ စက္ကန့်ပြ၊ Home ကို ပို့ |
| 2 | Login | `login_page.dart` | Email/password form၊ error banner၊ loading state |
| 3 | Sign Up | `signup_page.dart` | Name/email/password form၊ auto login |
| 4 | Home | `home_page.dart` | Welcome၊ budget card၊ planner cards၊ feature cards၊ today plan |
| 5 | Set Daily Budget | `set_budget.dart` | ပမာဏထည့်၊ validation၊ save callback |
| 6 | Budget Confirmation | `budget_save.dart` | သိမ်းပြီး အတည်ပြု၊ planner ဆက်ဝင်နိုင် |
| 7 | Foods | `foods_page.dart` | Search၊ category filter၊ favorites filter၊ favorite toggle |
| 8 | Automatic Planner | `auto_page.dart` | Local algorithm နဲ့ plan ဆောက်၊ save |
| 9 | Manual Planner | `manual_page.dart` | Meal type အလိုက် food ရွေး၊ quantity၊ save |
| 10 | Manual Browse / Detail | `manual_browse.dart`, `manual_detail.dart` | Food ရှာပြီး ရွေးချယ် |
| 11 | My Plan | `myplan_page.dart` | သိမ်းထားတဲ့ plan ပြ၊ edit၊ delete dialog |

### 3.2 တစ်စိတ်တစ်ပိုင်း ရေးပြီးသား UI

| Screen | ရေးပြီးတာ | မရေးရသေးတာ |
|---|---|---|
| Account / Profile | Dialog နဲ့ name, email, initials, logout | Edit profile form, change password form, save to backend |
| Reports | Home မှာ card + sidebar/bottom nav + login စစ်ခြင်း | Report page လုံးဝ မရှိ |
| Expenses | Home မှာ card ပဲ ရှိ | Expense page, add/edit expense form လုံးဝ မရှိ |
| Meal History | Home မှာ card ပဲ ရှိ | History page လုံးဝ မရှိ |
| Guest Transfer | ဘာမှ မရှိ | Conflict dialog, transfer prompt လုံးဝ မရှိ |

### 3.3 လုံးဝ မရေးရသေးတဲ့ UI (5 screens)

1. **Expenses Page** — နေ့စဉ် စားသုံးမှု မှတ်တမ်း ထည့်/ပြ/ဖျက်
2. **History Page** — ရက်အလိုက် စားသုံးမှု ပြန်ကြည့်၊ summary
3. **Reports Page** — daily/weekly/monthly chart နှင့် total
4. **Profile Settings Page** — အမည်ပြင်၊ password ပြင်
5. **Guest Transfer Screen** — guest budget/plan ကို account ထဲ ရွှေ့ရန် မေးတဲ့ UI

### 3.4 UI coverage

```text
လိုအပ်တဲ့ screen စုစုပေါင်း ≈ 16
ရေးပြီး                    = 11
တစ်စိတ်တစ်ပိုင်း           = 2 (Profile dialog, placeholder cards)
မရေးရသေး                  = 5

UI screen coverage ≈ 11 / 16 = 69%
```

---

## 4. API ချိတ်ပြီးသား / မချိတ်ရသေးတဲ့ အပိုင်း

### 4.1 ချိတ်ပြီးသား endpoints (12 ခု)

| # | Endpoint | ခေါ်တဲ့နေရာ | ဘာအတွက် |
|---|---|---|---|
| 1 | `POST /auth/register` | `RemoteAuthRepository.register` | Account ဖန်တီး |
| 2 | `POST /auth/login` | `RemoteAuthRepository.login` | Login |
| 3 | `GET /auth/me` | `RemoteAuthRepository.restoreSession` | App ပြန်ဖွင့်ရင် session ပြန် |
| 4 | `POST /auth/logout` | `RemoteAuthRepository.logout` | Logout |
| 5 | `PUT /budget` | `HomePage._saveBudgetToBackend` | Budget သိမ်း/ပြင် |
| 6 | `GET /budget` | `_PlanSessionGateState._syncSession` | Budget ပြန်ဖတ် |
| 7 | `GET /foods` | `FoodRepository.getFoods` | Catalog ဆွဲ (page loop) |
| 8 | `GET /favorites` | `FoodRepository.getFavoriteIds` | Favorite id စာရင်း |
| 9 | `POST /favorites` | `FoodRepository.setFavorite` | Favorite ထည့် |
| 10 | `DELETE /favorites/:foodId` | `FoodRepository.setFavorite` | Favorite ဖျက် |
| 11 | `POST /plans` | `MealPlanRepository.save` | Plan သိမ်း |
| 12 | `GET /plans` | `MealPlanRepository.get` | Plan ပြန်ဖတ် |

### 4.2 Repository ထဲ ရေးထားပြီး UI က မခေါ်သေးတာ (3 ခု)

| Endpoint | Code ရှိပေမယ့် | ပြဿနာ |
|---|---|---|
| `DELETE /plans` | `MealPlanRepository.delete` | ဘယ်နေရာကမှ မခေါ်ဘူး |
| `PATCH /users/me` | `RemoteAuthRepository.updateProfile` | UI/BLoC event မရှိ |
| `PATCH /users/me/password` | `RemoteAuthRepository.changePassword` | UI/BLoC event မရှိ |

### 4.3 လုံးဝ မချိတ်ရသေးတာ (9 ခု)

| Endpoint | လိုအပ်တဲ့အလုပ် |
|---|---|
| `GET /expenses` | Expense page load |
| `POST /expenses` | နေ့စဉ် စားသုံးမှု သိမ်း |
| `DELETE /expenses` | နေ့စဉ် မှတ်တမ်း ဖျက် |
| `GET /history` | ရက်အလိုက် သမိုင်း |
| `GET /reports` | daily/weekly/monthly report |
| `POST /guest-transfer` | Guest data ရွှေ့ |
| `GET /foods/:id` | တစ်ခုချင်း detail (လောလောဆယ် မလို) |
| `POST/PATCH/DELETE /foods` | Admin catalog management |
| `GET /health` | Startup/server status check |

### 4.4 Integration coverage

| Feature | UI | API | အခြေအနေ |
|---|---|---|---|
| Register | ရှိ | ချိတ်ပြီး | အပြည့်အစုံ |
| Login | ရှိ | ချိတ်ပြီး | အပြည့်အစုံ |
| Session restore | ရှိ | ချိတ်ပြီး | အပြည့်အစုံ |
| Logout | ရှိ | ချိတ်ပြီး | အပြည့်အစုံ |
| Budget save | ရှိ | ချိတ်ပြီး | အပြည့်အစုံ |
| Budget load | ရှိ | ချိတ်ပြီး | အပြည့်အစုံ |
| Foods catalog | ရှိ | ချိတ်ပြီး | အပြည့်အစုံ |
| Favorites | ရှိ | ချိတ်ပြီး | အပြည့်အစုံ |
| Plan save | ရှိ | ချိတ်ပြီး | အပြည့်အစုံ |
| Plan load | ရှိ | ချိတ်ပြီး | အပြည့်အစုံ |
| Plan delete | ရှိ | မချိတ် | Local only — bug ဖြစ်နိုင် |
| Profile update | Dialog ပဲ | Repo ရှိ၊ UI မရှိ | တစ်စိတ်တစ်ပိုင်း |
| Change password | မရှိ | Repo ရှိ၊ UI မရှိ | တစ်စိတ်တစ်ပိုင်း |
| Expenses | မရှိ | မချိတ် | မစရသေး |
| History | မရှိ | မချိတ် | မစရသေး |
| Reports | မရှိ | မချိတ် | မစရသေး |
| Guest transfer | မရှိ | မချိတ် | မစရသေး |

```text
Feature အရေအတွက် 17
အပြည့်အစုံ        = 10
တစ်စိတ်တစ်ပိုင်း   = 3
မစရသေး           = 4

API integration coverage ≈ 10 / 17 = 59% (တစ်စိတ်တစ်ပိုင်း ထည့်ရင် ≈ 65%)
```

---

## 5. ချိတ်ပြီးသားအပိုင်းတွေ — Construction အလိုက် ရှင်းလင်းချက်

ဒီအပိုင်းက "ဘယ်လိုချိတ်ထားတယ်" ဆိုတာကို အလွှာအလိုက်၊ တကယ့် code အတိုင်း ရှင်းပြထားပါတယ်။

### 5.1 အလွှာ ခြောက်လွှာ ပုံစံ

```text
Flutter UI (Page / Widget)
        │  user action / callback
        ▼
BLoC (AuthBloc သာ အပြည့်ရှိ)
        │
        ▼
Repository (Auth / Food / MealPlan)
        │  body['data'] ဆွဲထုတ်
        ▼
ApiClient (Dio wrapper)
        │  baseUrl + Bearer token
        ▼
Express route → controller → model
        │
        ▼
PostgreSQL
        │
        ▼
{ success, data } / { success, message, details }
```

လက်ရှိ code မှာ route နှစ်မျိုး ရှိတယ်ဆိုတာ သတိထားပါ။

- **အပြည့်အစုံ route:** `UI → BLoC → Repository → ApiClient` (Auth)
- **တိုတို route:** `UI → Repository → ApiClient` (Foods, Favorites, Plans, Budget)
- **အရှင်းဆုံး route:** `UI → ApiClient` (Budget PUT/GET က `home_page.dart` ထဲ တိုက်ရိုက်)

---

### 5.2 Composition Root — `lib/main.dart`

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

Provider tree —

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

အဓိပ္ပာယ် —

- `ApiClient` က app တစ်ခုလုံးအတွက် instance တစ်ခုတည်း။ Page တိုင်း `context.read<ApiClient>()` နဲ့ ယူနိုင်တယ်။
- `AuthBloc` က app တစ်ခုလုံးအတွက် instance တစ်ခုတည်း။ `context.watch<AuthBloc>()` နဲ့ login state ကို စောင့်ကြည့်နိုင်တယ်။
- App စတာနဲ့ `AuthStarted` ပို့ပြီး secure storage ထဲက token ကို ဖတ်ကာ `GET /auth/me` နဲ့ session ပြန်တည်ဆောက်တယ်။

**အားနည်းချက်:** `FoodRepository` နဲ့ `MealPlanRepository` တို့ကို provider မှာ မထည့်ထားဘဲ page တွေထဲမှာ `FoodRepository(context.read<ApiClient>())` လို **နေရာတိုင်းမှာ အသစ်ဆောက်** နေတယ်။ လောလောဆယ် အလုပ်ဖြစ်ပေမယ့် test လုပ်ရခက်တယ်၊ instance များလာတယ်။

---

### 5.3 Transport — `lib/services/api_client.dart`

`ApiClient` က တာဝန် ၃ ခု ရှိတယ်။

1. `baseUrl`, timeout, JSON header သတ်မှတ်
2. Request တိုင်းမှာ `Authorization: Bearer <token>` ထည့်
3. Dio error ကို `ApiException` ပြောင်

Token ထည့်ပုံ —

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

Response ကို **envelope တစ်ခုလုံး** ပြန်တယ်။

```dart
if (body is Map) return Map<String, dynamic>.from(body);
return <String, dynamic>{};
```

ဒါကြောင့် repository တိုင်းက `body['data']` ကို ကိုယ်တိုင် ဆွဲထုတ်ရတယ်။

Base URL resolution —

```text
Windows / Web   → http://localhost:4000/api
Android Emulator→ http://10.0.2.2:4000/api
Physical device → --dart-define=API_BASE_URL=http://<PC-LAN-IP>:4000/api
```

---

### 5.4 Auth Vertical Slice (အပြည့်အစုံ)

```text
LoginPage
   │ AuthLoginRequested(email, password)
   ▼
AuthBloc._onLoginRequested
   │ isSubmitting = true → button disable
   ▼
RemoteAuthRepository.login
   │ POST /auth/login (authenticated: false)
   ▼
_persistSession
   │ body['data'] → AuthSession.fromJson
   │ tokenStorage.saveToken(token)
   ▼
AuthState(status: authenticated, user)
   │ BlocConsumer listener
   ▼
Navigator → HomePage
```

Login repository —

```dart
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
```

Session restore —

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

Session restore ကို app စတာနဲ့ `AuthStarted` က ခေါ်တယ်။

```text
Token မရှိ        → unauthenticated (guest)
Token ရှိ + 200    → authenticated
Token ရှိ + 401    → token ဖျက် → unauthenticated
```

**အားသာချက်:** ဒီ slice က အလွှာအားလုံး (UI → BLoC → Repository → ApiClient → Backend) ဖြတ်ထားတာမို့ ကျန်တဲ့ feature တွေအတွက် စံပြပုံစံ ဖြစ်နေတယ်။

---

### 5.5 Budget Save (တိုက်ရိုက် API ခေါ်)

`home_page.dart` ထဲမှာ —

```dart
Future<void> _saveBudgetToBackend(BuildContext context, int amount) async {
  final api = context.read<ApiClient>();

  final response = await api.put(
    '/budget',
    data: {'date': _todayDate(), 'amount': amount},
  );

  if (response['success'] != true) {
    throw StateError('Budget could not be saved.');
  }
}
```

`openBudget()` ထဲမှာ logged-in ဆိုမှ backend သိမ်းတယ်။

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

Design —

- Guest → `GuestBudget` (memory only)
- Logged-in → `PUT /budget` + `GuestBudget` ကို display အတွက် သိမ်း
- `date` ကို `YYYY-MM-DD` အတိအကျ ပို့
- Backend က budget တစ်ခုတည်း ရှိရမယ်၊ ပြင်ရင် upsert လုပ်
- Budget ပြင်တာ plan ကို မဖျက်ဘူး၊ ရှိရင် `overBudget` warning ပြန်

`_startPlan()` ထဲမှာ budget မရှိသေးရင် planner မဝင်ခင် `SetBudgetPage` ကို အရင်ခေါ်တယ်။ အဲဒီမှာလည်း logged-in ဆို `PUT /budget` ကို တိုက်ရိုက်ခေါ်တယ်။

---

### 5.6 Budget Restore — `_PlanSessionGate`

ဒါက ဒီ project ရဲ့ **အရေးအကြီးဆုံး session orchestration** ပါ။ HomePage ကို wrap ထားတယ်။

```text
HomePage
  └── _PlanSessionGate (StatefulWidget)
        ├── initState → postFrame → _syncSession(authState)
        ├── BlocListener<AuthBloc>
        │     listenWhen: status သို့မဟုတ် email ပြောင်း
        │     listener: _onAuthChanged
        └── child: HomePage UI
```

`_syncSession()` က အစဉ်လိုက် လုပ်တယ်။

1. Account key (`user.email`) တွက်
2. Account မရှိ (guest) ဆို `GuestBudget.clear()` ပြီး ရပ်
3. Account အသစ်ဖြစ်ရင် —
   - `_savedTodayPlan.value = null`
   - `_myPlanSelected.value = false`
   - `GuestBudget.clear()` (အကောင့်တစ်ခုရဲ့ budget ကို နောက်အကောင့် မပြစေရန်)
4. `GET /budget?date=...`
   - 404 က "မရှိသေး" အဖြစ် ကိုင်ပြီး error မပြ
   - `data.budget.amount` ကို `GuestBudget.save()`
5. `GET /foods` နဲ့ catalog ဆွဲ
6. `GET /plans?date=...` နဲ့ plan ဆွဲ
7. Plan items တွေကို food id နဲ့ catalog ထဲ join ပြီး `AutoPlan`/`ManualPlan` ပြန်
8. `HomePage._savedTodayPlan.value = plan`

Race condition ကို ကာကွယ်ထားတယ် —

```dart
final request = ++_requestVersion;
...
if (!mounted || request != _requestVersion) return;
...
if (_accountKey(context.read<AuthBloc>().state) != account) return;
```

ဒါက account လဲလိုက်တဲ့အခါ ရှေးဟောင်း response တွေ UI ကို မရောက်စေရန် ကာကွယ်တယ်။

**အားသာချက်:** App ပြန်ဖွင့်ရင် logged-in user ရဲ့ budget နဲ့ ဒီနေ့ plan ကို server ကနေ ပြန်ပြီး ပြနိုင်တယ်။ Account လဲရင် data မရောတော့ဘူး။

---

### 5.7 Foods Catalog — API ချိတ်ထား

`FoodRepository.getFoods()` က page loop နဲ့ catalog တစ်ခုလုံး ဆွဲတယ်။

```dart
var page = 1;
while (true) {
  final body = await api.get(
    '/foods',
    authenticated: false,
    queryParameters: {'page': page, 'limit': 100},
  );

  if (body['success'] != true) {
    throw StateError('Cannot load foods.');
  }

  final data = Map<String, dynamic>.from(body['data'] as Map);
  final rows = data['foods'] as List;

  for (final row in rows) {
    final food = Map<String, dynamic>.from(row as Map);
    result.add(FoodCatalogItem(
      id: food['id'].toString(),
      name: food['name'].toString(),
      price: (food['price'] as num).toInt(),
      shopName: food['shopName'].toString(),
      location: (food['location'] ?? '').toString(),
      category: food['category'].toString(),
      imagePath: food['imagePath']?.toString(),
    ));
  }

  final pagination = Map<String, dynamic>.from(data['pagination'] as Map);
  if (pagination['hasMore'] != true) break;
  page++;
}
```

အဓိကအချက် —

- Backend က **UUID** ပြန်တယ်။ `food_001` မဟုတ်တော့ဘူး။
- `pagination.hasMore` မပြီးမချင်း page တွေ ဆက်ဆွဲ
- `authenticated: false` ဖြစ်လို့ guest လည်း catalog ကြည့်နိုင်တယ်
- Search နဲ့ category ကို API မှာ မစစ်ဘဲ **client မှာ local filter** လုပ်တယ် (`FoodsPage._visibleFoods`)

`HomePage._openFoods()` က —

```dart
final foods = await repository.getFoods();

final favoriteIds = isLoggedIn
    ? await repository.getFavoriteIds()
    : <String>{};

Navigator.push(
  FoodsPage(
    isLoggedIn: isLoggedIn,
    foods: foods,
    initialFavoriteIds: favoriteIds,
    onFavoriteToggle: isLoggedIn ? repository.setFavorite : null,
    ...
  ),
);
```

`_plannerPage()` ကလည်း logged-in ဆို API catalog ကို `FutureBuilder` နဲ့ ဆွဲပြီး planner ကို ပေးတယ်။ Guest ဆို `sampleFoodCatalog` ကို သုံးတယ်။

---

### 5.8 Favorites — API ချိတ်ထား

```dart
Future<Set<String>> getFavoriteIds() async {
  final body = await api.get('/favorites');
  ...
  return rows.map((row) {
    final favorite = Map<String, dynamic>.from(row as Map);
    final food = favorite['food'];
    if (food is Map) return food['id'].toString();
    return (favorite['foodId'] ?? favorite['food_id']).toString();
  }).toSet();
}

Future<void> setFavorite(String foodId, bool add) async {
  final Map<String, dynamic> body;
  if (add) {
    body = await api.post('/favorites', data: {'foodId': foodId});
  } else {
    body = await api.delete('/favorites/$foodId');
  }
  if (body['success'] != true) {
    throw StateError('Cannot update favorite.');
  }
}
```

`FoodsPage._toggleFavorite()` ရဲ့ flow —

```text
Guest ဖြစ်ရင် → login dialog → ရပ်
တန်းစီနေဆဲ id ဖြစ်ရင် → ရပ် (double tap ကာကွယ်)
add = !_favoriteIds.contains(id)
  │
  ├─ onFavoriteToggle null → local setState (fallback)
  │
  └─ onFavoriteToggle ရှိ → await API
        ├─ success → setState add/remove
        └─ failure → snackbar, local မပြောင်း
```

**အားသာချက်:** Backend မအောင်မြင်ရင် UI state မပြောင်းဘူး။ Double tap ကို `_updatingFavorites` နဲ့ ကာကွယ်ထားတယ်။

**အားနည်းချက်:** Optimistic update မဟုတ်လို့ network နှေးရင် icon ပြောင်းဖို့ စောင့်ရတယ်။ 409 (already favorite) ကို အထူးမကိုင်ဘဲ generic error ပြတယ်။

---

### 5.9 Plan Save — Auto/Manual နှစ်မျိုးလုံး ချိတ်ထား

Planner page တွေက `onSave` callback ပေးတယ်။ `HomePage._savePlan()` က လက်ခံတယ်။

```dart
Future<void> _savePlan(BuildContext homeContext, Object plan) async {
  final isLoggedIn = homeContext.read<AuthBloc>().state.isAuthenticated;

  if (isLoggedIn) {
    final repository = MealPlanRepository(homeContext.read<ApiClient>());
    // Backend must save successfully before updating the UI.
    await repository.save(plan);
  }

  _savedTodayPlan.value = plan;

  final homeRoute = ModalRoute.of(homeContext);
  if (homeRoute != null) {
    Navigator.of(homeContext).popUntil((route) => identical(route, homeRoute));
  }
}
```

ဒီမှာ **အရေးကြီးတဲ့ design decision** ရှိတယ် — backend save မအောင်မြင်ရင် local UI ကို မပြောင်းဘူး။ `await repository.save(plan)` က မအောင်မြင်ရင် throw ဖြစ်ပြီး အောက်ကို မဆက်ဘူး။

`MealPlanRepository.save()` က plan အမျိုးအစားကို ခွဲတယ်။

Auto plan —

```dart
if (plan is AutoPlan) {
  date = plan.date;
  method = 'auto';
  items = [
    for (final entry in plan.meals.entries)
      {'foodId': entry.value.id, 'quantity': 1, 'mealType': entry.key.name},
  ];
}
```

Manual plan —

```dart
} else if (plan is ManualPlan) {
  date = plan.date;
  method = 'manual';
  items = [
    for (final entry in plan.meals.entries)
      for (final item in entry.value)
        {
          'foodId': item.food.id,
          'quantity': item.quantity,
          'mealType': entry.key.name,
        },
  ];
}
```

Payload —

```json
{
  "date": "2026-11-12",
  "method": "auto",
  "items": [
    { "foodId": "uuid", "quantity": 1, "mealType": "breakfast" }
  ]
}
```

Backend က စစ်တာ —

- Budget မရှိရင် `422`
- Auto plan budget ကျော်ရင် `422` (မသိမ်း)
- Manual plan budget ကျော်လို့ရ၊ `overBudget: true` ပြန်
- Auto plan မှာ meal type တစ်ခုကို item တစ်ခု၊ quantity 1 ပဲ
- ဒီနေ့ plan ရှိရင် အဟောင်းကို replace
- Price ကို server က catalog ကနေ ပြန်ယူ (client price ကို မယုံ)
- Plan သိမ်းတာ expense မဖန်တီး

**အားနည်းချက်:** Planner page တွေက error ကို `catch (_)` နဲ့ ဖမ်းပြီး **generic snackbar** ပဲ ပြတယ်။ Backend ရဲ့ "Set a daily budget for 2026-11-12 before saving..." ဆိုတဲ့ အသုံးဝင်တဲ့ message ကို မပြဘူး။

---

### 5.10 Plan Load — Session Gate ကနေ ပြန်ဖတ်

```dart
final foods = await FoodRepository(api).getFoods();

final plan = await MealPlanRepository(api)
    .getSavedPlan(DateTime.now(), foods);

HomePage._savedTodayPlan.value = plan;
```

`getSavedPlan()` က API plan ကို local model ပြန်ပြောင်းတယ်။

```dart
final savedDate = DateTime.parse(
  (plan['date'] ?? plan['planDate'] ?? '<fallback>').toString(),
);

for (final raw in rawItems) {
  final item = Map<String, dynamic>.from(raw as Map);
  final foodId = (item['food'] ?? item['foodId'] ?? item['food_id'])?.toString();
  final food = foodsById[foodId];
  if (food == null) {
    throw FormatException('Food $foodId is missing from the catalog.');
  }

  final type = MealType.values.byName(
    (item['mealType'] ?? item['meal_type']).toString(),
  );

  if (method == 'auto') {
    meals[type] = food;
  } else {
    (meals[type] ??= []).add(
      ManualItem(food: food, quantity: (item['quantity'] as num).toInt()),
    );
  }
}
```

ဒီမှာ **catalog join** အရေးကြီးတယ်။ Backend plan item ထဲက food က id string ပဲ ဖြစ်တယ်။ ဒါကြောင့် UI မှာ ပြဖို့ catalog ကို အရင်ဆွဲပြီး id နဲ့ ပြန်တွဲရတယ်။

---

### 5.11 Guest Mode — Local only ဒီဇိုင်း

```text
Guest
  ├── Budget → GuestBudget (memory)
  ├── Planner catalog → sampleFoodCatalog
  ├── Plan save → _savedTodayPlan (static ValueNotifier)
  └── Favorites → login dialog (ခွင့်မပြု)
```

`GuestBudget` —

```dart
class GuestBudget {
  static final ValueNotifier<int?> dailyBudget = ValueNotifier<int?>(null);

  static int? get amount => dailyBudget.value;
  static bool get hasBudget => amount != null;

  static void save(int amount) { ... }
  static void clear() => dailyBudget.value = null;
}
```

ဒါက app ပိတ်ရင် ပျောက်တယ်။ Database မပါဘူး။

---

## 6. လက်ရှိ အားနည်းချက်များ

### 6.1 အရေးကြီး (ချက်ချင်း ပြင်သင့်)

| # | ပြဿနာ | ဖိုင် | သက်ရောက်မှု |
|---|---|---|---|
| 1 | **Plan delete က local only** — `onDelete` က `_savedTodayPlan.value = null` ပဲ လုပ်၊ `DELETE /plans` မခေါ် | `home_page.dart` နှင့် `myplan_page.dart` | App ပြန်ဖွင့်ရင် ဖျက်လိုက်တဲ့ plan ပြန်ပေါ်လာမယ် |
| 2 | **Guest data transfer မရှိ** — login ဖြစ်တာနဲ့ `_syncSession` က `GuestBudget.clear()` လုပ်တယ် | `home_page.dart` | Guest ရဲ့ budget/plan ပျောက်တယ်၊ account ထဲ မရွှေ့ဘူး |
| 3 | **Profile update / password change UI မရှိ** | `home_page.dart` account dialog | User က နာမည်ပြင်/password ပြင် မလုပ်နိုင် |
| 4 | **Plan load error အမြဲ silent** | `_PlanSessionGateState._syncSession` | Food တစ်ခု catalog ထဲက ဖျက်ခံရရင် plan တစ်ခုလုံး မပေါ်၊ "No Meal Plan Yet" ပြနေမယ် |
| 5 | **Planner error message မျိုချ** | `auto_page.dart`, `manual_page.dart` | Backend ရဲ့ တိကျတဲ့ validation message မပေါ် |

### 6.2 အလယ်အလတ်

| # | ပြဿနာ | ရှင်းလင်းချက် |
|---|---|---|
| 6 | 401 ကို global မကိုင် | `ApiClient` မှာ interceptor မရှိ။ Token သက်တမ်းကုန်ရင် page တစ်ခုချင်း error ပြနေမယ်၊ login ကို auto မပို့ဘူး |
| 7 | Endpoint တွေ hardcode | `FoodRepository`/`MealPlanRepository`/`home_page` မှာ `'/foods'`, `'/budget'`, `'/plans'` လို string တွေ တိုက်ရိုက် |
| 8 | Repository interface မရှိ | `FoodRepository`/`MealPlanRepository` က concrete class ပဲ။ Mock လုပ်ရခက်တယ် |
| 9 | BLoC မရှိ | Foods/Plans/Budget က `setState` + callback + static notifier နဲ့ ရေးထား။ Feature ကြီးလာရင် state ရှုပ်မယ် |
| 10 | `HomePage` က `StatelessWidget` + static `ValueNotifier` | Backend state ပါ ထည့်ထားပြီးမို့ Stateful/BLoC ပြောင်းတာ ပိုသင့်တော် |
| 11 | Foods filter/search local | Catalog ကြီးလာရင် client မှာ အားလုံးဆွဲထားရ။ API ရဲ့ `category/search/sort` ကို မသုံးဘူး |
| 12 | Pagination loop က blocking | `_openFoods` က အားလုံးဆွဲပြီးမှ page ဖွင့်။ Catalog ကြီးရင် စောင့်ရ၊ loading UI မရှိ |
| 13 | Image path က backend field ကို တိုက်ရိုက် `Image.asset` | Seed က `assets/img/...` ဖြစ်လို့ အခု အလုပ်ဖြစ်ပေမယ့် URL ပြောင်းရင် ကျိုးမယ် |

### 6.3 သေးငယ် / နောက်ပိုင်း

| # | ပြဿနာ |
|---|---|
| 14 | `ApiEndpoints` ထဲမှာ foods/plans/budget/favorites မပါ |
| 15 | `GET /budget` 404 ကို debugPrint နဲ့ပဲ ကိုင်၊ user မသိ |
| 16 | `_saveBudgetToBackend` က date ကို client က ပို့၊ timezone ကွာရင် မတူနိုင် |
| 17 | Foods catalog မရရင် guest လည်း Foods page မဖွင့်နိုင် (local sample fallback မရှိ) |
| 18 | Favorites 409 ကို အထူးမကိုင် |
| 19 | Tests က auth bloc နဲ့ user model ပဲ ရှိ။ Repository/API tests မရှိ |
| 20 | Plan delete အတွက် repository method ရှိပြီးသား မသုံး (dead code) |
| 21 | `HomePage._savedTodayPlan` က static ဖြစ်လို့ widget test တွေ ရှုပ်နိုင် |
| 22 | Form validation တွေက client မှာပဲ၊ backend error details ကို field တစ်ခုချင်း မပြသေး |
| 23 | Reports/Expenses/History က "not implemented" snackbar ပဲ |
| 24 | Currency format က `GuestBudget.format` နဲ့ပဲ၊ architecture တစ်ခုတည်း မရှိ |

---

## 7. Checkpoints နှင့် Milestones

### 7.1 ပြီးသွားတဲ့ checkpoint များ

| CP | Milestone | သက်သေ | အခြေအနေ |
|---|---|---|---|
| CP0 | Backend PostgreSQL migration + API contract | smoke check 67 pass | ပြီး |
| CP1 | Composition root + ApiClient + token injection | `main.dart`, `api_client.dart` | ပြီး |
| CP2 | Auth vertical slice (register/login/restore/logout) | `AuthBloc` + `RemoteAuthRepository` | ပြီး |
| CP3 | Budget save | `PUT /budget` from Home | ပြီး |
| CP4 | Budget restore + account switch safety | `_PlanSessionGate` | ပြီး |
| CP5 | Foods catalog from API | `FoodRepository.getFoods` | ပြီး |
| CP6 | Favorites from API | `FoodRepository` + `FoodsPage` | ပြီး |
| CP7 | Plan save (auto + manual) | `MealPlanRepository.save` | ပြီး |
| CP8 | Plan restore on login/app restart | `getSavedPlan` + gate | ပြီး |
| CP9 | Guest mode local flow | `GuestBudget`, local planners | ပြီး |

### 7.2 ကျန်ရှိ checkpoint များ

| CP | Milestone | လိုအပ်တဲ့အလုပ် | ခန့်မှန်း |
|---|---|---|---|
| CP10 | Plan delete API | `onDelete` ထဲ `MealPlanRepository.delete(DateTime.now())` ခေါ်၊ 404 ကို success လို ကိုင် | ၁–၂ နာရီ |
| CP11 | Profile update + change password | Account dialog → form page → `AuthBloc` event → `updateProfile`/`changePassword` | ၄–၆ နာရီ |
| CP12 | Expenses page + API | `GET/POST/DELETE /expenses` + form + states | ၁ ရက် |
| CP13 | History page + API | `GET /history` + date range + summary | ၁ ရက် |
| CP14 | Reports page + API | `GET /reports` + chart + period switch | ၁–၂ ရက် |
| CP15 | Guest transfer | `POST /guest-transfer` + 409 conflict dialog + resolution | တစ်ဝက်ရက် |
| CP16 | Hardening | global 401, endpoint constants, error messages, loading states | ၁ ရက် |
| CP17 | Testing | repository tests, widget tests, integration test | ၁–၂ ရက် |

### 7.3 Milestone အလိုက် ပြီးစီးမှု

```text
M1 Backend ready                 ████████████████████ 100%
M2 Auth usable end-to-end        ████████████████████ 100%
M3 Budget + Foods + Favorites    ████████████████████ 100%
M4 Plan save + load              ███████████████████░  90%
M5 Plan delete + Profile         ██░░░░░░░░░░░░░░░░░░  10%
M6 Expenses + History + Reports  ░░░░░░░░░░░░░░░░░░░░   0%
M7 Guest transfer                ░░░░░░░░░░░░░░░░░░░░   0%
M8 Hardening + Tests             ████░░░░░░░░░░░░░░░░  20%
```

**အကြမ်းဖျင်း project progress: ≈ 60%**  
(Backend 100%, UI 69%, client integration ~59%, tests 20% တို့ကို ပျမ်းမျှချ)

---

## 8. နောက်ထပ် လုပ်သင့်တဲ့ အစီအစဉ်

### အဆင့် 1 — Plan delete ကို အရင်ပြီးအောင် (အမြန်ဆုံး၊ အကျိုးအရှိဆုံး)

```dart
// home_page.dart
onDelete: () async {
  if (context.read<AuthBloc>().state.isAuthenticated) {
    await MealPlanRepository(context.read<ApiClient>())
        .delete(DateTime.now());
  }
  _savedTodayPlan.value = null;
},
```

ပြီးရင် —

- 404 ကို "plan မရှိ" အဖြစ် ကိုင်
- error ရရင် snackbar ပြ၊ local state မဖျက်
- delete ပြီးရင် My Plan က Home ကို ပြန်

### အဆင့် 2 — Plan load error ကို user သိနိုင်အောင်

```dart
if (error is ApiException && error.statusCode == 404) {
  HomePage._savedTodayPlan.value = null; // empty state
} else {
  _planLoadError.value = 'Could not load your plan.';
}
```

ဒါမှ "No Meal Plan Yet" နဲ့ "Load failed" ကို ခွဲပြနိုင်မယ်။

### အဆင့် 3 — Profile + Password

- `AccountPage` အသစ်
- `AuthProfileUpdateRequested`, `AuthPasswordChangeRequested` event
- success ရင် `AuthState.user` update
- validation error ကို `ApiException.details` နဲ့ field အောက်မှာ ပြ

### အဆင့် 4 — Expenses (History/Reports အတွက် အခြေခံ)

Expenses ကို အရင်ချိတ်ရမယ်။ မဟုတ်ရင် History/Reports မှာ data မရှိဘူး။

```text
ExpensesPage
  ├── GET /expenses?date=...
  ├── POST /expenses  (နေ့တစ်ခုလုံး replace)
  └── DELETE /expenses?date=...
```

### အဆင့် 5 — History နှင့် Reports

- History: from/to date range၊ day list၊ summary
- Reports: `period=daily|weekly|monthly`၊ chart
- 404/empty state ကို error မဟုတ်ဘဲ empty အဖြစ် ကိုင်

### အဆင့် 6 — Guest Transfer

Login/signup အောင်မြင်တာနဲ့ guest budget/plan ရှိမရှိ စစ်၊ ရှိရင် `POST /guest-transfer`။

- 409 ရရင် conflict dialog
- `resolution`: `replace-with-guest` သို့မဟုတ် `keep-account`
- ပြီးမှ local guest state ကို ရှင်း

### အဆင့် 7 — Hardening

- `ApiClient` မှာ 401 interceptor → token ဖျက် → `AuthLogoutRequested`
- endpoint အားလုံးကို `ApiEndpoints` ထဲ ရွှေ့
- repository interface တွေ ထုတ်၊ `main.dart` မှာ provider လုပ်
- loading / error / empty state သုံးမျိုး စံနှုန်းချ
- repository unit tests + widget tests

---

## 9. Acceptance Checklist (လက်ရှိ အလုပ်လုပ်ကြောင်း စစ်ရန်)

### Auth

- [ ] Register အသစ် → Home ရောက်၊ token သိမ်း
- [ ] Logout → token ဖျက်၊ Guest banner ပြန်
- [ ] App ပိတ်ပြီး ပြန်ဖွင့် → session ပြန်၊ user name ပြ
- [ ] မှားတဲ့ password → error banner ပြ၊ button ပြန် enable

### Budget

- [ ] Guest budget သိမ်း → Home မှာ ပြ
- [ ] Logged-in budget သိမ်း → server ရောက်
- [ ] App ပြန်ဖွင့် → budget ပြန်
- [ ] Account လဲ → အရင် account budget မပြ

### Foods + Favorites

- [ ] Foods page ဖွင့် → backend catalog ပြ
- [ ] Search/category → local filter မှန်
- [ ] Logged-in favorite → server သိမ်း၊ ပြန်ဖွင့်ရင် ပြန်
- [ ] Guest favorite → login dialog
- [ ] Favorite ဖျက် → server ဖျက်

### Plan

- [ ] Budget မရှိဘဲ plan သိမ်း → 422 error (လက်ရှိ generic message)
- [ ] Auto plan သိမ်း → server ရောက်၊ Home မှာ ပြ
- [ ] Manual plan သိမ်း (budget ကျော်) → server သိမ်း၊ overBudget warning
- [ ] App ပြန်ဖွင့် → plan ပြန်
- [ ] My Plan → Delete → **server ကပါ ဖျက်ရမယ် (လက်ရှိ မဖြစ်)**

### Guest

- [ ] Guest budget + plan သိမ်း → app ပိတ်ရင် ပျောက်
- [ ] Guest က Foods → catalog ပြ
- [ ] Guest → Login → guest data transfer (လက်ရှိ မရှိ)

---

## 10. Endpoint ↔ Code Map (အမြန်ရှာဖွေရန်)

| Endpoint | Repository / Code | UI ခေါ်တဲ့နေရာ |
|---|---|---|
| `POST /auth/register` | `RemoteAuthRepository.register` | `SignUpPage` → `AuthRegisterRequested` |
| `POST /auth/login` | `RemoteAuthRepository.login` | `LoginPage` → `AuthLoginRequested` |
| `GET /auth/me` | `RemoteAuthRepository.restoreSession` | `AuthStarted` |
| `POST /auth/logout` | `RemoteAuthRepository.logout` | Account dialog → `AuthLogoutRequested` |
| `PATCH /users/me` | `RemoteAuthRepository.updateProfile` | မရှိ |
| `PATCH /users/me/password` | `RemoteAuthRepository.changePassword` | မရှိ |
| `GET /foods` | `FoodRepository.getFoods` | `HomePage._openFoods`, planner |
| `GET /favorites` | `FoodRepository.getFavoriteIds` | `HomePage._openFoods` |
| `POST /favorites` | `FoodRepository.setFavorite` | `FoodsPage._toggleFavorite` |
| `DELETE /favorites/:foodId` | `FoodRepository.setFavorite` | `FoodsPage._toggleFavorite` |
| `GET /budget` | `home_page.dart` တိုက်ရိုက် | `_PlanSessionGateState._syncSession` |
| `PUT /budget` | `home_page.dart` တိုက်ရိုက် | `openBudget`, `_startPlan` |
| `POST /plans` | `MealPlanRepository.save` | `HomePage._savePlan` |
| `GET /plans` | `MealPlanRepository.getSavedPlan` | `_PlanSessionGateState._syncSession` |
| `DELETE /plans` | `MealPlanRepository.delete` | မရှိ (dead code) |
| `GET /expenses` | မရှိ | မရှိ |
| `POST /expenses` | မရှိ | မရှိ |
| `DELETE /expenses` | မရှိ | မရှိ |
| `GET /history` | မရှိ | မရှိ |
| `GET /reports` | မရှိ | မရှိ |
| `POST /guest-transfer` | မရှိ | မရှိ |

---

## 11. နိဂုံး

လက်ရှိ MealMate က **"backend အပြည့်အစုံ + Flutter အခြေခံလမ်းကြောင်း အလုပ်လုပ်နေပြီ"** အဆင့်မှာ ရှိပါတယ်။

အပြည့်အစုံ အလုပ်လုပ်နေတာ —

- Register / Login / Session restore / Logout
- Budget save + restore
- Foods catalog (UUID, pagination)
- Favorites
- Auto/Manual plan save + restore

ချက်ချင်း ပြင်သင့်တာ —

1. **Plan delete ကို API ချိတ်** (လက်ရှိ local only — အမှန်တကယ် bug)
2. **Plan load error ကို user သိနိုင်အောင်** ပြ
3. **Guest data transfer** ထည့် (မဟုတ်ရင် login လုပ်တာနဲ့ guest data ပျောက်)

ပြီးရင် Expenses → History → Reports → Profile → Hardening အစီအစဉ်နဲ့ ဆက်သွားရင် dependency မရှုပ်ဘဲ တစ်ဆင့်ချင်း အလုပ်လုပ်တဲ့ feature တွေ ရလာမယ်။

---

*ဒီ report ကို `lib/` နှင့် `backend/` ရဲ့ လက်ရှိ code မှ တိုက်ရိုက်ဖတ်ပြီး ပြင်ဆင်ထားပါတယ်။ Code ပြောင်းတာနဲ့ အခြေအနေ ပြောင်းနိုင်ပါတယ်။*
