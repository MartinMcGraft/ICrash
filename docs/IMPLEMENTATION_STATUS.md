# Implementation status

Updated: 2026-09-09

## Phase 0 — Git / DEV-Pedro

Status: complete and published.

- Private repository cloned from `https://github.com/MartinMcGraft/ICrash.git`.
- Remote default branch confirmed as `main` at commit `8e0e619`.
- Local integration branch `DEV-Pedro` created from `origin/main`.
- Existing modernization applied to `03_Implementacao/app1` without deleting the historical Django server, report, planning, analysis or design material.
- V2 specification and continuity documents added under `docs/`.
- `flutter analyze`, Flutter tests, Android/Web/Windows builds and Android debug execution passed.
- Android walkthrough covered the homepage, registration screen, QR reader, hardware-back navigation and Data Matrix analyser. No fatal application error was observed.
- The virtual camera could not validate a real code and produced CameraX availability warnings; physical-camera validation remains pending.
- Stable modernization commit: `ef09179a7bbbb400c4d7cea743860693164d11da`, published to `origin/DEV-Pedro`.

## Phase 1 — Firebase foundation

Status: in progress.

- Firebase CLI 15.29.0 and FlutterFire CLI 1.4.1 installed; FlutterFire added to the user PATH.
- Safe local project `demo-icrash-v2` configured with Auth on 9099, Firestore on 8081 and Emulator UI on 4000.
- Auth and Firestore emulators started and stopped successfully. Firestore begins with deny-all Rules until Phase 2 implements and tests authorization.
- Firebase CLI login completed. The initial Google Cloud Terms blocker was resolved before project creation.
- Google Cloud Terms were accepted and the Firebase development project was created: visible name `I-Crash`, technical ID `i-crash-pt-2026`. It remains on the Spark plan; no billing account, App Check setting, Storage bucket or Cloud Function was created.
- The default Cloud Firestore database was created with the authorized immutable location `eur3`, Standard edition and Native mode. The Firebase CLI confirms `freeTier: true`; point-in-time recovery and delete protection remain disabled. Firebase's initial closed rules prevent external access until Phase 2 rules are deployed and tested.
- FlutterFire registered Android, iOS, macOS, web and Windows app configurations. The production identifiers are `pt.icrash.app` (Android/iOS) and `pt.icrash.app.macos` (macOS); the legacy `com.example.app1` identifiers were removed.
- Firebase Core, Authentication and Cloud Firestore are installed. Firebase is initialized before the Flutter application starts.
- Firebase Authentication is active with e-mail and password only. No user was created and e-mail-link login remains disabled.
- Android, web and Windows compile with the Firebase integration. Visual Studio Community 2022 was updated from 17.5 to 17.14.40, resolving the Firebase Windows SDK linker incompatibility.

Phase 2 and workstreams A–J have not started.

See `MODERNIZATION_2026.md` for the baseline modernization and `ICRASH_V2_SPECIFICATION.md` for the authoritative V2 scope.
