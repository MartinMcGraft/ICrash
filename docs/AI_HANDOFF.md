# AI handoff

Updated: 2026-09-09

- Repository: `C:\Users\Pedro Jorge\Documents\projeto icrash\ICrash-git`
- Remote: `https://github.com/MartinMcGraft/ICrash.git`
- Current branch: `DEV-Pedro`
- Base commit: `8e0e619` (`origin/main`)
- Last published commit before this phase: `63fc941` (`chore: validate Windows Firebase build`)
- Flutter application: `03_Implementacao/app1`
- Firestore Rules tests: `firestore-tests/` (Node project, separate from the Flutter app)
- Preserved backup: `C:\Users\Pedro Jorge\Documents\projeto icrash\backup-before-update-20260907`

## Completed work

Phase 0 (Git/modernization) and Phase 1 (Firebase foundation) are complete and published — see prior handoff history in git log for `03_Implementacao/app1` and `docs/`.

**Phase 2 foundation (this session) is complete**: layered architecture, emulator wiring, Firestore multi-institution model, and institution/role-scoped security Rules with automated tests. UI replacement (spec item 5 / workstreams A-D) has **not** started — this is the next task.

## Exact files changed this session

- `03_Implementacao/app1/lib/main.dart` — now calls `bootstrapFirebase()` instead of `Firebase.initializeApp` directly.
- `03_Implementacao/app1/lib/src/common/app_environment.dart` — emulator-vs-cloud selection.
- `03_Implementacao/app1/lib/src/common/repository_failure.dart` — typed repository error.
- `03_Implementacao/app1/lib/src/domain/entities/*.dart` — `role.dart`, `membership.dart`, `institution.dart`, `cart_status.dart`, `cart.dart`, `cart_drawer.dart`, `slot.dart`, `product.dart`, `cart_product_assignment.dart`, `batch.dart`, `usage_event.dart`, `audit_event.dart`, `cart_responsible_user.dart` — plain Dart entities, no Firebase imports.
- `03_Implementacao/app1/lib/src/domain/inventory_rules.dart` — pure conservative-expiry/no-FEFO logic.
- `03_Implementacao/app1/lib/src/domain/repositories/*.dart` — `auth_repository.dart`, `institution_repository.dart`, `cart_repository.dart`, `drawer_repository.dart`, `product_repository.dart`, `inventory_repository.dart`, `usage_repository.dart`, `audit_repository.dart` — interfaces only.
- `03_Implementacao/app1/lib/src/services/*.dart` — `scanner_service.dart` (two separate interfaces: internal QR vs GS1 Data Matrix), `report_service.dart`, `notification_service.dart` — contracts only, no implementation.
- `03_Implementacao/app1/lib/src/data/firebase/*.dart` — `firebase_bootstrap.dart`, `firestore_paths.dart`, `firestore_codec.dart`, `firestore_exception_mapper.dart`, `firebase_auth_repository.dart`, `firestore_institution_repository.dart`, `firestore_cart_repository.dart`, `firestore_drawer_repository.dart`, `firestore_product_repository.dart`, `firestore_inventory_repository.dart`, `firestore_usage_repository.dart`, `firestore_audit_repository.dart`.
- `03_Implementacao/app1/test/domain/inventory_rules_test.dart` — new, 11 tests.
- `firestore.rules` — rewritten from deny-all to the institution/role-scoped model.
- `firestore.indexes.json` — two composite indexes added.
- `firestore-tests/` — new Node project (`package.json`, `rules.test.mjs`, `README.md`, `.gitignore`); `npm install` already run locally (`node_modules/` is git-ignored, not committed).
- `docs/ARCHITECTURE.md`, `docs/FIREBASE_MODEL.md`, `docs/IMPLEMENTATION_STATUS.md`, `docs/TEST_STATUS.md` — updated to describe the above.

## Architecture decisions

