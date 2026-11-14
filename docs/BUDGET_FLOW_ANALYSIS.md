# MealMate — Budget အပိုင်း လုံးဝ ခွဲခြမ်းစိတ်ဖြာချက်

> ဒီ document က **Budget feature တစ်ခုတည်း** ကို အာရုံစိုက်ပြီး ရေးထားပါတယ်။  
> ဘယ် class တွေ ပါလဲ၊ ဘယ် function တွေ ဘယ်လို အလုပ်လုပ်လဲ၊ ဘယ်သူက ဘယ်သူ့ကို ခေါ်လဲ၊ ဘယ် state က ဘယ်လို ပြောင်းလဲလဲ၊ backend နဲ့ ဘယ်လို ချိတ်ထားလဲ ဆိုတာကို အစအဆုံး ဖတ်နိုင်အောင် စီစဉ်ထားပါတယ်။

**ရက်စွဲ:** 2026-11-13  
**သက်ဆိုင်တဲ့ ဖိုင်များ:**

- `lib/ui/home_page.dart`
- `lib/ui/set_budget.dart`
- `lib/ui/budget_save.dart`
- `lib/ui/guest_budget.dart`
- `lib/services/api_client.dart`
- `lib/logic/auth/auth_bloc.dart` (သွယ်ဝိုက်သာ)
- `backend/routes/budgetRoutes.js`
- `backend/controllers/budgetController.js`
- `backend/models/DailyBudget.js`
- `backend/middleware/validate.js`
- `backend/utils/dates.js`
- `backend/utils/constants.js`

---

## 1. Budget ဆိုတာ ဒီ project မှာ ဘာလဲ

Budget က **"တစ်နေ့စာ အစားအသောက် သုံးငွေ ကန့်သတ်ချက်"** ဖြစ်ပါတယ်။

| အချက် | သတ်မှတ်ချက် |
|---|---|
| ယူနစ် | တစ်နေ့တစ်ခု (one budget per day) |
| ငွေ | ကျပ် ကိန်းပြည့် (whole MMK integer) |
| အနည်းဆုံး | 1 MMK |
| အများဆုံး | 10,000,000 MMK (backend) |
| သိမ်းပုံ | Guest ဆို memory၊ Logged-in ဆို PostgreSQL |
| သက်ရောက်မှု | Meal plan ရဲ့ budget limit ဖြစ်တယ် |
| မလုပ်တာ | Budget သိမ်းတာ expense မဖန်တီးဘူး၊ plan ကို မဖျက်ဘူး |

အရေးကြီးဆုံး သဘောတရား —

```text
Budget သတ်မှတ်တာ = "ဒီနေ့ ဘယ်လောက်သုံးမယ်" ကြိုတင်စီမံခြင်း
Expense မှတ်တမ်း = "အမှန်တကယ် ဘယ်လောက်သုံးခဲ့" မှတ်ခြင်း
```

ဒီနှစ်ခုက မတူပါဘူး။ ဒါကြောင့် budget သိမ်းတာက expense record မဖန်တီးပါဘူး။

---

## 2. ခြုံငုံ Flow မြေပုံ

Budget ထဲ ဝင်နိုင်တဲ့ လမ်းကြောင်း **၄ ခု** ရှိပါတယ်။

