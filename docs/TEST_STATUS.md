# Test status

Updated: 2026-09-09

## Phase 2, V2 login/institution slice — Android emulator live validation

Full walkthrough on `ICrash_API_36`, against the local Auth/Firestore emulators seeded via `firestore-tests/seed_emulator.mjs`:

- Login screen: WORKING. Empty-field validation shows both PT-PT error messages; valid credentials sign in via the Auth emulator; invalid credentials show "Credenciais inválidas...".
- Institution selection: WORKING. `collectionGroup('memberIndex')` query returns the seeded "Hospital de Teste"; tapping it opens the dashboard placeholder. Empty-state message was verified separately via widget test (no second seeded account was created to exercise it live).
- Dashboard placeholder: WORKING. Shows the real institution name; "Abrir aplicação anterior (referência)" opens the legacy `HomeMenu`, which still renders Registration/QR Code Reader/Data matrix scan unchanged; back navigation returns to the placeholder correctly. Sign-out button verified via widget test (`institution_selection_screen_test.dart`).
- No fatal `pt.icrash.app` exceptions in logcat across the whole session; unrelated OS/emulator noise (Bluetooth power stats, audio HAL, Play Services Phenotype API) was present as usual on this AVD image and is not app-caused.

Three real bugs were found and fixed only because of this live run — none of them would have been caught by `flutter analyze`/`flutter test`/a successful build alone, which is exactly the risk the spec's mandatory-live-validation rule exists to catch:

1. **`MainActivity` package mismatch** (pre-existing since Phase 1, not introduced this session): `android/app/src/main/kotlin/com/example/app1/MainActivity.kt` still declared `package com.example.app1` after the Phase 1 rename of `applicationId`/`namespace` to `pt.icrash.app`, so the app crashed on every launch with `ClassNotFoundException`. Fixed by moving the file to `android/app/src/main/kotlin/pt/icrash/app/MainActivity.kt` and correcting the package declaration.
2. **Cleartext traffic blocked**: Android's default network security policy blocks the plain-HTTP traffic the Auth/Firestore emulators use, failing every emulator request with `Cleartext HTTP traffic to 10.0.2.2 not permitted`. Fixed with a debug-build-only `network_security_config.xml` (see `docs/ARCHITECTURE.md`/`docs/FIREBASE_MODEL.md` for the full explanation) — never applies to release builds.
3. **Firebase project id mismatch under the emulator** and the collection-group Rules quirk that surfaced alongside it — see `docs/FIREBASE_MODEL.md` ("Why `memberIndex` exists") and `docs/ARCHITECTURE.md` ("Environment selection") for the full story; fixed with the `memberIndex` collection plus a dedicated named `FirebaseApp` for emulator mode.

## Phase 2 foundation — automated validation

- `flutter analyze --no-pub`: passed, no issues, after adding `lib/src/**` (domain/data/services/presentation/common layers) and rewiring `lib/main.dart` to `bootstrapFirebase()`.
- `flutter test --no-pub`: passed, 19 tests — `test/domain/inventory_rules_test.dart` (11, including the two literal critical inventory scenarios from spec sections 58 and 59), `test/widget_test.dart` (legacy `HomeMenu` smoke test, now pumped directly rather than via `MyApp` since `MyApp` requires a real Firebase app), and three new presentation-layer suites using fakes from `test/fakes/fake_repositories.dart`: `login_screen_test.dart`, `institution_selection_screen_test.dart`, `dashboard_placeholder_screen_test.dart`.
- `flutter build apk --debug --no-pub`: passed, confirming the Firebase bootstrap (emulator-by-default in debug, cloud in release) compiles end to end on Android.
- `firebase emulators:exec --only firestore --project demo-icrash-v2 "npm --prefix firestore-tests test"`: passed, 22/22 Firestore Rules tests — spec section 60's security scenarios plus the `memberIndex` collection-group query (own-institution read, cross-user denial, admin-only writes).
- Full Android emulator live walkthrough of the new screens: see the section above.
- Web/Windows builds were not re-run this phase (no code path affecting those platforms changed beyond `bootstrapFirebase()`/`AppServices`, already exercised via `flutter analyze`/`flutter test`); re-verify before the next release-oriented milestone.

## Phase 0 automated validation

- `flutter pub get`: passed; two indirect packages remain constrained by Flutter.
- `flutter analyze --no-pub`: passed, no issues.
- `flutter test --no-pub`: passed, 1 widget test.
- `flutter build apk --debug --no-pub`: passed.
- `flutter build web --no-pub`: passed; WebAssembly dry run passed.
- `flutter build windows --no-pub`: passed.
- `flutter run -d emulator-5554 --debug --no-pub`: launched and attached to the Dart VM service.

## Android walkthrough

Device: `ICrash_API_36`, Android 16 / API 36.

- Home screen: WORKING; three entry points visible.
- Registration navigation/form rendering: WORKING; submission was not attempted because it still targets the obsolete Django endpoint.
- QR reader: WORKING BUT NEEDS IMPROVEMENT; screen and camera service opened and back navigation returned home. No physical code was available.
- Data Matrix analyser: WORKING BUT NEEDS IMPROVEMENT; screen opened and an analysis attempt returned `Nenhuma data de validade encontrada` for the virtual camera image.
- Runtime: no fatal Flutter/application error. CameraX reported transient missing-camera/availability warnings on the headless virtual camera before opening it.

## Known gaps

Physical-camera QR/GS1 validation, backend flows, permissions UI, offline/reconnection UX and full V2 screen coverage remain untested — nothing in the presentation layer consumes the new repositories yet. Security Rules now have automated coverage (see Phase 2 above), but only for the scenarios in spec section 60; broader domain scenarios (multi-lot replenishment through the real repository against the emulator, offline queued writes replaying against Rules) are still open. Scanner abstractions and mock GS1 inputs belong to later phases. iOS/macOS cannot be claimed from Windows. The complete screen classification is deferred until V2 screens replace the legacy ones, as required by the specification.

## Phase 1 local Firebase foundation

- Firebase CLI 15.29.0 and FlutterFire CLI 1.4.1 version checks passed.
- `firebase emulators:exec --only auth,firestore --project demo-icrash-v2` passed.
- Auth and Firestore started without cloud authentication and shut down after the test command.
- Initial Firestore port 8080 was unavailable because an existing Apache service owns it; configuration moved to the free port 8081 and then passed.
- No Flutter-to-emulator integration or Rules behavior test exists yet; these remain Phase 1/2 work.
- Cloud Firestore database provisioning: passed. Default database confirmed as Standard / Native / `eur3` / free tier. No application data was written.
- FlutterFire configuration: passed for Android, iOS, macOS, web and Windows options; the generated Dart configuration selects the correct platform at runtime.
- Firebase Authentication: e-mail/password provider enabled in the Firebase console. No users were created.
- `flutter analyze`: passed after Firebase integration, no issues.
- `flutter test`: passed after Firebase integration, 1 widget test.
- `flutter build web --wasm --no-web-resources-cdn`: passed after Firebase integration.
- Android Firebase configuration was completed with the Google Services Gradle plugin and `flutter build apk --debug` passed.
- Visual Studio Community 2022 updated from 17.5 to 17.14.40 with the required C++ tools.
- `flutter build windows --debug`: passed after the Visual Studio update; the Windows executable was generated successfully.
