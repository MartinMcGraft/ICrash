# AI handoff

Updated: 2026-09-09

- Repository: `C:\Users\Pedro Jorge\Documents\projeto icrash\ICrash-git`
- Remote: `https://github.com/MartinMcGraft/ICrash.git`
- Current branch: `DEV-Pedro`
- Base commit: `8e0e619` (`origin/main`)
- Last published commit before this session: `63fc941` (`chore: validate Windows Firebase build`)
- Flutter application: `03_Implementacao/app1`
- Firestore Rules tests + emulator seed script: `firestore-tests/` (Node project, separate from the Flutter app)
- Preserved backup: `C:\Users\Pedro Jorge\Documents\projeto icrash\backup-before-update-20260907`

## Completed work

Phase 0 (Git/modernization) and Phase 1 (Firebase foundation) are complete and published. Phase 2's architecture foundation (layered domain/data/repositories, Firestore model, security Rules with tests) is complete. **This session added the first V2 presentation slice** — login, institution selection, dashboard placeholder — validated live end-to-end on the Android emulator, plus fixed three real bugs (one pre-existing since Phase 1, two new) that only a live run could catch, plus a dependency-security fix to the legacy Django manifest.

## Exact files changed this session

Security fix (legacy, inert, historical-reference-only Django backend — not restored or developed, only its manifest was patched):
- `03_Implementacao/server/Pipfile`, `Pipfile.lock` — bumped Django 4.2.2 (EOL)/DRF 3.14.0/psycopg2 2.9.6 → Django 5.2.17 (current LTS)/DRF 3.18.1/psycopg2 2.9.12, regenerated via `pipenv lock`, to close the ~60 Dependabot alerts GitHub reported (those alerts track `main`'s dependency graph; this fix is only on `DEV-Pedro` and the user explicitly chose not to open a PR to `main` for it — see "Do not redo" below).

V2 architecture (this session's first sub-phase, already handed off once — see prior commits `b2badfe`, `a1791ed`, `31705a9`, `ae67e8e`):
- Full layered architecture (`lib/src/domain`, `lib/src/data/firebase`, `lib/src/services`, `lib/src/common`), `firestore.rules`, `firestore.indexes.json`, `firestore-tests/`. Unchanged in this later sub-phase except where listed below.

V2 login/institution-selection slice (this sub-phase):
- `03_Implementacao/app1/lib/main.dart` — `_AuthGate` routes `LoginScreen`/`InstitutionSelectionScreen` on auth state; constructs `AppServices` from `bootstrapFirebase()`'s result.
- `03_Implementacao/app1/lib/src/common/app_services.dart` — new. `AppServices` (repository bundle, two constructors: Firebase-backed default, `withRepositories` for tests) + `AppServicesScope` (`InheritedWidget`).
- `03_Implementacao/app1/lib/src/presentation/auth/login_screen.dart` — new.
- `03_Implementacao/app1/lib/src/presentation/institution/institution_selection_screen.dart` — new.
- `03_Implementacao/app1/lib/src/presentation/dashboard/dashboard_placeholder_screen.dart` — new; opens legacy `HomeMenu` unmodified.
- `03_Implementacao/app1/lib/src/data/firebase/firebase_bootstrap.dart` — rewritten. Returns `FirebaseServices` (`FirebaseAuth`+`FirebaseFirestore`); in emulator mode initializes a **separate named `FirebaseApp`** (`icrash-emulator`) with **demo project options** (`projectId: 'demo-icrash-v2'`) instead of touching `[DEFAULT]`. See "Two real bugs" below for why both parts of this are load-bearing.
- `03_Implementacao/app1/lib/src/common/app_environment.dart` — added `emulatorProjectId = 'demo-icrash-v2'` constant.
- `03_Implementacao/app1/lib/src/data/firebase/firestore_institution_repository.dart` — `watchMyInstitutions` now queries `collectionGroup('memberIndex')` instead of `'memberships'`.
- `03_Implementacao/app1/lib/src/data/firebase/firestore_paths.dart` — added `FirestorePaths.memberIndex(institutionId)`.
- `03_Implementacao/app1/android/app/src/main/kotlin/pt/icrash/app/MainActivity.kt` — moved from `.../com/example/app1/MainActivity.kt` (git-mv) and corrected `package pt.icrash.app`. **This bug was pre-existing since Phase 1** (the `applicationId`/`namespace` rename to `pt.icrash.app` never moved the actual Kotlin file), not introduced this session — it just was never caught because no one launched the app on Android after that rename until now.
- `03_Implementacao/app1/android/app/src/debug/res/xml/network_security_config.xml` — new, debug-only, allows cleartext HTTP to `10.0.2.2`/`localhost`/`127.0.0.1` (the emulators).
- `03_Implementacao/app1/android/app/src/debug/AndroidManifest.xml` — references the above via `android:networkSecurityConfig`.
- `03_Implementacao/app1/test/widget_test.dart` — now pumps `HomeMenu` directly (via a plain `MaterialApp`) instead of `MyApp`, since `MyApp` now needs a real Firebase app.
- `03_Implementacao/app1/test/fakes/fake_repositories.dart` — new. Hand-written fakes for every repository interface (`noSuchMethod`-based `UnimplementedFake` base so each fake only overrides what a given test needs) + `buildTestServices(...)` helper. No mocking package was added.
- `03_Implementacao/app1/test/presentation/login_screen_test.dart`, `institution_selection_screen_test.dart`, `dashboard_placeholder_screen_test.dart` — new.
- `firestore.rules` — added the `memberIndex` collection-group rule (see `docs/FIREBASE_MODEL.md`, "Why `memberIndex` exists," for the full empirical story of why this is shaped the way it is — read it before touching this rule).
- `firestore.indexes.json` — `memberships` → `memberIndex` in the collection-group index.
- `firestore-tests/rules.test.mjs` — added `memberIndex` seeding + a 4-test `describe` block (22 tests total).
- `firestore-tests/seed_emulator.mjs` — now also seeds a `memberIndex` doc alongside the `memberships` doc.
- `docs/ARCHITECTURE.md`, `docs/FIREBASE_MODEL.md`, `docs/IMPLEMENTATION_STATUS.md`, `docs/TEST_STATUS.md` — updated.

## Architecture decisions

- **Dependency wiring, previously left open, now decided**: `AppServices` + `AppServicesScope` (`InheritedWidget`), no DI package. A screen calls `AppServicesScope.of(context).xxx`. Keep using this pattern for every future screen.
- **Emulator mode needs its own named `FirebaseApp`, never `[DEFAULT]`, and its own demo project id.** This is not optional/simplifiable — see "Two real bugs" below. Any future refactor of `firebase_bootstrap.dart` must preserve both properties.
- `FirestoreInstitutionRepository.watchMyInstitutions` reads a denormalized `memberIndex` collection, not `memberships` directly, because of a Firestore Rules/emulator limitation with mixing collection-group and nested-exact rules on one collection name. **Nothing keeps `memberIndex` in sync automatically yet** — there is no membership-creation flow in the app (only `firestore-tests/seed_emulator.mjs` writes it, by hand, for manual QA). Whoever builds membership management (workstream A) must write both `memberships/{uid}` and `memberIndex/{uid}` — ideally in one `WriteBatch` — on create/disable/re-enable. Full details in `docs/FIREBASE_MODEL.md`.

## Two real bugs found only by live-testing on Android (read before repeating this class of mistake)

1. **`[core/duplicate-app]` crash on startup.** Cause: on Android, the native Firebase SDK auto-initializes `[DEFAULT]` from `google-services.json` (the real `i-crash-pt-2026` project) before Dart runs; calling `Firebase.initializeApp()` again for `[DEFAULT]` with different (demo) options throws, and since this happened before `runApp`, the whole app hung (Android reported it as an ANR, not a crash dialog, which was confusing to diagnose from logcat filters that don't include `AndroidRuntime`/`FATAL EXCEPTION`). Fix: named app `icrash-emulator` for emulator mode, `[DEFAULT]` untouched.
2. **Firestore Rules denied a `collectionGroup` query with "No matching allow statements" even though the exact same rules + data succeeded in `firestore-tests/rules.test.mjs`.** Cause: the Flutter app's Firebase project id (`i-crash-pt-2026`, from `firebase_options.dart`) never matched the emulator's configured project (`demo-icrash-v2`, from `.firebaserc`), even though `useFirestoreEmulator`/`useAuthEmulator` had redirected the network connection. `singleProjectMode` logs a warning about this ("Multiple projectIds are not recommended...") but does not actually make Rules evaluation work correctly across project ids — confirmed by a throwaway Node probe script (since deleted) that reproduced the denial with a mismatched project id and success with a matching one, using otherwise identical code. Fix: emulator mode's `FirebaseOptions` always uses `projectId: 'demo-icrash-v2'`.

**Lesson for future phases, already stated in the spec but worth restating**: a successful `flutter analyze`/`flutter test`/`flutter build` proves nothing about whether the app actually runs. Both of these bugs, plus the pre-existing `MainActivity` package bug, compiled cleanly and would have shipped silently without the mandatory live Android walkthrough.

## Firebase configuration status

Unchanged from the architecture-foundation sub-phase except for the `memberIndex` additions above. `firestore.rules`/`firestore.indexes.json` are still **not deployed** anywhere — only tested against the local emulator. Do not deploy without explicit user confirmation.

## Firestore collections already implemented (schema, not deployed data)

Same as before, plus `institutions/{id}/memberIndex/{uid}` (see `docs/FIREBASE_MODEL.md`, "Why `memberIndex` exists"). No membership-creation flow exists in the app yet — only the emulator seed script writes `memberships`/`memberIndex` docs, for manual QA.

## Domain models already implemented

Unchanged this sub-phase. See prior handoff / `docs/ARCHITECTURE.md`.

## Dependencies added/removed

None in the Flutter app (no `pubspec.yaml` change). No new dev-dependency for widget testing — fakes are hand-written (`test/fakes/fake_repositories.dart`), deliberately not introducing `mockito`/`mocktail`. `firestore-tests/` gained no new npm packages this sub-phase (it already had `firebase`/`@firebase/rules-unit-testing` from before).

## Migrations performed

None.

## Security rules status

22/22 passing locally (`firestore-tests/rules.test.mjs`). Still not deployed anywhere. Known gaps unchanged from the architecture-foundation handoff (offline-replay test, `platformAdmins` bootstrap, slot-geometry validation) — see prior AI_HANDOFF content in git history (`b2badfe`..`31705a9`) if needed, or `docs/FIREBASE_MODEL.md`.

## Tests already run

`flutter analyze` clean. `flutter test`: 19/19. `flutter build apk --debug`: passed. Firestore Rules tests: 22/22. Full live Android walkthrough: passed (login, institution selection, dashboard placeholder, legacy app access, sign-out) — see `docs/TEST_STATUS.md` for detail and the three bugs it caught.

## Android emulator tests already performed

This session, on `ICrash_API_36`: fresh install → login screen renders → validation errors on empty submit → successful sign-in with the seeded test account → institution list shows "Hospital de Teste" → tapping it opens the dashboard placeholder with the real institution name → "Abrir aplicação anterior" opens the legacy `HomeMenu` (Registration/QR Code Reader/Data matrix scan all still visible) → back navigation returns correctly. No fatal `pt.icrash.app` exceptions in logcat. Screenshots were taken at each step during the session (not committed to the repo — they lived in `%TEMP%`).

## Known bugs

None known to remain. The three found this session (MainActivity package, cleartext blocking, project-id mismatch) are fixed and verified live.

## Known platform limitations

Unchanged: physical-camera QR/GS1, iOS/macOS (cannot validate from Windows), Web/Windows not re-verified this sub-phase (re-check before relying on them).

## Open business decisions

Unchanged — see `docs/OPEN_DECISIONS.md`.

## Pending Git changes

At the time of writing, everything under "Exact files changed this session" is either committed or about to be committed — check `git log` / `git status` on `DEV-Pedro` for the actual state; the human-readable summary at the end of the assistant's turn names the actual commit hashes.

`firestore-tests/node_modules/` and any `probe*.mjs` scratch files are git-ignored/deleted — do not look for them, they were never committed.

## Exact commands needed to continue

```
cd "C:\Users\Pedro Jorge\Documents\projeto icrash\ICrash-git\03_Implementacao\app1"
flutter analyze --no-pub
flutter test --no-pub

cd "C:\Users\Pedro Jorge\Documents\projeto icrash\ICrash-git"
firebase emulators:exec --only firestore --project demo-icrash-v2 "npm --prefix firestore-tests test"
```

To manually try the app end-to-end:

```
cd "C:\Users\Pedro Jorge\Documents\projeto icrash\ICrash-git"
firebase emulators:start --only auth,firestore --project demo-icrash-v2
```

then, in another terminal: `npm --prefix firestore-tests run seed` (creates `enfermeira.teste@icrash.pt` / `icrash-teste-123` with an active `institutionAdmin` membership in "Hospital de Teste"), then `flutter run` from `03_Implementacao/app1` (debug mode already defaults to the emulator; on the Android emulator specifically, make sure `ICrash_API_36` is booted first).

## Exact next implementation task

Continue workstream A/B/C (spec item 5): build the next V2 screen(s) beyond the dashboard placeholder. Sensible next slice, in order:

1. **Membership management** (create/disable a member, assign a role) — this is the first thing that needs to write both `memberships` and `memberIndex` atomically (a `WriteBatch`), so it's also the natural place to add an `InstitutionRepository`/new small repository method for it (none exists yet — `InstitutionRepository` currently only has `createInstitution`).
2. **Cart list + cart creation** for an institution (uses the already-implemented `CartRepository`).
3. **Drawer/slot editor** (workstream B) — the domain model (`CartDrawer`, `Slot` with row/column/rowSpan/columnSpan) and `DrawerRepository` already exist; nothing in presentation consumes them yet.

Whichever is picked, follow the same pattern established here: repository already exists (check `lib/src/domain/repositories/` first), fakes go in `test/fakes/fake_repositories.dart`, screen goes in `lib/src/presentation/<area>/`, and — per the spec's own mandatory rule — validate live on the Android emulator before calling it done, not just `flutter analyze`/`flutter test`.

## Temporary workarounds

- `FirestoreInventoryRepository.reconcileAfterAudit` still uses a plain `WriteBatch` for the batch-collection replacement rather than one atomic transaction spanning batches+assignment (unchanged from the architecture-foundation handoff; noted again here since it's the same category of "not fully atomic" concern as the new `memberships`/`memberIndex` dual-write need).
- No membership-creation UI exists; `memberIndex` is currently kept in sync only by `firestore-tests/seed_emulator.mjs` for manual QA. Do not build a screen that writes `memberships` without also writing `memberIndex`.

## Things that must NOT be redone

Everything from the Phase 1 handoff still applies: do not initialize another repository, develop on or push to `main`, restore Django (its manifest was only security-patched, not the code — do not start running/testing it), discard the backup, recreate Firebase without location approval, repeat the SDK modernization, commit secrets/build caches, or claim iOS/macOS validation from Windows.

Additionally: do not re-derive the conservative-expiry logic inline (`InventoryRules` only). Do not deploy `firestore.rules`/`firestore.indexes.json` to the cloud project without explicit user confirmation. Do not "simplify" `firebase_bootstrap.dart` back to a single `[DEFAULT]` app or the real project id in emulator mode — both bugs described above will come straight back. Do not open a PR from `DEV-Pedro` to `main` for the Django dependency fix — the user was asked and explicitly chose to leave it as-is for now.

## Environment

- Flutter: `C:\Flutter\stable\bin\flutter.bat`
- Git: `C:\Program Files\Git\cmd\git.exe`
- Node: v22.15.0, npm: 11.3.0 (used only by `firestore-tests/`)
- Python: 3.10.11, with `pipenv` available (installed into a throwaway venv this session, cleaned up after — reinstall with `pip install pipenv` into a fresh venv if `Pipfile.lock` ever needs regenerating again)
- Android SDK: `C:\Android\Sdk`
- Emulator: `ICrash_API_36` / usually `emulator-5554`
- Required Java workaround: `JDK_JAVA_OPTIONS=-Djdk.net.unixdomain.tmpdir=C:/Flutter/socket-temp`
- Firebase CLI: `C:\Users\Pedro Jorge\AppData\Roaming\npm\firebase.cmd` (15.29.0)
- FlutterFire CLI: `C:\Users\Pedro Jorge\AppData\Local\Pub\Cache\bin\flutterfire.bat` (1.4.1)

Firebase CLI is authenticated. `.firebaserc` keeps `demo-icrash-v2` as the safe local default and names the cloud project `development` (`i-crash-pt-2026`). Firebase Core is initialized via `bootstrapFirebase()` in `lib/main.dart`, which as of this session returns a `FirebaseServices` rather than being a bare side-effecting call — see "Architecture decisions" above.
