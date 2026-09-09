# Architecture

Status: login → institution selection → per-institution cart list/creation → member management live and validated on the Android emulator; legacy app still reachable from there. Everything else in the legacy app (grids, registration, request handler) is untouched and still compiles; it will be replaced flow by flow in later phases.

Existing app: legacy Flutter screens and HTTP `RequestHandler` targeting the old Django endpoint remain in place under `lib/` (`grids/`, `registration/`, `request_handler/`, `qr_code_reader/`, `updates/`). `HomeMenu` is no longer the app's entry point, but it is still reachable — see "Presentation" below.

## V2 layers (`lib/src/`)

```
presentation/
  auth/login_screen.dart
  institution/institution_selection_screen.dart
  dashboard/institution_home_screen.dart      per-institution home: cart list + creation
  cart/cart_detail_screen.dart                placeholder until drawers/slots exist
  cart/cart_status_label.dart, create_cart_dialog.dart
  members/members_screen.dart                 institution-admin-only: list/create/role/status
  members/add_member_dialog.dart, membership_labels.dart
        ↑
domain/
  entities/        plain Dart classes, fromMap/toMap only, no Firebase imports
  repositories/    abstract interfaces (AuthRepository, InstitutionRepository,
                   CartRepository, DrawerRepository, ProductRepository,
                   InventoryRepository, UsageRepository, AuditRepository)
  inventory_rules.dart   pure functions for the conservative-expiry/no-FEFO
                         rule, unit-tested without Firebase
        ↑
data/firebase/     Firestore/Auth implementations of every repository interface,
                   Firestore path constants, timestamp codec, exception mapping,
                   emulator bootstrap
services/          ScannerService (internal QR + GS1 Data Matrix, separate
                   interfaces), ReportService, NotificationService — contracts
                   only, no implementation yet
common/            AppEnvironment (emulator vs cloud selection), AppServices
                   (repository bundle + InheritedWidget), RepositoryFailure
```

The domain layer imports nothing from `cloud_firestore`/`firebase_auth`/`firebase_core`. `lib/src/domain/inventory_rules.dart` is proof of this: it is exercised directly in `test/domain/inventory_rules_test.dart` with no emulator running.

`lib/src/data/firebase/*` is the only place that imports Firebase packages. Firestore documents are converted to/from domain entities there; `Timestamp` never leaks past this layer (`firestore_codec.dart` converts it to a plain `DateTime` before entities see it).

## Presentation and dependency wiring

No dependency-injection framework was introduced. `AppServices` (`lib/src/common/app_services.dart`) is a plain class holding one instance of every repository; `lib/main.dart` constructs it once from `bootstrapFirebase()`'s result and hands it down via `AppServicesScope`, an `InheritedWidget`. A screen reads what it needs with `AppServicesScope.of(context).auth` etc. `AppServices.withRepositories(...)` is a second constructor that takes every repository directly (used by widget tests to inject fakes without touching Firebase — see `test/fakes/fake_repositories.dart`).

`lib/main.dart`'s `_AuthGate` widget listens to `AuthRepository.authStateChanges()` and shows `LoginScreen` when signed out, `InstitutionSelectionScreen` when signed in. Selecting an institution pushes `InstitutionHomeScreen`, which lists that institution's carts (`CartRepository.watchAccessibleCarts`) and — for a manager/institutionAdmin/platformSuperAdmin, checked once via `InstitutionRepository.getMyMembership` — shows a "Novo carro" FAB. Tapping a cart opens `CartDetailScreen`, a placeholder until drawers/slots/stock exist (workstreams B/C/E/F). Per the "preserve existing functionality" rule, `InstitutionHomeScreen` also has a button that opens the legacy `HomeMenu` unmodified. Nothing in the new screens calls the legacy `RequestHandler`.

The FAB visibility check is a UX nicety, not the security boundary — `firestore.rules` independently enforces that only manager+ can `create`/`update` a cart (spec section 18: never rely on hiding a button). If `createCart` is ever called by someone Rules reject, it fails with a `RepositoryFailure` shown in a `SnackBar`.