```text
┌─────────────────────────────────────────────────────────────┐
│ A. Home → "Set Daily Budget" / Edit icon                    │
│    HomePage.openBudget()                                    │
│      → SetBudgetPage                                         │
│      → onSave = saveBudget()                                 │
│      → BudgetSavePage (confirmation)                        │
│      → Edit / Automatic / Manual / Back Home                │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ B. Planner ဝင်ချိန် budget မရှိသေးလျှင်                       │
│    HomePage._startPlan()                                     │
│      → SetBudgetPage (confirmation page မပါ)                 │
│      → budget ရမှ _openPlanner()                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ C. BudgetSavePage မှ "Edit Budget"                           │
│    BudgetSavePage._edit()                                    │
│      → SetBudgetPage(initialBudget: _budget)                 │
│      → onSave = onBudgetChanged                              │
│      → pop(updated) → _budget update                        │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ D. App ပြန်ဖွင့် / Login ဖြစ်ချိန်                            │
│    _PlanSessionGateState._syncSession()                      │
│      → GET /budget?date=YYYY-MM-DD                           │
│      → GuestBudget.save(amount)                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Path A — Home မှ Budget သတ်မှတ်ခြင်း (အဓိကလမ်းကြောင်း)

### 3.1 စတင်တဲ့နေရာ — `_budgetCard()`

`home_page.dart` ရဲ့ `_budgetCard(BuildContext context)` က budget card ကို ဆောက်တယ်။

```dart
ValueListenableBuilder<int?>(
  valueListenable: GuestBudget.dailyBudget,
  builder: (context, amount, _) {
    final hasBudget = amount != null;
    ...
  },
)
```

ဒီ card မှာ —

- Budget မရှိရင် **"Set your budget"** နှင့် **"Set Daily Budget"** button
- Budget ရှိရင် **"{amount} MMK"** နှင့် **Edit** icon
- နှစ်မျိုးလုံး `openBudget(context)` ကို ခေါ်

```dart
onPressed: () => openBudget(context)
```

`ValueListenableBuilder` က `GuestBudget.dailyBudget` ကို စောင့်ကြည့်တာမို့ budget ပြောင်းတာနဲ့ card အလိုအလျောက် ပြန်ဆွဲတယ်။

### 3.2 `HomePage.openBudget()`

```dart
Future<void> openBudget(BuildContext context) async {
  final isLoggedIn = context.read<AuthBloc>().state.isAuthenticated;

  Future<bool> saveBudget(int amount) async {
    try {
      if (isLoggedIn) {
        await _saveBudgetToBackend(context, amount);
      }
      GuestBudget.save(amount);
      return true;
    } catch (error, stackTrace) {
      debugPrint('BUDGET SAVE ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  await Navigator.of(context).push<int>(
    MaterialPageRoute<int>(
      builder: (context) => SetBudgetPage(
        initialBudget: GuestBudget.amount,
        onSave: saveBudget,
        confirmationPageBuilder: (amount) => BudgetSavePage(
          budget: amount,
          onBudgetChanged: saveBudget,
          automaticPageBuilder: (context) => _plannerPage(
            context, 'Automatic', GuestBudget.amount ?? amount,
          ),
          manualPageBuilder: (context) =>
              _plannerPage(context, 'Manual', GuestBudget.amount ?? amount),
        ),
      ),
    ),
  );
}
```

ဒီ function မှာ အပိုင်း ၃ ပိုင်း ရှိတယ်။

| အပိုင်း | လုပ်ဆောင်ချက် |
|---|---|
| 1 | လက်ရှိ user logged-in လား စစ် |
| 2 | `saveBudget()` closure ဆောက် — backend သိမ်း + `GuestBudget` update |
| 3 | `SetBudgetPage` ကို push၊ confirmation page builder ပေး |

**အရေးကြီးချက်:** `saveBudget` က `Future<bool>` ပြန်တယ်။ အောင်မြင်ရင် `true`၊ မအောင်မြင်ရင် `false`။ ဒါပေမယ့် error ကို ဖမ်းပြီး **user ကို ဘာမှ မပြ**ဘဲ `false` ပြန်တယ်။ ဒါက အောက်ပိုင်း အားနည်းချက်မှာ ထပ်ရှင်းပါမယ်။

### 3.3 `_saveBudgetToBackend()`

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

ဒီမှာ —

- `context.read<ApiClient>()` နဲ့ app-wide Dio wrapper ကို ယူ
- `PUT /budget` ကို တိုက်ရိုက်ခေါ်
- `date` ကို `_todayDate()` နဲ့ `YYYY-MM-DD` ပို့
- response ရဲ့ `success` ကို စစ်
- `ApiClient` က envelope တစ်ခုလုံး ပြန်တာမို့ `response['success']` ကို စစ်ရတယ်

`_todayDate()` —

```dart
String _todayDate() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}
```

### 3.4 `SetBudgetPage` — input ယူတဲ့ screen

`SetBudgetPage` က **StatefulWidget** ဖြစ်တယ်။ Field ၃ ခု ရှိတယ်။

```dart
class SetBudgetPage extends StatefulWidget {
  final int? initialBudget;
  final Future<bool> Function(int amount)? onSave;
  final Widget Function(int amount)? confirmationPageBuilder;
  ...
}
```

| Field | အသုံး |
|---|---|
| `initialBudget` | Edit လုပ်တဲ့အခါ ရှိပြီးသား budget ကို ပြရန် |
| `onSave` | Save နှိပ်ရင် ခေါ်မယ့် async callback |
| `confirmationPageBuilder` | ရှိရင် confirmation page ကို ဆောက်၊ မရှိရင် pop |

State ထဲမှာ —

```dart
late final TextEditingController _controller;
final _formKey = GlobalKey<FormState>();
bool _isSaving = false;
```

`initState()` က `initialBudget` ကို comma format နဲ့ controller ထဲ ထည့်တယ်။

```dart
_controller = TextEditingController(
  text: widget.initialBudget == null ? '' : _format(widget.initialBudget!),
);
```

### 3.5 Input ဖတ်ပုံ

```dart
int? get _amount =>
    int.tryParse(_controller.text.replaceAll(',', '').trim());
```

- Comma တွေ ဖျက်
- Space ဖျက်
- `int.tryParse` နဲ့ ကိန်းပြည့် ဖတ်
- မရရင် `null`

Input field မှာ —

```dart
keyboardType: TextInputType.number,
inputFormatters: [FilteringTextInputFormatter.digitsOnly],
```

ဒါကြောင့် စာလုံး ရိုက်လို့ မရဘူး၊ ဂဏန်းပဲ ရိုက်နိုင်တယ်။

Quick Amount chip နှိပ်ရင် —

```dart
void _selectAmount(int amount) {
  setState(() => _controller.text = _format(amount));
  _formKey.currentState?.validate();
}
```

`quickAmounts` က `[5000, 10000, 15000, 20000]`။

### 3.6 Validation

```dart
validator: (value) {
  final amount = int.tryParse(
    (value ?? '').replaceAll(',', '').trim(),
  );
  if (amount == null || amount <= 0) {
    return 'Enter a budget greater than 0 MMK';
  }
  return null;
},
```

Client က **0 ထက် ကြီးရမယ်** ဆိုတာပဲ စစ်တယ်။ **အများဆုံး 10,000,000** ကို မစစ်ဘူး။

### 3.7 `_save()` — အဓိကလုပ်ဆောင်ချက်

```dart
Future<void> _save() async {
  if (_isSaving) return;
  if (!_formKey.currentState!.validate()) return;

  final amount = _amount;
  if (amount == null) return;

  if (widget.onSave != null) {
    setState(() => _isSaving = true);

    try {
      final success = await widget.onSave!(amount);
      if (!mounted || !success) return;
    } catch (error) {
      ...
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save budget. Please try again.'),
        ),
      );
      return;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  if (!mounted) return;

  if (widget.confirmationPageBuilder != null) {
    Navigator.of(context).pushReplacement<void, int>(
      MaterialPageRoute<void>(
        builder: (_) => widget.confirmationPageBuilder!(amount),
      ),
      result: amount,
    );
  } else {
    Navigator.of(context).pop(amount);
  }
}
```

အဆင့်လိုက် ရှင်းချက် —

| လုပ်ဆောင်ချက် | ရည်ရွယ်ချက် |
|---|---|
| `_isSaving` စစ် | double tap ကာကွယ် |
| `validate()` | form error ပြ |
| `_amount` ဖတ် | null ဆို ရပ် |
| `onSave` ရှိရင် ခေါ် | backend + GuestBudget သိမ်း |
| `success == false` | ဘာမှ မလုပ်၊ page မှာ ဆက်နေ |
| `catch` | generic snackbar ပြ |
| `confirmationPageBuilder != null` | `pushReplacement` နဲ့ confirmation ကို အစားထိုး |
| မရှိရင် | `pop(amount)` နဲ့ caller ကို ပြန် |

### 3.8 `pushReplacement` ရဲ့ အလုပ်လုပ်ပုံ

```dart
Navigator.of(context).pushReplacement<void, int>(
  MaterialPageRoute<void>(builder: (_) => BudgetSavePage(...)),
  result: amount,
);
```

ဒီနေရာမှာ —

- `SetBudgetPage` route ကို stack ကနေ ဖျက်
- `BudgetSavePage` ကို အပေါ်တင်တယ်
- ဖျက်လိုက်တဲ့ route ရဲ့ future ကို `amount` နဲ့ ပြီးစေတယ်

ဒါကြောင့် `openBudget()` ထဲက `await Navigator.push<int>(...)` က `amount` နဲ့ ချက်ချင်း ပြီးသွားတယ်။ ဒါပေမယ့် `openBudget()` က အဲဒီ result ကို မသုံးဘူး။ ဘာကြောင့်လဲဆိုတော့ UI က `GuestBudget.dailyBudget` ကို စောင့်ကြည့်ထားလို့ပါ။

### 3.9 `BudgetSavePage` — အတည်ပြု screen

```dart
class BudgetSavePage extends StatefulWidget {
  final int budget;
  final WidgetBuilder? automaticPageBuilder;
  final WidgetBuilder? manualPageBuilder;
  final Future<bool> Function(int amount)? onBudgetChanged;
  ...
}
```

| Field | အသုံး |
|---|---|
| `budget` | သိမ်းပြီးသား ပမာဏ |
| `automaticPageBuilder` | Auto planner ကို ဖွင့်ရန် |
| `manualPageBuilder` | Manual planner ကို ဖွင့်ရန် |
| `onBudgetChanged` | Edit လုပ်တဲ့အခါ ပြန်သိမ်းရန် callback |

State —

```dart
late int _budget;
```

`initState()` မှာ `_budget = widget.budget` လုပ်တယ်။

ပြသတဲ့ အပိုင်း —

```text
✓ Budget Save!
Your daily budget is
{amount} Ks
[ Edit Budget ]
What would you like to do next?
[ Automatic Meal Plan ]
[ Manual Meal Plan ]
[ Back to Home ]
```

### 3.10 `_edit()` — ရှိပြီးသား budget ပြင်

```dart
Future<void> _edit() async {
  final updated = await Navigator.of(context).push<int>(
    MaterialPageRoute(
      builder: (context) => SetBudgetPage(
        initialBudget: _budget,
        onSave: widget.onBudgetChanged,
      ),
    ),
  );

  if (!mounted || updated == null) return;

  if (widget.onBudgetChanged == null) {
    GuestBudget.save(updated);
  }

  setState(() {
    _budget = updated;
  });
}
```

ဒီမှာ —

- `initialBudget` ကို ပေးလိုက်တာမို့ input မှာ ရှိပြီးသား ပမာဏ ပြ
- `onSave` ကို `onBudgetChanged` ပေး
- ပြင်ပြီး pop ပြန်ရင် `_budget` update
- `onBudgetChanged == null` ဆိုမှ `GuestBudget.save` (fallback)
- `onBudgetChanged` ရှိရင် အဲဒီ callback ထဲမှာ `GuestBudget.save` ပါပြီးသား

### 3.11 `_home()` — Home ပြန်

```dart
void _home() => Navigator.of(context).pop(_budget);
```

`BudgetSavePage` ကို ဖွင့်ထားတဲ့သူက `await push<int>` မလုပ်ထားလို့ ဒီ result ကို ဘယ်သူမှ မယူဘူး။ ဒါပေမယ့် `GuestBudget.dailyBudget` က ပြောင်းထားပြီးသားမို့ Home card က မှန်ကန်တဲ့ ပမာဏ ပြနေတယ်။

### 3.12 `PopScope` — Android back button

```dart
PopScope<int>(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (!didPop) _home();
  },
  child: ...
)
```

- Back button နှိပ်ရင် ဒီ page ကို ဖျက်မယ့်အစား `_home()` ခေါ်
- `_budget` ကို result အနေနဲ့ ပြန်
- Home ကို ရောက်

### 3.13 Planner ကို ဆက်သွားခြင်း

```dart
void _openPlan(WidgetBuilder? builder, String planName) {
  if (builder == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$planName page is not connected yet.')),
    );
    return;
  }
  Navigator.of(context).push(MaterialPageRoute(builder: builder));
}
```

`BudgetSavePage` မှာ card နှိပ်ရင် `automaticPageBuilder` သို့မဟုတ် `manualPageBuilder` ကို ခေါ်။

Home က ပေးထားတဲ့ builder —

```dart
automaticPageBuilder: (context) => _plannerPage(
  context, 'Automatic', GuestBudget.amount ?? amount,
),
```

ဒါကြောင့် confirmation page ကနေ တိုက်ရိုက် planner ထဲ ဝင်နိုင်တယ်။

---

## 4. Path B — Planner ဝင်ချိန် Budget မရှိသေးလျှင်

`HomePage._startPlan()` က planner မဝင်ခင် budget ရှိမရှိ စစ်တယ်။

```dart
var budget = GuestBudget.amount;
if (budget == null) {
  final isLoggedIn = context.read<AuthBloc>().state.isAuthenticated;
  final api = context.read<ApiClient>();

  budget = await Navigator.of(context).push<int>(
    MaterialPageRoute<int>(
      builder: (_) => SetBudgetPage(
        onSave: (amount) async {
          if (isLoggedIn) {
            final response = await api.put(
              '/budget',
              data: {'date': _todayDate(), 'amount': amount},
            );
            if (response['success'] != true) {
              throw StateError('Budget could not be saved.');
            }
          }
          GuestBudget.save(amount);
          return true;
        },
      ),
    ),
  );

  if (!context.mounted || budget == null) return;
}

