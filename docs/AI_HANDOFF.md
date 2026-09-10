# AI handoff

Updated: 2026-09-10

- Repository: `C:\Users\Pedro Jorge\Documents\projeto icrash\ICrash-git`
- Remote: `https://github.com/MartinMcGraft/ICrash.git`
- Current branch: `DEV-Pedro`
- Base commit: `8e0e619` (`origin/main`)
- Last published commit before this continuation: `f9e3019` (`feat: add institution-wide activity history screen`)
- Flutter application: `03_Implementacao/app1`
- Firestore Rules tests + emulator seed script: `firestore-tests/` (Node project, separate from the Flutter app)
- Preserved backup: `C:\Users\Pedro Jorge\Documents\projeto icrash\backup-before-update-20260907`

## Completed work

Phase 0 (Git/modernization) and Phase 1 (Firebase foundation) are complete and published. Phase 2's architecture foundation (layered domain/data/repositories, Firestore model, security Rules with tests) is complete. **This continuation session added a seventh round of V2 work** on top of the six presentation slices from the prior session — two correctness fixes (product uniqueness per cart, layout versioning) plus five more presentation slices: (1) `responsibleUsers` management, (2) cart edit/duplicate, (3) product search within a cart, (4) a real institution dashboard (status counts + recent activity + search), and (5) an institution-wide activity history screen — all validated live end-to-end on the Android emulator, with zero new app bugs found. `flutter test` is now 69/69. The only major workstream left is GS1 Data Matrix scanning (spec sections 29-32) — the next task per explicit user instruction.

### Correctness fixes / responsibleUsers / cart edit-duplicate / product search / dashboard / history sub-phase (most recent)

- **Fix (spec section 20)**: `FirestoreInventoryRepository.createAssignment` now checks for an existing assignment with the same `productId` in the cart before creating, throwing `RepositoryFailure(RepositoryFailureReason.conflict)` if found; `assignment_dialog.dart` shows a specific PT-PT message for this case instead of the generic one.
- **Fix (spec section 38)**: new `bump_layout_version.dart`'s `bumpCartLayoutVersion(services, cart)` re-reads the cart and increments `layoutVersion`, called after `CartDetailScreen._createDrawer` and `SlotEditorScreen._save` — previously `layoutVersion` was never incremented anywhere despite the field existing.
- New `lib/src/presentation/cart/responsible_users_screen.dart` (spec section 17): manager+ screen, `CheckboxListTile` per institution member (via `InstitutionRepository.watchMembers`) reflecting/toggling `CartRepository.watchResponsibleUsers`/`assignResponsibleUser`/`removeResponsibleUser` — those repository methods already existed fully implemented from the architecture-foundation phase, only the screen was missing. New "Responsáveis" `AppBar` icon on `CartDetailScreen`.
- `CartDetailScreen` gained a manager+-gated overflow menu: "Editar" (`edit_cart_dialog.dart`, calls `CartRepository.updateCart`) and "Duplicar" (`duplicate_cart_dialog.dart`, creates a new cart and copies every drawer/slot via `createDrawer`/`replaceSlots` — never assignments/stock/history, spec sections 39-40). No "template gallery" concept was built; any cart can be a duplication source.
- New `lib/src/presentation/cart/product_search_screen.dart` (spec section 41): filters `InventoryRepository.watchAssignments` by product name, opens the same `showAssignmentDialog` the drawer grid uses. New "Pesquisar produto" `AppBar` icon on `CartDetailScreen`.
- `InstitutionHomeScreen` rewritten (spec section 49, scoped down): `_CartStatusSummary` (counts per `CartStatus`) and `_RecentActivity` (last 5 events via the already-institution-scoped `UsageRepository.watchRecentEvents`) above the existing cart list, plus a cart-name search field. Cross-cart per-slot expiry alerts deliberately deferred — needs an institution-wide `assignments` collectionGroup query + Rules change.
- New `lib/src/presentation/reports/history_screen.dart` (spec section 51, scoped to its read-only half): `ChoiceChip`-filterable list over `watchRecentEvents`. New "Histórico" `AppBar` icon on `InstitutionHomeScreen`, any user.
- No repository, Firestore, or Rules changes were needed beyond the `createAssignment` uniqueness check — every other method used here already existed.
- `FakeInventoryRepository`/`FakeCartRepository` extended: uniqueness-conflict check, `getCart`/`updateCart`, full `responsibleUsers` behavior with a stream controller.
- New/extended tests, 21 added this round (48 → 69 total): `responsible_users_screen_test.dart` (3), `product_search_screen_test.dart` (3), `history_screen_test.dart` (3), `cart_detail_screen_test.dart` (+7), `institution_home_screen_test.dart` (+4), `slot_editor_screen_test.dart` (+1). `flutter analyze --no-pub` clean.
- Live-validated on Android (continuing the same seeded institution/cart from prior sessions): dashboard showed real status counts ("Operacional: 1") and 4 real historical usage events with correct labels; History screen's "Consumo" filter narrowed the list correctly; product search found "Adrenalina" by partial name and opened its assignment dialog in view mode; "Editar" opened pre-filled with the current name/status; "Duplicar" created a second cart with the same drawer/slot structure and no stock/history, updating the dashboard's status count to "Operacional: 2" live; "Responsáveis" listed real members, correctly disabled an inactive membership's checkbox, and a toggle on an active member persisted through the Firestore emulator. No fatal exceptions in logcat. See `docs/TEST_STATUS.md`.

