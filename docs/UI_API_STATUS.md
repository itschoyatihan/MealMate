# MealMate — UI နှင့် API အခြေအနေ အနှစ်ချုပ်

**ရက်စွဲ:** 2026-11-12  
**ရည်ရွယ်ချက်:** လက်ရှိ UI ရေးပြီး/မရေးရသေးတဲ့ အပိုင်းနှင့် API ချိတ်ပြီး/မချိတ်ရသေးတဲ့ အပိုင်းကို လိုရင်းတိုရှင်း ကြည့်ရန်

---

## 1. UI ရေးပြီး / မရေးရသေး

### 1.1 အနှစ်ချုပ်

| အမျိုးအစား | အရေအတွက် |
|---|---|
| ရေးပြီးသား screen | 11 |
| တစ်စိတ်တစ်ပိုင်း | 2 |
| လုံးဝ မရေးရသေး | 5 |
| **စုစုပေါင်း** | **18** |

```text
UI screen coverage ≈ 11 / 18 = 61% (တစ်စိတ်တစ်ပိုင်း ထည့်ရင် ≈ 72%)
```

### 1.2 ရေးပြီးသား UI (11)

| # | Screen | ဖိုင် | လုပ်ဆောင်ချက် |
|---|---|---|---|
| 1 | Splash | `splash_page.dart` | ၃ စက္ကန့်ပြ၊ Home ပို့ |
| 2 | Login | `login_page.dart` | Email/password၊ error banner၊ loading |
| 3 | Sign Up | `signup_page.dart` | Register form၊ auto login |
| 4 | Home | `home_page.dart` | Budget card၊ planner cards၊ today plan |
| 5 | Set Budget | `set_budget.dart` | ပမာဏထည့်၊ validation |
| 6 | Budget Confirm | `budget_save.dart` | သိမ်းပြီး အတည်ပြု |
| 7 | Foods | `foods_page.dart` | Search၊ category၊ favorites |
| 8 | Auto Planner | `auto_page.dart` | Auto plan ဆောက်၊ save |
| 9 | Manual Planner | `manual_page.dart` | Food ရွေး၊ quantity၊ save |
| 10 | Manual Browse | `manual_browse.dart` | Food ရှာ၊ detail ကြည့် |
| 11 | My Plan | `myplan_page.dart` | Plan ပြ၊ edit၊ delete dialog |

### 1.3 တစ်စိတ်တစ်ပိုင်း (2)

| Screen | ရှိပြီး | မရှိသေး |
|---|---|---|
| Account / Profile | Name, email, logout dialog | Edit profile၊ change password |
| Protected feature cards | Reports/Expenses/History card နှင့် login စစ်ခြင်း | သက်ဆိုင်ရာ page တွေ မရှိ |

### 1.4 လုံးဝ မရေးရသေး (5)

| # | Screen | လိုအပ်ချက် |
|---|---|---|
| 1 | Expenses | နေ့စဉ် စားသုံးမှု ထည့်/ပြ/ဖျက် |
| 2 | History | ရက်အလိုက် မှတ်တမ်း ပြန် |
| 3 | Reports | Daily/weekly/monthly summary |
| 4 | Profile Settings | အမည်ပြင်၊ password ပြင် |
| 5 | Guest Transfer | Guest data ကို account ထဲ ရွှေ့ရန် |

---

## 2. API ချိတ်ပြီး / မချိတ်ရသေး

### 2.1 အနှစ်ချုပ်

| အမျိုးအစား | အရေအတွက် |
|---|---|
| အပြည့်အစုံ ချိတ်ပြီး | 10 |
| Repository ရှိပြီး UI မခေါ် | 3 |
| လုံးဝ မချိတ်ရသေး | 4 |
| **စုစုပေါင်း feature** | **17** |

```text
API integration coverage ≈ 10 / 17 = 59% (တစ်စိတ်တစ်ပိုင်း ထည့်ရင် ≈ 76%)
```

### 2.2 ချိတ်ပြီး endpoints (12)