if (!context.mounted) return;
_openPlanner(context, method, budget);
```

ဒီလမ်းကြောင်းမှာ —

- `confirmationPageBuilder` မပါ
- Save အောင်မြင်ရင် `SetBudgetPage` က `pop(amount)`
- `_startPlan` က `budget` ကို လက်ခံ
- ပြီးမှ `_openPlanner(context, method, budget)` ခေါ်
- `BudgetSavePage` မပြ

Error ဖြစ်ရင် `onSave` က throw လုပ်တယ်၊ `SetBudgetPage._save()` က ဖမ်းပြီး generic snackbar ပြတယ်။ ဒီလမ်းကြောင်းမှာတော့ error ကို user သိတယ် (Path A နဲ့ မတူဘူး)။

---

## 5. Path C — BudgetSavePage မှ Edit

ဒီလမ်းကြောင်းကို အပေါ် 3.10 မှာ ရှင်းပြီးပါပြီ။ အနှစ်ချုပ်က —

```text
BudgetSavePage (_budget = 15000)
  → Edit Budget
  → SetBudgetPage(initialBudget: 15000, onSave: saveBudget)
  → user က 20000 ရိုက်
  → Save
  → onSave(20000) → PUT /budget + GuestBudget.save(20000)
  → pop(20000)
  → BudgetSavePage._budget = 20000
  → UI မှာ 20,000 Ks ပြ
