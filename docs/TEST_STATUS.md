# Test status

Updated: 2026-09-09

## Phase 2, drawer/slot editor — Android emulator live validation

Full walkthrough on `ICrash_API_36`, against local emulators seeded via `firestore-tests/seed_emulator.mjs`, signed in as the seeded `institutionAdmin`:

- Cart detail screen: WORKING. Replaced the old placeholder; shows the cart's drawers (empty state when none exist) and, for a manager+, a "Nova gaveta" FAB.
- Drawer creation: WORKING. Dialog collects a name and rows/columns (1-12 each, mirroring the legacy `UpdateDrawerShape` screen's range); created "GavetaPrincipal" (3 rows × 2 columns after a dropdown-interaction quirk — see bug note below) and it appeared in the list immediately via the Firestore stream.
- Slot editor: WORKING. Opening a drawer with no saved slots renders one unit cell per grid position (`row+1,column+1` labels). Selecting two cells that form a rectangle and tapping "Juntar" merges them into one bigger slot spanning the full width; "Dividir" on a merged slot correctly restores the original unit cells. "Guardar" persists the full slot set via `DrawerRepository.replaceSlots`, confirmed with a "Gaveta guardada." snackbar; leaving and reopening the drawer reloads the merged layout from Firestore correctly.
- No fatal `pt.icrash.app` exceptions in logcat.

One real usability quirk found live, not a code bug: **Android's stylus-handwriting tutorial overlay ("Try out your stylus") intercepted a tap meant for a dialog's Cancel button** on this AVD image (it has a stylus input registered), consuming the tap as a handwriting gesture instead of dismissing the dialog. Not an app issue — worked around for this session with `adb shell settings put secure stylus_handwriting_enabled 0`; unrelated to anything shipped.

## Phase 2, membership management — Android emulator live validation

Full walkthrough on `ICrash_API_36`, against local emulators seeded via `firestore-tests/seed_emulator.mjs`, signed in as the seeded `institutionAdmin`:

- Members screen: WORKING. Reachable via a new "Membros" `AppBar` icon on the institution home screen, shown only for an institution admin/platform super admin (verified a manager does not see it, in `institution_home_screen_test.dart`). Lists the signed-in admin's own membership with no action menu on their own row (self-escalation is blocked by Rules, but the menu is also hidden for clarity).
- Member creation: WORKING. "Novo membro" dialog (e-mail, temporary password, role) creates a brand-new Firebase Auth account and its `memberships`/`memberIndex` docs in one `WriteBatch`, without signing the admin out of their own session — confirmed live: the admin stayed on the members list, watching the new member appear instantly via the Firestore stream, immediately after submitting the dialog.
- Role change: WORKING. "Mudar cargo" on a member's row opens a role picker; selecting a new role updates the list live.
- Enable/disable: WORKING. "Desativar"/"Reativar" toggles `memberships.status` and `memberIndex.status` together; the status chip updates live.
- No fatal `pt.icrash.app` exceptions in logcat during the whole walkthrough.

No new Firestore Rules were needed — `memberships`/`memberIndex` `create`/`update` were already institution-admin-scoped from the architecture-foundation phase; this phase only added the app code that exercises them (previously only `firestore-tests/seed_emulator.mjs` did).

## Phase 2, cart list and creation — Android emulator live validation

Full walkthrough on `ICrash_API_36`, against local emulators freshly seeded via `firestore-tests/seed_emulator.mjs` (emulator data does not persist across restarts; a stale cached Auth session from a prior emulator run showed "Ainda não tem acesso a nenhuma instituição" until signing out and back in — expected, not a bug: the cached uid no longer existed in the fresh emulator instance):

- Institution home screen: WORKING. Cart list shows the seeded "Carro de Emergência 1" / "Operacional" from `CartRepository.watchAccessibleCarts`; "Novo carro" FAB visible (seeded user is `institutionAdmin`).
- Cart creation: WORKING. Dialog validates empty input (covered by widget test), creating "Carro2" closed the dialog and the list updated live via the Firestore snapshot stream — no manual refresh, no navigation round-trip.
- Cart detail: WORKING. Shows name, status chip, and the drawers/stock placeholder message.
- Legacy app access: WORKING, moved to an AppBar icon (history icon, tooltip "Aplicação anterior (referência)") — see the bug note below for why.
- No fatal `pt.icrash.app` exceptions in logcat.

One real bug found by this live run, before any code shipped with it:

- **FAB/legacy-button overlap**: the initial layout put "Abrir aplicação anterior (referência)" in a bottom bar, which the default-positioned `FloatingActionButton.extended` ("Novo carro") visually overlapped on a real device — not visible in the widget tests, which don't check for accessible tap targets/paint overlap. Fixed by moving legacy-app access to an `AppBar` icon button instead of a bottom bar, which also happens to read cleaner. Re-verified live after the fix (screenshot comparison, not just re-running widget tests).

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
- `flutter test --no-pub`: passed, 38 tests — `test/domain/inventory_rules_test.dart` (11, including the two literal critical inventory scenarios from spec sections 58 and 59), `test/widget_test.dart` (legacy `HomeMenu` smoke test, now pumped directly rather than via `MyApp` since `MyApp` requires a real Firebase app), and presentation-layer suites using fakes from `test/fakes/fake_repositories.dart`: `login_screen_test.dart` (3), `institution_selection_screen_test.dart` (3), `institution_home_screen_test.dart` (7, cart list/empty-state/creation/role-gated FAB/Membros-icon-gating/legacy access), `members_screen_test.dart` (5, empty state/list/create/self-row-hides-menu/disable), `cart_detail_screen_test.dart` (4, empty state/drawer list/role-gated creation), `slot_editor_screen_test.dart` (4, unit grid render/merge/split/view-only-for-normal-user).
- `flutter build apk --debug --no-pub`: passed, confirming the Firebase bootstrap (emulator-by-default in debug, cloud in release) compiles end to end on Android.
- `firebase emulators:exec --only firestore --project demo-icrash-v2 "npm --prefix firestore-tests test"`: passed, 22/22 Firestore Rules tests — spec section 60's security scenarios plus the `memberIndex` collection-group query (own-institution read, cross-user denial, admin-only writes).
- Full Android emulator live walkthrough of the new screens: see the sections above.
- Web/Windows builds were not re-run this phase (no code path affecting those platforms changed beyond `bootstrapFirebase()`/`AppServices`/the new screens, already exercised via `flutter analyze`/`flutter test`); re-verify before the next release-oriented milestone.

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
