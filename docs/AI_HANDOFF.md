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

Phase 0 is complete and published. Analysis, tests, Android/Web/Windows builds and live Android debug execution passed. The next operation is Phase 1: inspect Firebase tooling/authentication, prepare local Auth/Firestore emulators and cloud project configuration, but do not create the irreversible Firestore database location until the user approves it.

## Firebase and V2 state

Phase 1 local foundation exists: `.firebaserc` selects the non-cloud `demo-icrash-v2`; `firebase.json` configures Auth `127.0.0.1:9099`, Firestore `127.0.0.1:8081` and UI `127.0.0.1:4000`; the local suite startup test passed. `firestore.rules` denies all access until Phase 2 security work, and the indexes file is empty. No cloud project, application configuration, collections, domain models, repositories or migrations exist. No billing, Storage or Functions were enabled. Before creating the real Firestore database, ask the user to approve the irreversible location. Owner identities are also still required.

V2 architecture decisions already accepted by the specification: layered repositories; institution-scoped access; Cloud Firestore for the prototype; offline support; aggregate `currentQuantity` independent from known batch totals; no FEFO/FIFO inference; conservative expiry until physical reconciliation; no identifiable patient information.

## Dependencies and migrations

See `03_Implementacao/app1/pubspec.yaml`, `pubspec.lock`, and `MODERNIZATION_2026.md`. The legacy Django backend remains as historical source but must not be restored for V2. Do not redo the Flutter upgrade.

## Tests and known limitations

Phase 0 on the true repository: analyzer clean; widget test passed; Android debug, Web and Windows release builds passed. `flutter run` launched on `ICrash_API_36`. Homepage, registration, QR reader, back navigation and Data Matrix analyser were exercised. The virtual camera opened after transient CameraX availability warnings; no real QR/Data Matrix could be validated. Complete backend flows, physical camera, iOS and macOS remain unvalidated. V2 tests and Firebase Rules tests do not exist yet.

`mobile_scanner` still relies on the legacy Kotlin Gradle plugin compatibility mode. Android SDK's new command reports that `--licenses` is obsolete while Flutter Doctor reports license status unknown; Android compilation nevertheless succeeds.

## Environment

- Flutter: `C:\Flutter\stable\bin\flutter.bat`
- Git: `C:\Program Files\Git\cmd\git.exe`
- Android SDK: `C:\Android\Sdk`
- Emulator: `ICrash_API_36` / usually `emulator-5554`
- Required Java workaround: `JDK_JAVA_OPTIONS=-Djdk.net.unixdomain.tmpdir=C:/Flutter/socket-temp`
- Firebase CLI: `C:\Users\Pedro Jorge\AppData\Roaming\npm\firebase.cmd` (15.29.0)
- FlutterFire CLI: `C:\Users\Pedro Jorge\AppData\Local\Pub\Cache\bin\flutterfire.bat` (1.4.1)

Firebase CLI currently has no authorized account. An official Firebase login page has been handed to the user. Continue authentication only after the user completes the Google sign-in. Do not request or store passwords. Port 8080 remains owned by an unrelated Apache service, so Firestore emulator uses 8081.

Firebase CLI is authenticated. `firebase projects:create i-crash-pt-2026 --display-name I-Crash` was attempted, but Google Cloud rejected it with `Callers must accept Terms of Service`; the operation did not create a project. The user must accept Google Cloud Terms of Service before retrying. Do not create Firestore until the user also expressly approves its irreversible location.

Google Cloud Terms were subsequently accepted and the retry succeeded. Cloud development project: visible name `I-Crash`, ID `i-crash-pt-2026`, Spark plan. `.firebaserc` keeps `demo-icrash-v2` as the safe local default and names the cloud project `development`. No Firestore database, Authentication provider, Firebase app registration, App Check setting, Storage bucket, Cloud Function, billing account or data was created. Before using FlutterFire, decide production application IDs instead of registering the legacy `com.example.app1` identifier.

The default Firestore database is now provisioned: location `eur3`, Standard edition, Native mode, free tier. It has Firebase's initial closed rules. Point-in-time recovery and delete protection are disabled. No Authentication provider, Firebase app registration, App Check setting, Storage bucket, Cloud Function, billing account or application data exists. Before using FlutterFire, decide production application IDs instead of registering the legacy `com.example.app1` identifier.

## Do not redo

Do not initialize another repository, develop on or push to `main`, restore Django, discard the backup, recreate Firebase without location approval, repeat the SDK modernization, commit secrets/build caches, or claim iOS/macOS validation from Windows.