`InstitutionHomeScreen` also has a "Membros" `AppBar` icon, shown only for an institution admin/platform super admin (a stricter check than the cart FAB's manager-or-above), opening `MembersScreen`. It lists every membership (`InstitutionRepository.watchMembers`), lets the admin change a member's role or toggle active/disabled, and creates brand-new members via a "Novo membro" dialog. There is still no Cloud Function to invite an existing user by e-mail alone (Phase 1 has none), so `createMember` always provisions a fresh Firebase Auth account for the given e-mail/temporary-password, then writes `memberships`/`memberIndex` in one `WriteBatch` — see "Isolated account creation" below for how the new account is created without signing the admin out of their own session. As with carts, `firestore.rules` is the real boundary (`isInstitutionAdmin`, not just `isManagerOrAbove`, gates `memberships`/`memberIndex` writes); the UI gating only avoids showing controls that would fail.

## Environment selection

`lib/src/common/app_environment.dart` decides Auth/Firestore emulator vs cloud:

- Debug builds default to the **emulator** (127.0.0.1, or 10.0.2.2 from the Android emulator) so development can never write to the cloud project `i-crash-pt-2026` by accident.
- Release builds default to **cloud**, since a shipped app has no emulator to reach.
- Either can be forced with `--dart-define=ICRASH_BACKEND=emulator` or `--dart-define=ICRASH_BACKEND=cloud`.

`lib/src/data/firebase/firebase_bootstrap.dart` implements this, and returns a `FirebaseServices` (the `FirebaseAuth`/`FirebaseFirestore` instances `AppServices` should use) rather than assuming the bare `.instance` singletons are always right. That indirection exists because of two platform issues found while validating this phase on the Android emulator — both are load-bearing, do not simplify this away:

1. **Emulator mode uses a second, separately-named `FirebaseApp`** (`icrash-emulator`), never `[DEFAULT]`. On Android (and iOS/macOS), the native Firebase SDK auto-initializes `[DEFAULT]` from `google-services.json`/`GoogleService-Info.plist` — the real `i-crash-pt-2026` project — before any Dart code runs. Calling `Firebase.initializeApp()` again for `[DEFAULT]` with different (demo-project) options throws `[core/duplicate-app]`, which crashed the app on startup (an ANR, since the thrown exception happened before `runApp`). The fix keeps `[DEFAULT]` pointed at the real project (harmless — nothing in emulator mode uses it) and creates a named app with `projectId: 'demo-icrash-v2'` for actual use.
2. **Emulator mode must use a project id that matches `.firebaserc`/`firebase.json` (`demo-icrash-v2`)**, not the real project id. Pointing `useFirestoreEmulator`/`useAuthEmulator` at the emulator's host/port is not enough by itself — the SDK still tags every request with whatever project id its `FirebaseOptions` declared. Confirmed empirically: a `collectionGroup` query against the emulator was denied with "No matching allow statements" under the real project id, and succeeded immediately under the matching demo id, using the exact same rules and data. `firebase.json`'s `singleProjectMode` does not paper over this for rules evaluation.

### Isolated account creation

`createIsolatedAccountCreationAuth()` in `firebase_bootstrap.dart` extends the same named-`FirebaseApp` pattern to a different problem: `FirebaseAuth.createUserWithEmailAndPassword` signs in as the newly created user on whichever `FirebaseAuth` instance it is called on, which would otherwise sign the admin out of their own session the moment they add a member. It initializes a throwaway app with a timestamp-suffixed unique name (so creating several members in one session never collides with `[core/duplicate-app]`), pointed at the same backend (emulator or cloud) `AppEnvironment` already selects, gets a `FirebaseAuth` from it, and the caller (`FirestoreInstitutionRepository.createMember`) deletes that app immediately after reading the new user's uid. The admin's own `FirebaseAuth`/`FirebaseFirestore` instances are never touched. This exists only because Phase 1 has no Cloud Functions to create the account server-side instead — replace this with a callable Function if/when one is introduced.

## What is intentionally not built yet

- Everything in workstreams A-D beyond login/institution-selection/cart list+creation/member management: no drawer/slot/product/assignment screens, no cart edit/duplicate/template.
- No dependency injection / service locator beyond `AppServicesScope`.
- `ScannerService`/`ReportService`/`NotificationService` are contracts only.
- Offline-state UI (synced/pending/failed) is not built; Firestore's own offline cache is unconfigured beyond its native platform default.
- Localization: screens currently hard-code PT-PT strings; `flutter_localizations`/`.arb` scaffolding is deferred to spec item 8.

See `ICRASH_V2_SPECIFICATION.md` for authoritative scope and dependency order, and `docs/FIREBASE_MODEL.md` for the Firestore collection layout and the conservative-expiry rule those repositories implement.