```

---

## 6. Path D — Login / App ပြန်ဖွင့်ချိန် Budget ပြန်ဖတ်ခြင်း

`HomePage` ကို `_PlanSessionGate` က ဖုံးထားတယ်။

```text
HomePage.build()
  └── _PlanSessionGate
        ├── initState → postFrame → _syncSession(authState)
        ├── BlocListener<AuthBloc>
        └── child: HomePage UI
```

### 6.1 `_syncSession()` ရဲ့ budget အပိုင်း

```dart
if (account == null) {
  _loadedAccount = null;
  GuestBudget.clear();
  return;
}

if (_loadedAccount != account) {
  HomePage._savedTodayPlan.value = null;
  HomePage._myPlanSelected.value = false;
  GuestBudget.clear();
}

_loadedAccount = account;

try {
  final api = context.read<ApiClient>();

  try {
    final response = await api.get(
      '/budget',
      queryParameters: {'date': _todayDateForSession()},
    );

    if (!mounted || request != _requestVersion) return;
    if (_accountKey(context.read<AuthBloc>().state) != account) return;

    final data = response['data'];
    final budget = data is Map ? data['budget'] : null;
    final amount = budget is Map ? budget['amount'] : null;

    if (amount is num && amount > 0) {
      GuestBudget.save(amount.toInt());
    } else if (amount is String) {
      final parsed = int.tryParse(amount);
      if (parsed != null && parsed > 0) GuestBudget.save(parsed);
    }
  } catch (error, stackTrace) {
    debugPrint('BUDGET GET ERROR (404 means no budget yet): $error');
    debugPrintStack(stackTrace: stackTrace);
  }
  ...
}
```

### 6.2 အဆင့်လိုက်

| အဆင့် | လုပ်ဆောင်ချက် | ရလဒ် |
|---|---|---|
| 1 | `account == null` စစ် | Guest ဆို budget ရှင်း |
| 2 | Account အသစ် စစ် | Plan/budget အဟောင်း မပြ |
| 3 | `GET /budget?date=...` | ဒီနေ့ budget ဆွဲ |
| 4 | `data.budget.amount` ဖတ် | num သို့မဟုတ် String |
| 5 | `GuestBudget.save()` | UI card update |
| 6 | Error ဖြစ်ရင် | debugPrint ပဲ |

### 6.3 404 ရဲ့ အဓိပ္ပာယ်

Backend က budget မရှိရင် `404` ပြန်တယ်။

```json
{
  "success": false,
  "message": "No daily budget set for 2026-11-13."
}
```

ဒါက **error မဟုတ်ဘူး**။ "ဒီနေ့ budget မသတ်မှတ်ရသေးဘူး" ဆိုတဲ့ empty state ပါ။ ဒါပေမယ့် လက်ရှိ code က `catch` ထဲ ဝင်ပြီး `debugPrintStack` နဲ့ log လုပ်တယ်။ User ကို error မပြဘူး (ကောင်းတယ်)၊ ဒါပေမယ့် console မှာ stack trace ထွက်နေတယ်။

### 6.4 Account လဲချိန်

```dart
if (_loadedAccount != account) {
  HomePage._savedTodayPlan.value = null;
  HomePage._myPlanSelected.value = false;
  GuestBudget.clear();
}
```

ဒါက အကောင့် A ရဲ့ budget ကို အကောင့် B မှာ မပြစေရန် ကာကွယ်တယ်။

### 6.5 Logout ချိန်

`_onAuthChanged()` က `newAccount == null` ဖြစ်ရင် —

```dart
++_requestVersion;
_loadedAccount = null;
HomePage._savedTodayPlan.value = null;
HomePage._myPlanSelected.value = false;
GuestBudget.clear();
```

ဒါကြောင့် logout လုပ်တာနဲ့ budget card က "Set your budget" ပြန်ဖြစ်တယ်။

---

## 7. Guest နှင့် Logged-in ကွာခြားချက်

| အချက် | Guest | Logged-in |
|---|---|---|
| Save လုပ်တဲ့နေရာ | `GuestBudget` memory | PostgreSQL `daily_budgets` |
| API ခေါ်? | မခေါ် | `PUT /budget` |
| App ပိတ်ရင် | ပျောက် | ကျန် |
| App ပြန်ဖွင့်ရင် | မရ | `GET /budget` နဲ့ ပြန် |
| Account လဲရင် | — | ရှင်းပြီး အသစ်ဆွဲ |
| Plan save | Local notifier | `POST /plans` ကို budget နဲ့ စစ် |

---

## 8. Class နှင့် Function Reference

### 8.1 `HomePage` (budget သက်ဆိုင်ရာ)

| Member | Signature | တာဝန် | ခေါ်တဲ့နေရာ |
|---|---|---|---|
| `_todayDate` | `String _todayDate()` | ဒီနေ့ကို `YYYY-MM-DD` ပြောင် | `_saveBudgetToBackend`, `_startPlan` |
| `_saveBudgetToBackend` | `Future<void> (BuildContext, int)` | `PUT /budget` | `openBudget`, `_startPlan` |
| `openBudget` | `Future<void> (BuildContext)` | Budget screen ဖွင့် | `_budgetCard` |
| `_startPlan` | `Future<void> (BuildContext, String)` | Budget မရှိရင် အရင်မေး | Home cards |
| `_budgetCard` | `Widget (BuildContext)` | Budget UI ဆောက် | `_content` |
| `_plannerPage` | `Widget (BuildContext, String, int)` | Planner + catalog | `openBudget`, `_startPlan` |
| `_PlanSessionGate` | Widget | Session sync | `HomePage.build` |
| `_syncSession` | `Future<void> (AuthState)` | Budget/plan restore | `initState`, auth listener |
| `_onAuthChanged` | `void (AuthState)` | Login/logout ကို တုံ့ပြန် | `BlocListener` |

### 8.2 `SetBudgetPage`

| Member | Signature | တာဝန် |
|---|---|---|
| `initialBudget` | `int?` | ရှိပြီးသား budget |
| `onSave` | `Future<bool> Function(int)?` | Save callback |
| `confirmationPageBuilder` | `Widget Function(int)?` | အတည်ပြု page builder |
| `_controller` | `TextEditingController` | Input |
| `_formKey` | `GlobalKey<FormState>` | Form validation |
| `_isSaving` | `bool` | Save နေဆဲ |
| `_format` | `static String (int)` | Comma ထည့် |
| `_amount` | `int? get` | Input ကို ဖတ် |
| `_selectAmount` | `void (int)` | Quick chip |
| `_save` | `Future<void> ()` | Save + navigation |
| `validator` | `String? (String?)` | > 0 စစ် |

### 8.3 `BudgetSavePage`

| Member | Signature | တာဝန် |
|---|---|---|
| `budget` | `int` | သိမ်းပြီး ပမာဏ |
| `automaticPageBuilder` | `WidgetBuilder?` | Auto planner |
| `manualPageBuilder` | `WidgetBuilder?` | Manual planner |
| `onBudgetChanged` | `Future<bool> Function(int)?` | Edit save callback |
| `_budget` | `int` | လက်ရှိ ပြသ ပမာဏ |
| `_money` | `String (int)` | Comma format |
| `_edit` | `Future<void> ()` | Budget ပြင် |
| `_home` | `void ()` | Home ပြန် |
| `_openPlan` | `void (WidgetBuilder?, String)` | Planner ဖွင့် |
| `_planCard` | `Widget (...)` | Plan card |

### 8.4 `GuestBudget`

| Member | Type | တာဝန် |
|---|---|---|
| `dailyBudget` | `ValueNotifier<int?>` | UI စောင့်ကြည့်တဲ့ တန်ဖိုး |
| `amount` | `int? get` | လက်ရှိ budget |
| `hasBudget` | `bool get` | ရှိ/မရှိ |
| `save` | `static void (int)` | သိမ်း (0 ထက် ကြီးရမယ်) |
| `clear` | `static void ()` | ရှင်း |
| `format` | `static String (int)` | Comma format |

`save()` က အောက်ပါအတိုင်း စစ်တယ်။

```dart
static void save(int amount) {
  if (amount <= 0) {
    throw ArgumentError.value(amount, 'amount', 'Budget must be positive');
  }
  dailyBudget.value = amount;
}
```

### 8.5 `ApiClient`

| Method | ဘာအတွက် |
|---|---|
| `put(path, data)` | `PUT /budget` |
| `get(path, queryParameters)` | `GET /budget` |

`ApiClient` က —

- Bearer token ထည့်
- `ApiException` ပြောင်
- Response body တစ်ခုလုံး ပြန်

### 8.6 Backend

| File | Function | တာဝန် |
|---|---|---|
| `budgetRoutes.js` | `router.get('/')` | `GET /api/budget` |
| `budgetRoutes.js` | `router.put('/')` | `PUT /api/budget` |
| `budgetController.js` | `getBudget` | 404 သို့မဟုတ် budget ပြန် |
| `budgetController.js` | `setBudget` | upsert + plan warning |
| `DailyBudget.js` | `findByUserAndDate` | user + date ရှာ |
| `DailyBudget.js` | `upsert` | insert သို့မဟုတ် update |
| `DailyBudget.js` | `toApiJSON` | row ကို JSON ပြောင် |
| `validate.js` | `requiredAmount` | 1 မှ 10,000,000 စစ် |
| `dates.js` | `todayInAppTimezone` | Asia/Yangon ဒီနေ့ |
| `dates.js` | `parseDateOnly` | `YYYY-MM-DD` စစ် |

---

## 9. Call Graph

```text
HomePage._budgetCard
  └── onPressed
        └── HomePage.openBudget(context)
              ├── AuthBloc.state.isAuthenticated
              ├── saveBudget(amount)                 [closure]
              │     ├── _saveBudgetToBackend(context, amount)
              │     │     ├── context.read<ApiClient>()
              │     │     ├── _todayDate()
              │     │     └── ApiClient.put('/budget', ...)
              │     └── GuestBudget.save(amount)
              └── Navigator.push(SetBudgetPage)
                    └── SetBudgetPage._save()
                          ├── Form.validate()
                          ├── _amount
                          ├── onSave(amount)
                          │     └── saveBudget(amount)
                          └── confirmationPageBuilder != null
                                ├── true  → pushReplacement(BudgetSavePage)
                                └── false → pop(amount)