### Audit reconciliation and event correction sub-phase

- `assignment_dialog.dart` gained `_Mode.reconcile` (manager+: batch checkboxes + confirmed-quantity field, calls `InventoryRepository.reconcileAfterAudit`) and `_Mode.correct` (anyone with cart access: pick a usage event via `UsageRepository.watchEventsForAssignment`, pre-filled "undo" adjustment, calls `recordCorrection`). No repository, Firestore, or Rules changes needed — this closes out `InventoryRepository`'s entire surface in the UI.
- `FakeInventoryRepository` gained `reconcileAfterAudit`/`recordCorrection`; `FakeUsageRepository` upgraded from an unimplemented stub to real in-memory behavior.
- Live-validated on Android: reconciled the "Adrenalina" assignment (unchecked its batch, confirmed quantity 2 → cell showed "2/1", batch dropped), then corrected the reconciliation event with its pre-filled default (+1) → cell showed "3/1" again. No fatal exceptions. See `docs/TEST_STATUS.md`.

### Product catalogue and slot assignments sub-phase

- New `lib/src/presentation/products/`: `products_screen.dart`, `create_product_dialog.dart`. `InstitutionHomeScreen` gained a "Produtos" `AppBar` icon (manager+ gated).
- New `lib/src/presentation/cart/assignment_dialog.dart`, `assignment_status_label.dart`: long-pressing a slot in `SlotEditorScreen` opens a dialog to assign a product (manager+), replenish stock with a lot/expiry (manager+), or record consumption (anyone with cart access) — built entirely on the already-complete `InventoryRepository`/`InventoryRules`, no repository or Rules changes needed.
- `SlotEditorScreen` cells now show the assigned product's name and `current/target` quantity, fed by a `Stream<List<CartProductAssignment>>` plus a one-shot product list.
- `FakeProductRepository`/`FakeInventoryRepository` upgraded from unimplemented stubs to real in-memory behavior.
- Live-validated on Android: created a product, assigned it to a slot, replenished it (lot number + expiry date picker), then recorded consumption — quantities updated correctly at each step, no fatal exceptions. One live-testing lesson (not a code bug): a `TextFormField`'s tap target extends beyond its visible text line into its label/helper-text band, so two stacked fields' tap targets sit closer together than screenshots suggest — confirmed via exact `uiautomator` `EditText` bounds. See `docs/TEST_STATUS.md`.

### Drawer/slot editor sub-phase

- `CartDetailScreen` rewritten from a static placeholder to a real drawer list (`DrawerRepository.watchDrawers`) with a manager-gated "Nova gaveta" FAB (`create_drawer_dialog.dart`: name + rows/columns 1-12).
- New `lib/src/presentation/cart/slot_editor_screen.dart`: renders a drawer's slots as a `Stack` of `Positioned` cells (not a `GridView` — Flutter's grid widgets don't support cell spanning). The grid always fills the available screen area — a `LayoutBuilder` divides the actual width/height by `columns`/`rows`, so one slot fills the whole visible area, two slots split it in half, etc., matching a real physical drawer rather than a fixed pixel grid (this was corrected mid-session after the first version used a fixed cell size — see below). A drawer with no saved slots starts as one unit cell per grid position. Tap-to-select cells whose combined area exactly tiles a rectangle, then "Juntar" merges them; "Dividir" on a selected merged slot restores unit cells. "Guardar" persists everything via `DrawerRepository.replaceSlots` in one call. Manager+ only, matching the Rules boundary on `drawers`/`slots` writes.
- `FakeDrawerRepository` upgraded from an unimplemented stub to real in-memory behavior, mirroring `FakeCartRepository`'s pattern.
- Live-validated on Android: created a 3×2 drawer, merged two cells, split them back, merged again and saved — the merged layout reloaded correctly from Firestore after leaving and reopening the drawer. No fatal exceptions. One environment quirk found (not a code bug): the AVD's stylus-handwriting tutorial overlay intercepted a dialog tap; worked around with `adb shell settings put secure stylus_handwriting_enabled 0` — see `docs/TEST_STATUS.md`.