- Domain layer (`lib/src/domain/`) never imports `cloud_firestore`/`firebase_auth`/`firebase_core`. Only `lib/src/data/firebase/*` does. Verified by `test/domain/inventory_rules_test.dart` running with zero Firebase setup.
- `AppEnvironment` (`lib/src/common/app_environment.dart`) makes debug builds default to the local emulator and release builds default to cloud, overridable via `--dart-define=ICRASH_BACKEND=emulator|cloud`. This is the "safe by default" mechanism the user asked for — nothing in a normal `flutter run`/`flutter test` in debug mode can write to `i-crash-pt-2026` by accident.
- Firestore collection model: `institutions/{id}` as tenancy root, with nested `memberships`, `products`, `carts` (nested `responsibleUsers`, `drawers/slots`, `assignments/batches`), and institution-level `usageEvents`/`auditEvents`. Full rationale in `docs/FIREBASE_MODEL.md`.
- `CartResponsibleUser` is one document per uid (not an array field) specifically so a future move to multiple responsible users per cart (open decision #3) needs no schema change.
- The conservative-expiry/no-FEFO rule (spec sections 22-28, 48, 58-59) is implemented as pure static functions in `lib/src/domain/inventory_rules.dart`, called from `FirestoreInventoryRepository`'s transactions rather than reimplemented inline, so it is unit-testable and there is exactly one place that can regress it.
- No dependency-injection framework was introduced. Repository implementations are plain classes taking `FirebaseFirestore`/`FirebaseAuth` instances in their constructors. **Not yet decided**: how presentation-layer code will obtain repository instances (provider/riverpod/get_it/manual). This must be decided when the first V2 screen is built — do not silently pick one without checking this file first.

## Firebase configuration status

Unchanged from Phase 1 except for the two additions below:

- `firestore.rules` is no longer deny-all; see `docs/FIREBASE_MODEL.md` for the full rule summary. It has **not been deployed** anywhere — only tested against the local emulator via `firebase-tests` (sic, actual folder name is `firestore-tests/`). Cloud project `i-crash-pt-2026` still has whatever Rules were last deployed there (should still be the original closed default — verify with `firebase deploy --only firestore:rules --project development --dry-run` style inspection before ever deploying for real, and get explicit user confirmation first).
- `firestore.indexes.json` now declares two composite indexes (see `docs/FIREBASE_MODEL.md`). Also not deployed anywhere yet.
- No users, institutions, carts, or any other document exist in either the emulator's persisted state (emulator data is not persisted across runs — `firebase emulators:exec` always starts clean) or the cloud project.
- No App Check, Storage, Cloud Functions or billing account exist. Do not add any without explicit user authorization (spec sections 7, 9).

## Firestore collections already implemented (schema, not deployed data)

See `docs/FIREBASE_MODEL.md` "Collection layout" for the full tree. Summary: `platformAdmins`, `institutions/{id}`, `.../memberships/{uid}`, `.../products/{id}`, `.../carts/{id}`, `.../carts/{id}/responsibleUsers/{uid}`, `.../carts/{id}/drawers/{id}`, `.../drawers/{id}/slots/{id}`, `.../carts/{id}/assignments/{id}`, `.../assignments/{id}/batches/{id}`, `.../usageEvents/{id}`, `.../auditEvents/{id}`.

## Domain models already implemented

All entities listed in "Exact files changed this session" above, under `lib/src/domain/entities/`. Every entity has `fromMap`/`toMap`; `fromMap` expects `DateTime?` for timestamp fields (the Firestore layer converts `Timestamp` → `DateTime` via `firestore_codec.dart`'s `normalizeTimestamps` before calling `fromMap` — **do not** pass a raw Firestore `Timestamp` into an entity's `fromMap` directly, it will throw a cast error).

## Dependencies added/removed

None. No `pubspec.yaml` change this session. The `firestore-tests/` Node project has its own `package.json` (`@firebase/rules-unit-testing`, `firebase`), entirely separate from the Flutter app's dependencies.

## Migrations performed

None (no cloud data existed to migrate).

## Security rules status

Implemented and tested locally (18/18 passing against the emulator, see `docs/TEST_STATUS.md` for the exact command). **Not deployed** to the cloud project. Do not deploy without the user's explicit confirmation, and do not deploy `firestore.indexes.json` changes either without checking whether they'd affect the cloud project's existing (empty) index configuration.

Known rules gaps to close in a later security-hardening pass (not blocking, but worth tracking):
- No test yet for an offline-queued write replaying against Rules after reconnect (spec section 60's last bullet) — this needs an actual Flutter-side offline test, not a Rules-unit test.
- `platformAdmins` has no self-service bootstrap; the very first entry must be created manually (console or Admin SDK) against whichever project (emulator or cloud) is being used.
- Drawer/slot Rules do not yet validate slot geometry (no-overlap, in-bounds) — spec section 36's invariants are currently a domain/application-layer responsibility only, not enforced by Rules. Acceptable for now (prototype), flag if this becomes a real integrity concern.

## Tests already run

See `docs/TEST_STATUS.md`, "Phase 2 foundation — automated validation" section, for the exact commands and counts. Summary: `flutter analyze` clean, `flutter test` 12/12, `flutter build apk --debug` passed, Firestore Rules tests 18/18 against the emulator.

## Android emulator tests already performed

None this session — no UI changed. Phase 0's walkthrough (home screen, registration, QR reader, Data Matrix analyser) remains the most recent live Android validation; see `docs/TEST_STATUS.md`.

## Known bugs

None introduced this session, as far as `flutter analyze`/`flutter test`/the Rules tests can show. No new bug was found in legacy code either (it was not touched).

## Known platform limitations

Unchanged from Phase 1 (see below, "Environment"). Web/Windows builds were not re-run this session; re-verify before relying on them again.

## Open business decisions

Unchanged — see `docs/OPEN_DECISIONS.md`. Nothing this session required a new clinical/business decision; the schema was built to remain flexible for the open questions already listed there (e.g. multiple responsible users per cart, L/T slot shapes).

## Pending Git changes

Everything listed under "Exact files changed this session" is staged for the next commit at the time of writing this handoff (see the human-readable summary at the end of the assistant's response for the actual commit hash once created). `firestore-tests/node_modules/` is untracked and git-ignored — do not commit it.

## Exact commands needed to continue

```
cd "C:\Users\Pedro Jorge\Documents\projeto icrash\ICrash-git\03_Implementacao\app1"
flutter analyze --no-pub
flutter test --no-pub

cd "C:\Users\Pedro Jorge\Documents\projeto icrash\ICrash-git"
firebase emulators:exec --only firestore --project demo-icrash-v2 "npm --prefix firestore-tests test"
```

To run the app against the emulator locally end-to-end (Auth + Firestore both up, app attached):

```
firebase emulators:start --only auth,firestore --project demo-icrash-v2
```

then, in another terminal, `flutter run` from `03_Implementacao/app1` (debug mode already defaults to the emulator).

## Exact next implementation task

Spec item 5 / workstreams A-D: start replacing legacy screens with V2 flows, in this order per the user's instructions — login (using `FirebaseAuthRepository`), institution selection (`FirestoreInstitutionRepository.watchMyInstitutions`), then carts/drawers/slots/stock/lots/audit screens. Before writing the first screen:

1. Decide how a screen obtains a repository instance (see "Architecture decisions" above — this was deliberately left open).
2. Seed at least one institution/membership/cart in the emulator (manually, or via a small seed script) so the new login → institution-selection flow has something to show.
3. Keep legacy screens reachable until their V2 replacement is validated on the Android emulator, per the spec's "do not restore Django, do not discard functionality" rule — but the legacy `RequestHandler` HTTP calls must not be wired into anything new.

## Temporary workarounds

- Android emulator `10.0.2.2` mapping for reaching the host machine's `127.0.0.1` emulator ports is handled in `AppEnvironment.emulatorHost`; if a real device is ever used instead of the Android emulator, this will need the host machine's LAN IP instead — not yet handled, flag if it comes up.
- `FirestoreInventoryRepository.reconcileAfterAudit` replaces the batch collection with a plain `WriteBatch` (not the same transaction as the assignment update) because a heavily-audited slot's batch count could exceed a single transaction's document-count budget. This means a reconciliation is not atomic end-to-end across batches+assignment; acceptable for the prototype, revisit if audit correctness under concurrent writes becomes a concern.

## Things that must NOT be redone

Everything from the Phase 1 handoff still applies: do not initialize another repository, develop on or push to `main`, restore Django, discard the backup, recreate Firebase without location approval, repeat the SDK modernization, commit secrets/build caches, or claim iOS/macOS validation from Windows.

Additionally from this session: do not re-derive the conservative-expiry logic inline in a repository or screen — always call into `InventoryRules`. Do not deploy `firestore.rules`/`firestore.indexes.json` to the cloud project without explicit user confirmation.

## Environment

- Flutter: `C:\Flutter\stable\bin\flutter.bat`
- Git: `C:\Program Files\Git\cmd\git.exe`
- Node: v22.15.0, npm: 11.3.0 (used only by `firestore-tests/`)
- Android SDK: `C:\Android\Sdk`
- Emulator: `ICrash_API_36` / usually `emulator-5554`
- Required Java workaround: `JDK_JAVA_OPTIONS=-Djdk.net.unixdomain.tmpdir=C:/Flutter/socket-temp`
- Firebase CLI: `C:\Users\Pedro Jorge\AppData\Roaming\npm\firebase.cmd` (15.29.0)
- FlutterFire CLI: `C:\Users\Pedro Jorge\AppData\Local\Pub\Cache\bin\flutterfire.bat` (1.4.1)

Firebase CLI is authenticated. `.firebaserc` keeps `demo-icrash-v2` as the safe local default and names the cloud project `development` (`i-crash-pt-2026`). Firebase Core is initialized via `bootstrapFirebase()` in `lib/main.dart`.