```

Plan ဝင်တဲ့လမ်းကြောင်း —

```text
HomePage._startPlan
  ├── GuestBudget.amount == null
  │     └── Navigator.push(SetBudgetPage)
  │           └── onSave
  │                 ├── logged-in → PUT /budget
  │                 └── GuestBudget.save
  └── _openPlanner(context, method, budget)
        └── _plannerPage
              ├── guest → sampleFoodCatalog
              └── logged-in → FoodRepository.getFoods()
```

Restore လမ်းကြောင်း —

```text
_PlanSessionGate.initState
  └── _syncSession(AuthState)
        ├── account == null → GuestBudget.clear()
        ├── GET /budget?date=...
        ├── data.budget.amount
        └── GuestBudget.save(amount)
```

---

## 10. Reactive State — ဘယ်လို update ဖြစ်လဲ

```text
User input
   ↓
SetBudgetPage._save()
   ↓
GuestBudget.dailyBudget.value = amount
   ↓
ValueNotifier notifyListeners()
   ↓
HomePage._budgetCard ရဲ့ ValueListenableBuilder
   ↓
UI ပြန်ဆွဲ
```

`GuestBudget` က app-wide static ဖြစ်တာမို့ page တစ်ခုနဲ့ တစ်ခု အကြား prop drilling မလိုဘူး။ ဒါပေမယ့် static ဖြစ်တာက test လုပ်ရခက်တဲ့ အချက် ဖြစ်တယ်။

---

## 11. Backend Contract အသေးစိတ်

### 11.1 `PUT /api/budget`

Request —

```json
{
  "date": "2026-11-13",
  "amount": 15000
}
```

Headers —

```text
Authorization: Bearer <JWT>
Content-Type: application/json
```

Success —

```json
{
  "success": true,
  "data": {
    "budget": {
      "id": "uuid",
      "date": "2026-11-13",
      "amount": 15000,
      "createdAt": "...",
      "updatedAt": "..."
    },
    "plan": {
      "plannedTotal": 12000,
      "remaining": 3000,
      "overBudget": false
    }
  }
}
```

`plan` က ဒီနေ့ plan ရှိမှ ပါမယ်။

Error —

```json
{
  "success": false,
  "message": "Validation failed.",
  "details": [
    {
      "field": "amount",
      "message": "Amount must be a whole number between 1 and 10000000."
    }
  ]
}
```

### 11.2 `GET /api/budget?date=YYYY-MM-DD`

Success —

```json
{
  "success": true,
  "data": {
    "budget": {
      "id": "uuid",
      "date": "2026-11-13",
      "amount": 15000
    }
  }
}
```

Budget မရှိ —

```json
{
  "success": false,
  "message": "No daily budget set for 2026-11-13."
}
```

Status `404`။

### 11.3 SQL Upsert

```sql
INSERT INTO daily_budgets (id, user_id, budget_date, amount)
VALUES ($1, $2, $3, $4)
ON CONFLICT (user_id, budget_date)
DO UPDATE SET amount = EXCLUDED.amount, updated_at = now()
RETURNING id, budget_date, amount, created_at, updated_at;
```

ဒီ SQL က **တစ်နေ့ တစ်ခု** ဆိုတာကို database level မှာ အာမခံတယ်။

### 11.4 Business Rules

| Rule | ရလဒ် |
|---|---|
| Budget မရှိဘဲ plan သိမ်း | `422` |
| Auto plan budget ကျော် | `422` (မသိမ်း) |
| Manual plan budget ကျော် | သိမ်း၊ `overBudget: true` |
| Budget ပြင်ရင် plan ရှိ | Plan မဖျက်၊ warning ပြန် |
| Plan ဖျက်ရင် budget | Budget ကျန် |
| Budget သိမ်း | Expense မဖန်တီး |
| Future date | Budget အတွက် ခွင့်ပြု၊ plan အတွက် မခွင့်ပြု |

---

## 12. Budget နှင့် Plan ဆက်စပ်ပုံ

```text
Budget သတ်မှတ်
   ↓
