# ICrash

> Full project documentation (architecture, business rules, history, setup): see the
> [repository README](../README.md).

Flutter app for I-Crash, the Intelligence Crash-Cart Management System.
One codebase, two shells: the **App** (Android / iOS / iPadOS, landscape) and
the **Admin Dashboard** (web / Windows / macOS / Linux). Backend: Firebase
(Auth + Cloud Firestore). The Firestore rules, emulator config, rules tests
and admin tools live in `../firebase`.

Extracted on 2026-10-15 from `03_Implementacao/app1`, without the legacy V1
code (`home_menu.dart`, `grids/`, `registration/`, `request_handler/`,
`qr_code_reader/`, `updates/`, `teste/`, `lib/images/`). The original,
including the legacy code, is kept untouched in `03_Implementacao/`.

## Getting started

```sh
flutter pub get
flutter test
flutter run                                  # debug → local Firebase emulator
flutter run --dart-define=ICRASH_BACKEND=cloud
flutter run --dart-define=ICRASH_SHELL=dashboard   # force a shell (app|dashboard)
```

Code layout (MVVM): `lib/src/domain` (entities, rules, repository
interfaces), `lib/src/data` (Firebase and local implementations),
`lib/src/services`, `lib/src/ui` (shells, features, view models).
