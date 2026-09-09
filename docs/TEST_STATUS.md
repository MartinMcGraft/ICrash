# Test status

Updated: 2026-09-09

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

Physical-camera QR/GS1 validation, backend flows, Firebase, permissions, offline/reconnection, security Rules and V2 domain scenarios remain untested. Scanner abstractions and mock GS1 inputs belong to later phases. iOS/macOS cannot be claimed from Windows. The complete screen classification is deferred until the minimum Firebase replacement operates, as required by the specification.

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
- Windows Firebase build: blocked by Visual Studio 2022 17.5 linker incompatibility with the current Firebase C++ SDK; update the C++ toolchain before retrying.