Plan save လုပ်တဲ့အခါ backend က budget ရှိမရှိ စစ်
   ↓
မရှိ → 422 "Set a daily budget..."
   ↓
ရှိ → plan သိမ်း
   ↓
Auto plan → budget ကျော်ရင် ငြင်း
Manual plan → budget ကျော်လို့ရ၊ warning
```

Client မှာ —

```dart
var budget = GuestBudget.amount;
if (budget == null) {
  // SetBudgetPage ကို အရင်ခေါ်
}
_openPlanner(context, method, budget);
```

ဒါကြောင့် UI level မှာ budget မရှိဘဲ planner ထဲ မဝင်နိုင်ဘူး။ Backend ကလည်း ထပ်စစ်တယ် (defense in depth)။

---

## 13. Error နှင့် Edge Case Matrix

| အခြေအနေ | လက်ရှိ ဖြစ်တာ | ကောင်းမွန်မှု |
|---|---|---|
| Amount ဗလာ | Validator error | ကောင်း |
| Amount 0 သို့မဟုတ် အနုတ် | Validator error | ကောင်း |
| Amount 10,000,000 ကျော် | Client မစစ်၊ backend 422 | မကောင်း |
| Guest save | `GuestBudget.save` | ကောင်း |
| Logged-in save success | PUT + GuestBudget | ကောင်း |
| Logged-in save fail (Path A) | `false` ပြန်၊ UI ငြိမ် | **မကောင်း** |
| Logged-in save fail (Path B) | Snackbar ပြ | ကောင်း |
| GET 404 | debugPrint + stack | log ဆူ |
| GET server error | debugPrint + stack | User မသိ |
| Double tap save | `_isSaving` ကာကွယ် | ကောင်း |
| Edit cancel | `updated == null` ရပ် | ကောင်း |
| Back button | `PopScope` က Home ပို့ | ကောင်း |
| Account switch | Budget ရှင်း + ပြန်ဆွဲ | ကောင်း |
| App restart logged-in | GET နဲ့ ပြန် | ကောင်း |
| App restart guest | ပျောက် | ဒီဇိုင်းအရ မှန် |

---

## 14. အားနည်းချက်များ (Budget သီးသန့်)

### 14.1 အရေးကြီး

**1. Path A မှာ save fail ဖြစ်ရင် user ကို ဘာမှ မပြ**

```dart
} catch (error, stackTrace) {
  debugPrint('BUDGET SAVE ERROR: $error');
  debugPrintStack(stackTrace: stackTrace);
  return false;
}
```

`SetBudgetPage._save()` က `success == false` ဆို ငြိမ်ငြိမ်း return လုပ်တယ်။ ဒါကြောင့် network error သို့မဟုတ် 422 ဖြစ်ရင် user က button နှိပ်လိုက်ပေမယ့် ဘာမှ မဖြစ်သလို ခံစားရမယ်။

**2. Backend validation message မျိုချ**

Backend က "Amount must be a whole number between 1 and 10000000." လို တိကျတဲ့ message ပြန်ပေမယ့် client က generic snackbar သို့မဟုတ် ဘာမှ မပြဘူး။

**3. Maximum amount ကို client မစစ်**

`validator` က `amount <= 0` ပဲ စစ်တယ်။ 10,000,000 ကျော်ရင် server မှ ငြင်းမှ သိရတယ်။

### 14.2 အလယ်အလတ်

| # | ပြဿနာ | ရှင်းလင်းချက် |
|---|---|---|
| 4 | Error handling မတူ | Path A က false၊ Path B က throw၊ `_edit` က callback ပေါ်မူတည် |
| 5 | Direct API in UI | `HomePage` က `ApiClient` ကို တိုက်ရိုက်ခေါ်၊ repository/BLoC မဖြတ် |
| 6 | Hardcoded endpoint | `'/budget'` ကို `ApiEndpoints` မှာ မထည့် |
| 7 | Loading state မရှိ | Login ပြီး budget ပြန်ဆွဲချိန် card က "Set your budget" ပြနေတယ် |
| 8 | Timezone ကွာနိုင် | Client `DateTime.now()` က device timezone၊ backend က Asia/Yangon |
| 9 | Date ကို client ပို့ | Server default ကို မသုံးဘဲ client ရဲ့ ဒီနေ့ကို သုံး |
| 10 | 404 ကို error လို log | `debugPrintStack` နဲ့ မလိုအပ်ဘဲ stack ထုတ် |
| 11 | Static state | `GuestBudget` က global static၊ test isolate မလွယ် |
| 12 | Navigation quirk | `pushReplacement` ရဲ့ result ကို ဘယ်သူမှ မယူ |
| 13 | Edit ပြီး plan warning မပြ | Backend က `overBudget` ပြန်ပေမယ့် confirmation page မှာ မပြ |

### 14.3 သေးငယ်

| # | ပြဿနာ |
|---|---|
| 14 | `_format` ကို `SetBudgetPage`, `BudgetSavePage`, `GuestBudget` မှာ သုံးကြိမ် ပြန်ရေး |
| 15 | Amount ကို int ပဲ၊ decimal မပံ့ပိုး (ဒီဇိုင်းအရ မှန်) |
| 16 | Save နေဆဲ button ကို disable မလုပ်၊ `_isSaving` က guard ပဲ |
| 17 | Budget history မရှိ (တစ်နေ့ပဲ) |
| 18 | Offline retry mechanism မရှိ |

---

## 15. ပိုကောင်းအောင် ပြင်ဆင်နည်း

### 15.1 BudgetRepository ထုတ်ခြင်း

```dart
abstract interface class BudgetRepository {
  Future<int?> fetchBudget({DateTime? date});
  Future<void> saveBudget({required int amount, DateTime? date});
}
```

```dart
class RemoteBudgetRepository implements BudgetRepository {
  const RemoteBudgetRepository(this._api);

