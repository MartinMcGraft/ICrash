# AI handoff

Updated: 2026-09-09

- Repository: `C:\Users\Pedro Jorge\Documents\projeto icrash\ICrash-git`
- Remote: `https://github.com/MartinMcGraft/ICrash.git`
- Current branch: `DEV-Pedro`
- Base commit: `8e0e619` (`origin/main`)
- Stable Phase 0 implementation commit: `ef09179a7bbbb400c4d7cea743860693164d11da`, published as `origin/DEV-Pedro`.
- Flutter application: `03_Implementacao/app1`
- Preserved backup: `C:\Users\Pedro Jorge\Documents\projeto icrash\backup-before-update-20260907`

## Completed work

The earlier local modernization was applied to the true repository while preserving its history and all historical directories. Flutter/Dart, dependencies, native platform configuration, QR scanner migration and baseline test updates are described in `MODERNIZATION_2026.md`. The V2 specification and mandatory documentation files were added at repository root.

## Current phase

Phase 0 is complete and published. Phase 1 now has a functional Firebase foundation: local Auth/Firestore emulators, the approved Firestore database in `eur3`, FlutterFire configuration and e-mail/password Authentication. Phase 2 must replace the remaining legacy flows with the V2 domain model and repositories.

## Firebase and V2 state

Phase 1 local foundation exists: `.firebaserc` selects the non-cloud `demo-icrash-v2`; `firebase.json` configures Auth `127.0.0.1:9099`, Firestore `127.0.0.1:8081` and UI `127.0.0.1:4000`; the local suite startup test passed. `firestore.rules` denies all access until Phase 2 security work, and the indexes file is empty. Cloud project `i-crash-pt-2026` now has a Standard Native Firestore database in `eur3`, Spark billing, five FlutterFire platform registrations and e-mail/password Authentication. No users, collections, domain models, repositories or migrations exist. No App Check, Storage or Functions were enabled. Owner identities are still required.

V2 architecture decisions already accepted by the specification: layered repositories; institution-scoped access; Cloud Firestore for the prototype; offline support; aggregate `currentQuantity` independent from known batch totals; no FEFO/FIFO inference; conservative expiry until physical reconciliation; no identifiable patient information.

## Dependencies and migrations

See `03_Implementacao/app1/pubspec.yaml`, `pubspec.lock`, and `MODERNIZATION_2026.md`. The legacy Django backend remains as historical source but must not be restored for V2. Do not redo the Flutter upgrade.

## Tests and known limitations

Phase 0 on the true repository: analyzer clean; widget test passed; Android debug, Web and Windows release builds passed. `flutter run` launched on `ICrash_API_36`. Homepage, registration, QR reader, back navigation and Data Matrix analyser were exercised. The virtual camera opened after transient CameraX availability warnings; no real QR/Data Matrix could be validated. After Firebase integration, analyzer, tests, Android debug APK, web build and Windows debug build pass. Visual Studio Community 2022 is now 17.14.40 with the required C++ toolchain. Complete backend flows, physical camera, iOS and macOS remain unvalidated. V2 tests and Firebase Rules tests do not exist yet.

`mobile_scanner` still relies on the legacy Kotlin Gradle plugin compatibility mode. Android SDK's new command reports that `--licenses` is obsolete while Flutter Doctor reports license status unknown; Android compilation nevertheless succeeds.

## Environment

- Flutter: `C:\Flutter\stable\bin\flutter.bat`
- Git: `C:\Program Files\Git\cmd\git.exe`
- Android SDK: `C:\Android\Sdk`
- Emulator: `ICrash_API_36` / usually `emulator-5554`
- Required Java workaround: `JDK_JAVA_OPTIONS=-Djdk.net.unixdomain.tmpdir=C:/Flutter/socket-temp`
- Firebase CLI: `C:\Users\Pedro Jorge\AppData\Roaming\npm\firebase.cmd` (15.29.0)
- FlutterFire CLI: `C:\Users\Pedro Jorge\AppData\Local\Pub\Cache\bin\flutterfire.bat` (1.4.1)

Firebase CLI is authenticated. Cloud development project: visible name `I-Crash`, ID `i-crash-pt-2026`, Spark plan. `.firebaserc` keeps `demo-icrash-v2` as the safe local default and names the cloud project `development`. The Firestore database is provisioned in `eur3`, Standard edition, Native mode and free tier; it has closed Rules, with point-in-time recovery and delete protection disabled. FlutterFire uses `pt.icrash.app` on Android/iOS and `pt.icrash.app.macos` on macOS, with web registrations for web and Windows. Firebase Core is initialized in `lib/main.dart`; Authentication and Firestore packages are installed; e-mail/password Authentication is enabled. No users, application data, App Check, Storage, Cloud Functions or billing account exist.

## Do not redo

Do not initialize another repository, develop on or push to `main`, restore Django, discard the backup, recreate Firebase without location approval, repeat the SDK modernization, commit secrets/build caches, or claim iOS/macOS validation from Windows.
