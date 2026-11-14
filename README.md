# MealMate

Campus meal planning and actual-expense tracking for Windows and Android.

- **Frontend:** Flutter (`flutter_bloc`, `dio`, `flutter_secure_storage`)
- **Backend:** Express + MongoDB (`server/`)

## Project structure

```
lib/
├── constants/       colors, theme, API endpoints, app settings
├── models/          User, AuthSession and JSON (de)serialization
├── services/        Dio API client, secure token storage, API errors
├── repositories/    AuthRepository contract + remote implementation
├── logic/           BLoC events, states and AuthBloc
├── ui/              screens (splash, home, login, sign-up, budget, foods)
└── main.dart        dependency wiring and app bootstrap
server/
├── src/models/      Mongoose schemas (User)
├── src/controllers/ auth + profile controllers
├── src/routes/      /api/auth and /api/users routes
└── src/             app, server bootstrap, config, middleware
```

Guest planning still uses temporary in-memory state (`GuestBudget`); account
data is persisted by the API.

## Run the backend

```bash
cd server
cp .env.example .env       # Windows: copy .env.example .env
# set JWT_SECRET to a long random value
npm install
npm run dev                # http://localhost:4000
```

See `server/README.md` for the endpoint contract and curl examples.

## Run the Flutter app

```bash
flutter pub get
flutter run -d windows     # or: flutter run -d android
```

The API base URL defaults to:

| Target                   | URL                       |
| ------------------------ | ------------------------- |
| Windows / web / iOS      | `http://localhost:4000/api` |
| Android emulator         | `http://10.0.2.2:4000/api`  |

For a physical Android device or a remote server, override it:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:4000/api
```

Android debug builds allow cleartext HTTP for the local API; production must
use HTTPS.

> **Windows desktop note:** plugins require symlink support. If `flutter run`
> reports “Building with plugins requires symlink support”, enable Windows
> Developer Mode (`start ms-settings:developers`) once, then retry.

## Checks

```bash
flutter analyze
flutter test
```