  final ApiClient _api;

  @override
  Future<int?> fetchBudget({DateTime? date}) async {
    try {
      final body = await _api.get(
        ApiEndpoints.budget,
        queryParameters: date == null ? null : {'date': apiDate(date)},
      );
      final data = body['data'];
      final budget = data is Map ? data['budget'] : null;
      return budget is Map ? (budget['amount'] as num?)?.toInt() : null;
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<void> saveBudget({required int amount, DateTime? date}) async {
    await _api.put(
      ApiEndpoints.budget,
      data: {
        if (date != null) 'date': apiDate(date),
        'amount': amount,
      },
    );
  }
}
```

### 15.2 Error message ကို user ပြ

```dart
Future<void> _saveBudgetToBackend(BuildContext context, int amount) async {
  try {
    await context.read<BudgetRepository>().saveBudget(amount: amount);
  } on ApiException catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message)),
    );
    rethrow;
  }
}
```

### 15.3 Client max validation

```dart
const maxBudget = 10000000;

if (amount == null || amount <= 0) {
  return 'Enter a budget greater than 0 MMK';
}
if (amount > maxBudget) {
  return 'Budget cannot exceed 10,000,000 MMK';
}
```

### 15.4 Loading state

```dart
final ValueNotifier<bool> budgetLoading = ValueNotifier<bool>(false);
```

`GET /budget` စချိန် `true`၊ ပြီးရင် `false`။ Card မှာ skeleton ပြ။

### 15.5 Timezone ကို server သုံး

`date` ကို မပို့ဘဲ server ရဲ့ default (Asia/Yangon) ကို သုံးတာ ပိုလုံခြုံပါတယ်။

```dart
await api.put('/budget', data: {'amount': amount});
```

---

## 16. စမ်းသပ်ရန် Checklist

### Guest

- [ ] Budget မရှိချိန် "Set your budget" ပြ
- [ ] 15,000 ထည့် → သိမ်း → 15,000 MMK ပြ
- [ ] App ပိတ်ပြီး ပြန်ဖွင့် → ပျောက်
- [ ] 0 ထည့် → validation error
- [ ] Quick amount chip → input ပြည့်
- [ ] Edit → 20,000 → confirmation မှာ 20,000

### Logged-in

- [ ] 15,000 သိမ်း → DB ရောက်
- [ ] App ပြန်ဖွင့် → 15,000 ပြန်
- [ ] Edit → 20,000 → DB update
- [ ] Logout → budget ရှင်း
- [ ] Account လဲ → အရင် budget မပြ
- [ ] Network ဖြတ် → save fail → **error ပြရမယ် (လက်ရှိ မပြ)**
- [ ] 10,000,001 ထည့် → backend 422

### Plan နှင့် ဆက်စပ်

- [ ] Budget မရှိဘဲ Auto Plan → budget screen ရှေ့
- [ ] Budget ရှိမှ plan save ရ
- [ ] Auto plan budget ကျော် → 422
- [ ] Manual plan budget ကျော် → သိမ်း၊ warning
- [ ] Budget ပြင်ရင် plan မပျက်
- [ ] Plan ဖျက်ရင် budget ကျန်

### UI/Navigation

- [ ] SetBudgetPage back → Home
- [ ] BudgetSavePage back → Home
- [ ] Confirmation မှ Edit → save → confirmation ပြန်
- [ ] Confirmation မှ Auto/Manual → planner
- [ ] Save double tap → တစ်ခါပဲ သိမ်း

---

## 17. အနှစ်ချုပ်

Budget feature ကို class အားဖြင့် —

```text
HomePage
  ├── openBudget              (entry)
  ├── _saveBudgetToBackend    (PUT)
  ├── _startPlan              (budget gate)
  ├── _budgetCard             (display)
  └── _PlanSessionGate
        └── _syncSession      (GET + restore)

