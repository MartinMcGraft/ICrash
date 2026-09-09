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

## Phase 2 — Architecture, Firestore model, security rules

Status: foundation complete (items 1-4 of the phase); UI replacement (item 5 / workstreams A-D) not started.

- Layered architecture created under `03_Implementacao/app1/lib/src/`: `domain/entities`, `domain/repositories` (interfaces only, no Firebase import), `domain/inventory_rules.dart` (pure conservative-expiry logic), `data/firebase/*` (Firestore/Auth implementations), `services/*` (ScannerService/ReportService/NotificationService contracts), `common/*` (`AppEnvironment`, `RepositoryFailure`).
- `lib/main.dart` now calls `bootstrapFirebase()` instead of initializing Firebase directly; it selects the local emulator by default in debug builds and the cloud project in release builds, overridable with `--dart-define=ICRASH_BACKEND=emulator|cloud`. Legacy screens (`HomeMenu`, `grids/*`, `registration/*`, `request_handler/*`) are untouched and still the app's actual UI.
- Firestore collection model implemented per `docs/FIREBASE_MODEL.md`: `platformAdmins`, `institutions/{id}` with `memberships`, `products`, `carts` (with `responsibleUsers`, `drawers/slots`, `assignments/batches`), plus institution-level `usageEvents` and `auditEvents`.
- `firestore.rules` rewritten from deny-all to institution/role-scoped rules: membership + active-status checks, manager/admin/platform-super-admin role gates, explicit per-cart `responsibleUsers` access, field-level write scoping on `assignments` (a non-manager assigned user may change only `currentQuantity`), and immutable (`create`-only) `usageEvents`/`auditEvents`.
- `firestore.indexes.json` gained the two composite indexes those queries need in production: a `COLLECTION_GROUP` index on the member-lookup collection (`uid`, `status`) and a `COLLECTION` index on `usageEvents` (`assignmentId`, `serverTimestamp desc`). (The member-lookup collection was renamed `memberships` → `memberIndex` later the same day — see "Phase 2 continued" below.)
- New automated tests: `03_Implementacao/app1/test/domain/inventory_rules_test.dart` (11 tests, includes the two literal spec section 58/59 scenarios) and `firestore-tests/rules.test.mjs` (18 tests at the time, since grown to 22 — see below) against the local emulator, covering spec section 60's security scenarios. Both pass; see `docs/TEST_STATUS.md`.
- `flutter analyze`, `flutter test` and `flutter build apk --debug` all pass with the new code.

## Phase 2 continued — V2 login/institution-selection slice

Status: first presentation-layer slice complete and validated live on the Android emulator (spec item 5, partial).

- New screens: `lib/src/presentation/auth/login_screen.dart`, `institution/institution_selection_screen.dart`, `dashboard/dashboard_placeholder_screen.dart` (stands in for the real dashboard; opens the untouched legacy `HomeMenu` via a button).
- `lib/src/common/app_services.dart`: `AppServices` (repository bundle) + `AppServicesScope` (`InheritedWidget`) — the dependency-wiring decision `AI_HANDOFF.md` had previously left open.
- `lib/main.dart` rewritten: `_AuthGate` routes between `LoginScreen`/`InstitutionSelectionScreen` based on `AuthRepository.authStateChanges()`.
- `FirestoreInstitutionRepository.watchMyInstitutions` now queries a new `memberIndex` collection group instead of `memberships` directly — required by a Firestore Rules/emulator limitation discovered while validating this live; see `docs/FIREBASE_MODEL.md`.
- `firebase_bootstrap.dart` rewritten to return `FirebaseServices` (an explicit `FirebaseAuth`/`FirebaseFirestore` pair) and, in emulator mode, to initialize a separate named `FirebaseApp` with the demo project id rather than reusing `[DEFAULT]` — two real Android bugs (`[core/duplicate-app]` crash, and Firestore Rules being denied under a mismatched project id) forced this; see `docs/ARCHITECTURE.md`.
- Fixed a **pre-existing Phase 1 bug**, found only by this session's live Android run: `android/app/src/main/kotlin/com/example/app1/MainActivity.kt` still had the pre-rename package, causing every launch to crash with `ClassNotFoundException`. Moved to `android/app/src/main/kotlin/pt/icrash/app/MainActivity.kt` with the corrected `package pt.icrash.app` declaration.
- Added `android/app/src/debug/res/xml/network_security_config.xml` (debug-only) to allow the cleartext HTTP the Firebase emulators use; release builds are unaffected.
- `firestore.rules`/`firestore.indexes.json` updated for the `memberIndex` collection (see `docs/FIREBASE_MODEL.md`); `firestore-tests/rules.test.mjs` gained 4 tests (22 total) and `firestore-tests/seed_emulator.mjs` now seeds `memberIndex` alongside `memberships`.
- New widget tests using hand-written fakes (`test/fakes/fake_repositories.dart`, no mocking framework added): `login_screen_test.dart`, `institution_selection_screen_test.dart`, `dashboard_placeholder_screen_test.dart`. The pre-existing `widget_test.dart` now pumps `HomeMenu` directly instead of via `MyApp`, since `MyApp` requires a real Firebase app.
- Full live validation on Android emulator `ICrash_API_36`: login → institution selection → dashboard placeholder → legacy `HomeMenu` (and back), sign-out. See `docs/TEST_STATUS.md` for the detailed walkthrough and the three bugs this run caught.

## Phase 2 continued — cart list and creation

Status: complete and validated live on the Android emulator.

- `lib/src/presentation/dashboard/dashboard_placeholder_screen.dart` replaced by `dashboard/institution_home_screen.dart`: real cart list per institution (`CartRepository.watchAccessibleCarts`), a "Novo carro" FAB shown only for manager/institutionAdmin/platformSuperAdmin (checked via `InstitutionRepository.getMyMembership`), and the legacy-app button kept.
- New `lib/src/presentation/cart/`: `cart_detail_screen.dart` (placeholder — name/status only, until drawers/slots exist), `cart_status_label.dart` (PT-PT `CartStatus` labels), `create_cart_dialog.dart` (name-only creation dialog).
- No repository/domain/Rules changes were needed — `CartRepository`, `Cart`, and the `carts` Firestore Rules were already complete from the architecture-foundation phase.
- Fakes extended: `FakeCartRepository` now has real in-memory behavior (`watchAccessibleCarts`, `createCart`) instead of being an unimplemented stub; `FakeInstitutionRepository.getMyMembership` added. Both still hand-written, no mocking package.
- New/renamed tests: `institution_home_screen_test.dart` (5 tests: empty state, list+navigate to detail, FAB shown for manager + creates a cart, FAB hidden for a normal user, legacy app still reachable); `institution_selection_screen_test.dart` updated for the rename.
- Live Android validation: seeded institution already had one cart from `seed_emulator.mjs`; the list rendered it correctly, "Novo carro" was visible (seeded user is `institutionAdmin`), and creating a cart updated the list live via the Firestore snapshot stream. See `docs/TEST_STATUS.md`.

Not started: everything else in workstreams A-D (drawer/slot/product/assignment screens, membership-management UI — there is currently no in-app way to create a membership, cart edit/duplicate/template), offline-state UI, ScannerService/ReportService/NotificationService implementations, the real dashboard (alerts/expiry/audit summary), reports, localization scaffolding, and everything downstream of them.

See `MODERNIZATION_2026.md` for the baseline modernization and `ICRASH_V2_SPECIFICATION.md` for the authoritative V2 scope.
