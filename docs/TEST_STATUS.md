# Test status

Updated: 2026-09-09

## Phase 2 foundation — automated validation

- `flutter analyze --no-pub`: passed, no issues, after adding `lib/src/**` (domain/data/services/common layers) and rewiring `lib/main.dart` to `bootstrapFirebase()`.
- `flutter test --no-pub`: passed, 12 tests — the pre-existing widget test plus 11 new tests in `test/domain/inventory_rules_test.dart`, including the two literal critical inventory scenarios from spec sections 58 and 59 (daily consumption never touches batches/expiry; only audit reconciliation may advance `earliestKnownExpiry`; replenishment can only pull it earlier, never later).
- `flutter build apk --debug --no-pub`: passed, confirming the new Firebase bootstrap (emulator-by-default in debug, cloud in release) compiles end to end on Android. Pre-existing Kotlin Gradle Plugin deprecation warnings from `firebase_auth`/`firebase_core`/`mobile_scanner` are unrelated to this phase.
- `firebase emulators:exec --only firestore --project demo-icrash-v2 "npm --prefix firestore-tests test"`: passed, 18/18 Firestore Rules tests covering spec section 60's security scenarios (unauthenticated denied, cross-institution isolation, unassigned-cart access denied, assigned-user write scope limited to `currentQuantity`, no self-role-escalation, only a platform super admin creates institutions, `usageEvents`/`auditEvents` are create-only even for institution admins).
- No Flutter-to-emulator integration test exists yet (nothing in the presentation layer calls the new repositories); that lands with the first V2 screen in the next phase.
- Web/Windows builds were not re-run this phase (no code path affecting those platforms changed beyond the same `bootstrapFirebase()` call already exercised via `flutter analyze`); re-verify before the next release-oriented milestone.

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