SetBudgetPage
  ├── _amount                 (input parse)
  ├── _save                   (validate + callback + nav)
  └── validator               (> 0)

BudgetSavePage
  ├── _edit                   (re-open editor)
  ├── _home                   (pop)
  └── _openPlan               (planner)

GuestBudget
  ├── dailyBudget             (ValueNotifier)
  ├── save / clear / format
  └── amount / hasBudget

Backend
  ├── budgetRoutes            (GET/PUT)
  ├── budgetController        (get/set)
  └── DailyBudget             (upsert by user+date)
```

အလုပ်လုပ်ပုံကို တစ်ကြောင်းတည်း ပြောရရင် —

```text
User က ငွေပမာဏ ထည့်
  → SetBudgetPage က စစ်
  → Logged-in ဆို PUT /budget
  → Guest ဆို GuestBudget
  → GuestBudget.dailyBudget ပြောင်း
  → Home card အလိုအလျောက် ပြ
  → Confirmation page မှ planner ဆက်ဝင်နိုင်
```

အဓိက အားသာချက်က **guest နဲ့ logged-in နှစ်မျိုးလုံး တစ်နေရာတည်းက ကိုင်နိုင်တာ** ဖြစ်တယ်။ အဓိက အားနည်းချက်က **Path A မှာ error ဖြစ်ရင် user ကို မပြတာ** နဲ့ **repository/BLoC မဖြတ်ဘဲ UI ထဲ တိုက်ရိုက် API ခေါ်တာ** ဖြစ်တယ်။

---

*ဒီ document ကို `home_page.dart`, `set_budget.dart`, `budget_save.dart`, `guest_budget.dart` နှင့် backend budget controller/model တို့ကို တိုက်ရိုက်ဖတ်ပြီး ရေးထားပါတယ်။*