| # | Endpoint | ခေါ်တဲ့ code | အသုံး |
|---|---|---|---|
| 1 | `POST /auth/register` | `RemoteAuthRepository.register` | Register |
| 2 | `POST /auth/login` | `RemoteAuthRepository.login` | Login |
| 3 | `GET /auth/me` | `restoreSession` | Session ပြန် |
| 4 | `POST /auth/logout` | `logout` | Logout |
| 5 | `PUT /budget` | `HomePage._saveBudgetToBackend` | Budget သိမ်း |
| 6 | `GET /budget` | `_PlanSessionGateState` | Budget ပြန်ဖတ် |
| 7 | `GET /foods` | `FoodRepository.getFoods` | Catalog ဆွဲ |
| 8 | `GET /favorites` | `getFavoriteIds` | Favorite စာရင်း |
| 9 | `POST /favorites` | `setFavorite` | Favorite ထည့် |
| 10 | `DELETE /favorites/:foodId` | `setFavorite` | Favorite ဖျက် |
| 11 | `POST /plans` | `MealPlanRepository.save` | Plan သိမ်း |
| 12 | `GET /plans` | `MealPlanRepository.getSavedPlan` | Plan ပြန်ဖတ် |

### 2.3 Repository ရှိပြီး UI မခေါ်သေး (3)

| Endpoint | Code ရှိ | ပြဿနာ |
|---|---|---|
| `DELETE /plans` | `MealPlanRepository.delete` | ဘယ်နေရာကမှ မခေါ် — plan delete က local only |
| `PATCH /users/me` | `updateProfile` | UI/BLoC event မရှိ |
| `PATCH /users/me/password` | `changePassword` | UI/BLoC event မရှိ |

### 2.4 လုံးဝ မချိတ်ရသေး (4 feature)

| Feature | လိုအပ်တဲ့ endpoint | လက်ရှိ UI |
|---|---|---|
| Expenses | `GET/POST/DELETE /expenses` | မရှိ |
| History | `GET /history` | မရှိ |
| Reports | `GET /reports` | မရှိ |
| Guest Transfer | `POST /guest-transfer` | မရှိ |

### 2.5 Feature အလိုက် အခြေအနေ

| Feature | UI | API | အခြေအနေ |
|---|---|---|---|
| Register / Login / Restore / Logout | ရှိ | ချိတ်ပြီး | အပြည့်အစုံ |
| Budget save + load | ရှိ | ချိတ်ပြီး | အပြည့်အစုံ |
| Foods catalog | ရှိ | ချိတ်ပြီး | အပြည့်အစုံ |
| Favorites | ရှိ | ချိတ်ပြီး | အပြည့်အစုံ |
| Plan save + load | ရှိ | ချိတ်ပြီး | အပြည့်အစုံ |
| Plan delete | ရှိ | မချိတ် | Local only |
| Profile update | Dialog ပဲ | Repo ရှိ | တစ်စိတ်တစ်ပိုင်း |
| Change password | မရှိ | Repo ရှိ | တစ်စိတ်တစ်ပိုင်း |
| Expenses | မရှိ | မချိတ် | မစရသေး |
| History | မရှိ | မချိတ် | မစရသေး |
| Reports | မရှိ | မချိတ် | မစရသေး |
| Guest transfer | မရှိ | မချိတ် | မစရသေး |

---

## 3. လိုရင်း ကောက်ချက်

- **အလုပ်လုပ်နေတာ:** Auth, Budget, Foods, Favorites, Plan save/load
- **ချက်ချင်း ပြင်သင့်တာ:** Plan delete ကို `DELETE /plans` နဲ့ ချိတ်၊ Plan load error ကို user သိနိုင်အောင် ပြ
- **နောက်ထပ် စရန်:** Guest transfer → Expenses → History → Reports → Profile → Hardening

---

*ဒီစာမျက်နှာသည် `docs/PROGRESS_ANALYSIS.md` ရဲ့ UI/API အပိုင်းကို လိုရင်းချုပ်ထားတဲ့ အနှစ်ချုပ်ဖြစ်သည်။*