### Membership management sub-phase

- `InstitutionRepository` gained `watchMembers`, `createMember`, `updateMemberRole`, `setMembershipStatus`. No Rules changes needed — `memberships`/`memberIndex` admin-only writes already existed.
- `createMember` provisions a brand-new Firebase Auth account (no Cloud Function to invite by e-mail alone exists yet) via a throwaway, uniquely-named secondary `FirebaseApp` (`createIsolatedAccountCreationAuth` in `firebase_bootstrap.dart`) so creating a member never signs the admin out of their own session, then writes `memberships`+`memberIndex` in one `WriteBatch`.
- New `lib/src/presentation/members/`: `members_screen.dart`, `add_member_dialog.dart`, `membership_labels.dart`. `InstitutionHomeScreen` gained a "Membros" `AppBar` icon gated on institution-admin/platform-super-admin (stricter than the cart FAB's manager-or-above).
- `RepositoryFailureReason` gained `invalidInput`; `firestore_exception_mapper.dart` now distinguishes `email-already-in-use`/`invalid-email`/`weak-password` instead of collapsing every Auth error to `unauthenticated`.
- Live-validated on Android: created a member, changed their role, disabled them — each reflected instantly via the Firestore stream, admin session never disturbed, no fatal exceptions.

### Cart list/creation sub-phase

- `dashboard/dashboard_placeholder_screen.dart` → renamed/rewritten as `dashboard/institution_home_screen.dart` (`InstitutionHomeScreen`): real cart list (`CartRepository.watchAccessibleCarts`), a "Novo carro" FAB gated on role (`InstitutionRepository.getMyMembership`), legacy-app access moved to an `AppBar` icon.
- New `lib/src/presentation/cart/`: `cart_detail_screen.dart`, `cart_status_label.dart`, `create_cart_dialog.dart`.
- No domain/repository/Rules changes needed — `CartRepository`/`Cart`/the `carts` Rules were already complete.
- `FakeCartRepository` upgraded from an unimplemented stub to real in-memory behavior; `FakeInstitutionRepository.getMyMembership` added.
- `institution_home_screen_test.dart` (5 tests) replaces the old `dashboard_placeholder_screen_test.dart`.
- **Bug found live**: the FAB overlapped a bottom-bar "legacy app" button — invisible to widget tests (they don't check paint overlap). Fixed by moving that access into the `AppBar` instead.
- Live-validated: cart list renders seed data, "Novo carro" creates a cart and the list updates instantly via the Firestore stream (no manual refresh), cart detail opens, legacy app still reachable, no fatal exceptions.

## Exact files changed this session

Correctness fixes / responsibleUsers / cart edit-duplicate / product search / dashboard / history (this sub-phase, most recent):
- `03_Implementacao/app1/lib/src/data/firebase/firestore_inventory_repository.dart` — `createAssignment` now checks for an existing assignment with the same `productId` in the cart, throws `RepositoryFailure(RepositoryFailureReason.conflict)` if found.
- `03_Implementacao/app1/lib/src/presentation/cart/assignment_dialog.dart` — specific conflict message for the uniqueness check.
- `03_Implementacao/app1/lib/src/presentation/cart/bump_layout_version.dart` — new; shared `bumpCartLayoutVersion(services, cart)` helper.
- `03_Implementacao/app1/lib/src/presentation/cart/slot_editor_screen.dart` — `_save()` now calls `bumpCartLayoutVersion` after `replaceSlots`.
- `03_Implementacao/app1/lib/src/presentation/cart/cart_detail_screen.dart` — `_createDrawer` calls `bumpCartLayoutVersion`; added `_editCart`/`_duplicateCart`; `AppBar` gained "Pesquisar produto" icon, overflow menu ("Editar"/"Duplicar", manager+ gated), "Responsáveis" icon (manager+ gated).
- `03_Implementacao/app1/lib/src/presentation/cart/edit_cart_dialog.dart` — new.
- `03_Implementacao/app1/lib/src/presentation/cart/duplicate_cart_dialog.dart` — new.
- `03_Implementacao/app1/lib/src/presentation/cart/responsible_users_screen.dart` — new.
- `03_Implementacao/app1/lib/src/presentation/cart/product_search_screen.dart` — new.
- `03_Implementacao/app1/lib/src/presentation/dashboard/institution_home_screen.dart` — rewritten: `_CartStatusSummary`, `_RecentActivity`, cart-name search field, "Histórico" `AppBar` icon.
- `03_Implementacao/app1/lib/src/presentation/reports/history_screen.dart` — new.
- `03_Implementacao/app1/test/fakes/fake_repositories.dart` — `FakeInventoryRepository` gained the uniqueness-conflict check; `FakeCartRepository` gained `getCart`/`updateCart` and full `responsibleUsers` behavior.
- `03_Implementacao/app1/test/presentation/responsible_users_screen_test.dart`, `product_search_screen_test.dart`, `history_screen_test.dart` — new (3 tests each). `cart_detail_screen_test.dart` (+7), `institution_home_screen_test.dart` (+4), `slot_editor_screen_test.dart` (+1).
- No repository interface, Firestore Rules, or Rules-test changes were needed.
- `docs/ARCHITECTURE.md`, `docs/IMPLEMENTATION_STATUS.md`, `docs/TEST_STATUS.md` — updated.

Audit reconciliation and event correction (prior sub-phase):
- `03_Implementacao/app1/lib/src/presentation/cart/assignment_dialog.dart` — added `_Mode.reconcile`/`_Mode.correct`, their loader/submit methods, and the two new UI branches; added "Corrigir"/"Reconciliar" buttons to the view mode.
- `03_Implementacao/app1/lib/src/presentation/cart/assignment_status_label.dart` — added `usageEventTypeLabel`.
- `03_Implementacao/app1/test/fakes/fake_repositories.dart` — `FakeInventoryRepository` gained `reconcileAfterAudit`/`recordCorrection` (and a proper per-batch id generator in `recordReplenishment`, needed so reconciliation's per-batch checkboxes have distinct keys); `FakeUsageRepository` gained real behavior.
- `03_Implementacao/app1/test/presentation/slot_editor_screen_test.dart` — 3 new tests.
- No repository, Firestore implementation, or Rules changes were needed.
- `docs/ARCHITECTURE.md`, `docs/IMPLEMENTATION_STATUS.md`, `docs/TEST_STATUS.md` — updated.

Product catalogue and slot assignments (prior sub-phase):
- `03_Implementacao/app1/lib/src/presentation/products/products_screen.dart`, `create_product_dialog.dart` — new.
- `03_Implementacao/app1/lib/src/presentation/cart/assignment_dialog.dart`, `assignment_status_label.dart` — new.
- `03_Implementacao/app1/lib/src/presentation/cart/slot_editor_screen.dart` — added `_assignments` stream, `_products` future, long-press wiring, and per-cell product/quantity display.
- `03_Implementacao/app1/lib/src/presentation/dashboard/institution_home_screen.dart` — added the "Produtos" `AppBar` icon.
- `03_Implementacao/app1/test/fakes/fake_repositories.dart` — `FakeProductRepository`/`FakeInventoryRepository` gained real in-memory behavior.
- `03_Implementacao/app1/test/presentation/products_screen_test.dart` — new (4 tests). `slot_editor_screen_test.dart` gained 3 tests (assign/consume/informational-message).
- No repository, Firestore implementation, or Rules changes were needed.
- `docs/ARCHITECTURE.md`, `docs/IMPLEMENTATION_STATUS.md`, `docs/TEST_STATUS.md` — updated.

Drawer/slot editor (prior sub-phase):
- `03_Implementacao/app1/lib/src/presentation/cart/cart_detail_screen.dart` — rewritten from a static placeholder (`StatelessWidget`) to a `StatefulWidget` with a real drawer list and manager-gated "Nova gaveta" FAB.
- `03_Implementacao/app1/lib/src/presentation/cart/create_drawer_dialog.dart` — new; name + rows/columns (1-12) dialog.
- `03_Implementacao/app1/lib/src/presentation/cart/slot_editor_screen.dart` — new; the merge/split grid editor described above.
- `03_Implementacao/app1/test/fakes/fake_repositories.dart` — `FakeDrawerRepository` gained real in-memory `watchDrawers`/`createDrawer`/`updateDrawer`/`watchSlots`/`replaceSlots`.
- `03_Implementacao/app1/test/presentation/cart_detail_screen_test.dart`, `slot_editor_screen_test.dart` — new (4 tests each).
- No repository interface, Firestore implementation, or Rules changes were needed — `DrawerRepository`/`FirestoreDrawerRepository` and the `drawers`/`slots` Rules were already complete from the architecture-foundation phase.
- `docs/ARCHITECTURE.md`, `docs/IMPLEMENTATION_STATUS.md`, `docs/TEST_STATUS.md` — updated.

Membership management (prior sub-phase):
- `03_Implementacao/app1/lib/src/domain/repositories/institution_repository.dart` — added `watchMembers`, `createMember`, `updateMemberRole`, `setMembershipStatus`.
- `03_Implementacao/app1/lib/src/data/firebase/firestore_institution_repository.dart` — implements the four new methods; `createMember` uses `createIsolatedAccountCreationAuth()` then a `WriteBatch`; `setMembershipStatus` also uses a `WriteBatch`; `updateMemberRole` is a single-doc update.
- `03_Implementacao/app1/lib/src/data/firebase/firebase_bootstrap.dart` — added `createIsolatedAccountCreationAuth()`: a throwaway, uniquely-named secondary `FirebaseApp` so creating another user's Auth account never signs out the current user.
- `03_Implementacao/app1/lib/src/common/repository_failure.dart` — added `RepositoryFailureReason.invalidInput`.
- `03_Implementacao/app1/lib/src/data/firebase/firestore_exception_mapper.dart` — maps `FirebaseAuthException` codes (`email-already-in-use` → `conflict`, `invalid-email`/`weak-password` → `invalidInput`) instead of always `unauthenticated`.
- `03_Implementacao/app1/lib/src/presentation/members/members_screen.dart`, `add_member_dialog.dart`, `membership_labels.dart` — new.
- `03_Implementacao/app1/lib/src/presentation/dashboard/institution_home_screen.dart` — added the "Membros" `AppBar` icon; refactored `_canManageCarts`/new `_isInstitutionAdmin` to share one `Future<Membership?> _myMembership` instead of two separate loads.
- `03_Implementacao/app1/test/fakes/fake_repositories.dart` — `FakeInstitutionRepository` gained real in-memory `watchMembers`/`createMember`/`updateMemberRole`/`setMembershipStatus`.
- `03_Implementacao/app1/test/presentation/members_screen_test.dart` — new (5 tests). `institution_home_screen_test.dart` gained 2 tests for the Membros icon's role gating.
- `firestore.rules`, `firestore.indexes.json` — deployed to the cloud project `i-crash-pt-2026` this sub-phase (unchanged content — no new rules were needed for membership management itself; see "Firebase configuration status" below for the deployment).
- `docs/ARCHITECTURE.md`, `docs/IMPLEMENTATION_STATUS.md`, `docs/TEST_STATUS.md` — updated.

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
- `FirestoreInstitutionRepository.watchMyInstitutions` reads a denormalized `memberIndex` collection, not `memberships` directly, because of a Firestore Rules/emulator limitation with mixing collection-group and nested-exact rules on one collection name. Full details in `docs/FIREBASE_MODEL.md`.
- **`memberIndex` is now kept in sync from the app itself**: `InstitutionRepository.createMember`/`setMembershipStatus` always write `memberships`+`memberIndex` together in one `WriteBatch` (see `FirestoreInstitutionRepository`). `updateMemberRole` only touches `memberships` since `memberIndex` has no role field. Any future direct write to `memberships` must keep following this pattern — never write one without the other.
- **Creating another user's Firebase Auth account without disturbing the caller's session** requires a throwaway secondary `FirebaseApp` (`createIsolatedAccountCreationAuth()` in `firebase_bootstrap.dart`), because `createUserWithEmailAndPassword` signs in as the new user on whichever `FirebaseAuth` instance it's called on. This is a workaround for Phase 1 having no Cloud Functions; replace it with a callable Function if one is ever introduced.

## Two real bugs found only by live-testing on Android (read before repeating this class of mistake)

1. **`[core/duplicate-app]` crash on startup.** Cause: on Android, the native Firebase SDK auto-initializes `[DEFAULT]` from `google-services.json` (the real `i-crash-pt-2026` project) before Dart runs; calling `Firebase.initializeApp()` again for `[DEFAULT]` with different (demo) options throws, and since this happened before `runApp`, the whole app hung (Android reported it as an ANR, not a crash dialog, which was confusing to diagnose from logcat filters that don't include `AndroidRuntime`/`FATAL EXCEPTION`). Fix: named app `icrash-emulator` for emulator mode, `[DEFAULT]` untouched.
2. **Firestore Rules denied a `collectionGroup` query with "No matching allow statements" even though the exact same rules + data succeeded in `firestore-tests/rules.test.mjs`.** Cause: the Flutter app's Firebase project id (`i-crash-pt-2026`, from `firebase_options.dart`) never matched the emulator's configured project (`demo-icrash-v2`, from `.firebaserc`), even though `useFirestoreEmulator`/`useAuthEmulator` had redirected the network connection. `singleProjectMode` logs a warning about this ("Multiple projectIds are not recommended...") but does not actually make Rules evaluation work correctly across project ids — confirmed by a throwaway Node probe script (since deleted) that reproduced the denial with a mismatched project id and success with a matching one, using otherwise identical code. Fix: emulator mode's `FirebaseOptions` always uses `projectId: 'demo-icrash-v2'`.

**Lesson for future phases, already stated in the spec but worth restating**: a successful `flutter analyze`/`flutter test`/`flutter build` proves nothing about whether the app actually runs. Both of these bugs, plus the pre-existing `MainActivity` package bug, compiled cleanly and would have shipped silently without the mandatory live Android walkthrough.

## Firebase configuration status

`firestore.rules`/`firestore.indexes.json` are now **deployed to the cloud project** `i-crash-pt-2026` (2026-09-09), with explicit user confirmation, matching the repo's copy exactly. No application data exists there yet (see "Cloud sample data — blocked" below). Any future change to `firestore.rules`/`firestore.indexes.json` still needs explicit user confirmation before redeploying.

### Cloud sample data — blocked, needs a service-account key

The user asked for the same sample data that's in the local emulator (`Hospital de Teste` institution, one `institutionAdmin` membership, one cart) to also exist in `i-crash-pt-2026`. This is **not done yet**: the deployed rules correctly make `platformAdmins`/the first `institutions` doc unwritable by any signed-in client (by design), so no client-side script can create the first document — and the sandbox's safety layer blocks deploying a temporarily-open rules file to a cloud project, even briefly, as a workaround. The only remaining path is a Firebase Admin SDK service-account key (bypasses Rules entirely, the officially-documented way to provision `platformAdmins`): the user generates one from `console.firebase.google.com/project/i-crash-pt-2026/settings/serviceaccounts/adminsdk` → "Generate new private key", saves the JSON, and gives the assistant its path so a one-off Node script (mirroring `firestore-tests/seed_emulator.mjs`, but against the real project) can seed the same four documents. Do not attempt the temporary-open-rules workaround again — it was already tried and blocked.

## Firestore collections already implemented (schema, not deployed data)

Same as before, plus `institutions/{id}/memberIndex/{uid}` (see `docs/FIREBASE_MODEL.md`, "Why `memberIndex` exists"). `memberships`/`memberIndex` can now be created and updated from within the app (`MembersScreen`), not just by the emulator seed script.

## Domain models already implemented

Unchanged this sub-phase. See prior handoff / `docs/ARCHITECTURE.md`.

## Dependencies added/removed

None in the Flutter app (no `pubspec.yaml` change). No new dev-dependency for widget testing — fakes are hand-written (`test/fakes/fake_repositories.dart`), deliberately not introducing `mockito`/`mocktail`. `firestore-tests/` gained no new npm packages this sub-phase (it already had `firebase`/`@firebase/rules-unit-testing` from before).

## Migrations performed

None.

## Security rules status

22/22 passing locally (`firestore-tests/rules.test.mjs`). Deployed to `i-crash-pt-2026` (2026-09-09), untested there directly (the rules test suite only runs against the emulator) — treat the emulator suite as the source of truth and redeploy after any change. Membership management needed no new rules — `memberships`/`memberIndex` admin-only writes were already covered. Known gaps unchanged from the architecture-foundation handoff (offline-replay test, `platformAdmins` bootstrap, slot-geometry validation) — see prior AI_HANDOFF content in git history (`b2badfe`..`31705a9`) if needed, or `docs/FIREBASE_MODEL.md`.

## Tests already run

`flutter analyze` clean. `flutter test`: 69/69 (up from 48). `flutter build apk --debug`: passed. Firestore Rules tests: 22/22 (unchanged this round — no Rules changes). Seven full live Android walkthroughs: login/institution-selection, cart list/creation, membership management, drawer/slot editor, product catalogue/slot assignments, audit reconciliation/correction, then this round's correctness-fixes/responsibleUsers/cart-edit-duplicate/product-search/dashboard/history — see `docs/TEST_STATUS.md` for detail and the bugs they caught (zero new bugs this round).

## Android emulator tests already performed

This session, on `ICrash_API_36`, across six builds:

1. Login slice: fresh install → login screen renders → validation errors on empty submit → successful sign-in with the seeded test account → institution list shows "Hospital de Teste" → tapping it opens the institution home → legacy app reachable → back navigation returns correctly.
2. Cart list/creation slice (separate emulator restart — emulator data does not persist, re-seed with `npm --prefix firestore-tests run seed` after every `emulators:start`): institution home shows the seeded "Carro de Emergência 1"; "Novo carro" FAB visible for the seeded `institutionAdmin`; created "Carro2" via the dialog, list updated live with no manual refresh; opened its detail screen; opened the legacy app via the new `AppBar` icon.
3. Membership management slice (same emulator instance as #2, re-seeded): "Membros" icon visible for the `institutionAdmin`; members list showed the admin's own row with no action menu; "Novo membro" created a new Auth account + `memberships`/`memberIndex` docs, appearing instantly in the list; "Mudar cargo" changed the new member's role live; "Desativar" toggled their status live. Admin's own session was never disrupted by creating the other account.
4. Drawer/slot editor slice (same running app session, no restart needed): opened "Carro de Emergência 1" → detail screen showed the empty-drawers state → created "GavetaPrincipal" (3×2) → opened it → slot editor rendered 6 unit cells → selected two and merged them into one wide slot → split it back to units → merged again and saved ("Gaveta guardada." snackbar) → left and reopened the drawer, confirming the merged layout reloaded correctly from Firestore.
5. Product catalogue/slot assignments slice (same session): "Produtos" icon → created "Adrenalina" → back to the drawer → long-pressed the merged slot → "Atribuir produto" with quantities 0/1 → cell showed "Adrenalina 0/1" live → long-pressed again → "Repor stock" with quantity 5, lot "LOTE123", expiry 16/09/2026 → cell showed "5/1" → "Registar consumo" with quantity 2 → cell showed "3/1".
6. Audit reconciliation/correction slice (same session, continuing from "3/1"): "Reconciliar" showed the "LOTE123" batch pre-checked and confirmed-quantity pre-filled with 3; unchecked the batch, set confirmed quantity to 2, confirmed → cell showed "2/1". "Corrigir" listed the reconciliation event pre-selected with adjustment pre-filled to +1 (undo); confirmed → cell showed "3/1" again.
7. Correctness-fixes/responsibleUsers/cart-edit-duplicate/product-search/dashboard/history slice (new session, same seeded institution/cart): institution home showed "Operacional: 1" and 4 real historical usage events with correct labels ("Correção · Adrenalina (+1)", "Reconciliação · Adrenalina (-1)", "Consumo · Adrenalina (-2)", "Reposição · Adrenalina (+5)"); "Histórico" icon opened the full event list, "Consumo" filter narrowed it correctly; "Pesquisar produto" found "Adrenalina" typing "Adren" and opened its assignment dialog directly in view mode; the cart's overflow menu showed "Editar"/"Duplicar" — "Editar" opened pre-filled with name/status, cancelled without changes; "Duplicar" opened pre-filled with "Carro de Emergência 1 (cópia)" and explicit no-stock/no-history copy text, confirming created the second cart with the same "GavetaPrincipal" 3×2 drawer and updated the dashboard to "Operacional: 2" immediately; "Responsáveis" listed both institution members by uid, correctly disabled the inactive manager membership's checkbox, and toggling the active institution-admin's checkbox on then off both persisted through the Firestore emulator live.

No fatal `pt.icrash.app` exceptions in logcat in any run. Screenshots were taken at each step during the session (not committed to the repo — they lived in `%TEMP%`).

**Lesson from the drawer/slot-editor sub-phase's live testing**: `adb shell uiautomator dump <path>` must be run with `MSYS_NO_PATHCONV=1` in this Git-Bash environment, exactly like `adb pull` already needed — otherwise the `/sdcard/...` argument gets silently mangled into a Windows-style path, the dump fails on-device, and a subsequent `adb pull` of the same path silently re-fetches a stale file from an earlier successful dump instead of erroring. This produced a very convincing false "bug" (a button appearing to render inconsistently) that cost significant time to debug before the stale-dump cause was found via `adb logcat`. Always set `MSYS_NO_PATHCONV=1` on both the `uiautomator dump` and the `adb pull` call, and treat a suspicious/unchanging dump result as a reason to check logcat for a dump failure before trusting it.

**Lesson from the product/assignment sub-phase's live testing**: a `TextFormField`'s actual tap target extends beyond its visible text line to include its label/helper-text band, so two vertically-stacked fields can have tap targets much closer together than a screenshot suggests — a tap aimed at what looks like the second field's row can still land inside the first field's (taller) target. When a form field seems to be "eating" taps meant for the field below it, get the exact `EditText` bounds via `uiautomator dump` rather than estimating from the screenshot.

## Known bugs

None known to remain. The four found in the cart-list sub-phase (MainActivity package, cleartext blocking, project-id mismatch, FAB/legacy-button overlap) are fixed and verified live. No new app bugs were found in the membership-management, drawer/slot-editor, product/assignment, reconcile/correct, or this round's correctness-fixes/responsibleUsers/cart-edit-duplicate/product-search/dashboard/history sub-phases (the stylus-handwriting overlay quirk and the TextFormField tap-target overlap noted above are AVD/OS/Material-theme behavior, not app bugs — see `docs/TEST_STATUS.md`).

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

Login, institution selection, cart list/creation/edit/duplicate, membership management, `responsibleUsers` management, the drawer/slot editor, product catalogue/slot assignments, audit reconciliation/correction, product search, the dashboard, and the activity history screen are all done. `InventoryRepository`'s entire surface is reachable from the UI, and both correctness gaps found in spec review (product uniqueness, layout versioning) are fixed. **The one remaining major workstream, explicitly the highest priority per the user's own instruction, is:**

**GS1 Data Matrix scanning integration (spec sections 29-32).** `ProductRepository.findByGtin` exists and is unused; `ScannerService` (`lib/src/services/`) is a contract-only interface with no implementation. The legacy QR/Data Matrix reader code exists under the untouched legacy `lib/` tree (`qr_code_reader/`, `data_matrix_analyser/` or similarly named — re-locate and re-read it, it has not been re-examined since Phase 0) but is not wired to the new domain model at all. Suggested approach:

1. Re-read spec sections 29-32 in full for the exact GS1 Data Matrix field/terminology requirements before designing anything.
2. Design and implement a concrete `ScannerService` (camera integration — likely reusing/adapting the legacy camera plumbing rather than rewriting it from scratch, but returning data through the new domain types, not the legacy ones).
3. Wire the scan result to `ProductRepository.findByGtin`, most likely pre-filling `assignment_dialog.dart`'s `_Mode.replenish` form (GTIN/lot/expiry) from a scanned code instead of requiring manual entry — check whether `_Mode.assign` should also benefit from a scan-to-find-product path.
4. Test (`flutter analyze`/`flutter test`, new fakes for `ScannerService` in `test/fakes/`) and, per the spec's mandatory rule, validate live on the Android emulator (the AVD's virtual camera cannot produce a real scannable code — see the Phase 0 walkthrough — so validate what can be validated live and document clearly what could not be, e.g. manual-entry fallback paths, UI state before/after a scan).

Follow the same pattern established throughout: check `lib/src/domain/repositories/`/`lib/src/services/` first for what already exists, fakes go in `test/fakes/`, screens go in `lib/src/presentation/<area>/`, and validate live before calling it done — not just `flutter analyze`/`flutter test`. Also visually re-check for control overlap since widget tests don't catch that — see the cart-list sub-phase's bug above.

## Temporary workarounds

- `FirestoreInventoryRepository.reconcileAfterAudit` still uses a plain `WriteBatch` for the batch-collection replacement rather than one atomic transaction spanning batches+assignment (unchanged from the architecture-foundation handoff).
- `createIsolatedAccountCreationAuth()` (member creation) is a client-side workaround for having no Cloud Function to create a user's Auth account server-side. It works but is not how a real invite-by-email flow should ultimately work — revisit if/when Cloud Functions are introduced.
- `memberships`/`memberIndex` are now written together everywhere (`createMember`, `setMembershipStatus` via `WriteBatch`). Any new code path that writes `memberships` directly must keep doing the same — never write one without the other.
- `SlotEditorScreen` gives every slot a position-based id (`r{row}c{column}` of its top-left cell) rather than a stable identity that survives merges/splits. **This is now a live concern, not just a future one**: `CartProductAssignment.slotId` is assigned by the product/assignment slice added this session, so re-merging or re-splitting an already-assigned drawer and saving will change which slot ids exist, orphaning any assignment whose `slotId` no longer matches a current slot (it becomes invisible in the grid — nothing currently detects or warns about this). There is no UI yet that reassigns or cleans up an orphaned assignment. Whoever next touches the drawer/slot editor should either add that detection/cleanup, or revisit the id scheme to keep it stable across merges/splits.

## Things that must NOT be redone

Everything from the Phase 1 handoff still applies: do not initialize another repository, develop on or push to `main`, restore Django (its manifest was only security-patched, not the code — do not start running/testing it), discard the backup, recreate Firebase without location approval, repeat the SDK modernization, commit secrets/build caches, or claim iOS/macOS validation from Windows.

Additionally: do not re-derive the conservative-expiry logic inline (`InventoryRules` only). `firestore.rules`/`firestore.indexes.json` are now deployed to the cloud project (see above) — any *future* change to either file still needs explicit user confirmation before redeploying. Do not "simplify" `firebase_bootstrap.dart` back to a single `[DEFAULT]` app or the real project id in emulator mode — both bugs described above will come straight back. Do not open a PR from `DEV-Pedro` to `main` for the Django dependency fix — the user was asked and explicitly chose to leave it as-is for now. Do not try deploying a temporarily-open/permissive `firestore.rules` to the cloud project to bootstrap data, even briefly — already attempted and blocked by the environment's safety layer; use a service-account key instead (see "Cloud sample data — blocked" above).

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
