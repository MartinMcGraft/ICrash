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
- No Google account is authenticated and no cloud Firebase resource exists yet. The browser login is waiting for user completion.
- Real Firestore location remains an explicit user decision before database creation.

Phase 2 and workstreams A–J have not started.

See `MODERNIZATION_2026.md` for the baseline modernization and `ICRASH_V2_SPECIFICATION.md` for the authoritative V2 scope.
