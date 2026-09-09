# Architecture

Status: Phase 2 foundation implemented (domain, data, repositories, DI wiring not yet exposed to UI). Legacy screens still run unchanged; they will be replaced flow by flow starting in the next phase.

Existing app: legacy Flutter screens and HTTP `RequestHandler` targeting the old Django endpoint remain in place under `lib/` (`grids/`, `registration/`, `request_handler/`, `qr_code_reader/`, `updates/`). Nothing there has been touched; they still compile and are still the app's actual entry point via `HomeMenu`.

## V2 layers (`lib/src/`)

```
presentation/     (not created yet — legacy screens are still the presentation layer)
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
common/            AppEnvironment (emulator vs cloud selection), RepositoryFailure
```

The domain layer imports nothing from `cloud_firestore`/`firebase_auth`/`firebase_core`. `lib/src/domain/inventory_rules.dart` is proof of this: it is exercised directly in `test/domain/inventory_rules_test.dart` with no emulator running.

`lib/src/data/firebase/*` is the only place that imports Firebase packages. Firestore documents are converted to/from domain entities there; `Timestamp` never leaks past this layer (`firestore_codec.dart` converts it to a plain `DateTime` before entities see it).

No dependency-injection framework was introduced. Repositories are plain classes constructed with `FirebaseFirestore.instance`/`FirebaseAuth.instance`; nothing outside `data/firebase` should construct them directly once presentation code starts consuming them — that wiring point will be decided when the first V2 screen is built.

## Environment selection

`lib/src/common/app_environment.dart` decides Auth/Firestore emulator vs cloud:

- Debug builds default to the **emulator** (127.0.0.1, or 10.0.2.2 from the Android emulator) so development can never write to the cloud project `i-crash-pt-2026` by accident.
- Release builds default to **cloud**, since a shipped app has no emulator to reach.
- Either can be forced with `--dart-define=ICRASH_BACKEND=emulator` or `--dart-define=ICRASH_BACKEND=cloud`.

`lib/src/data/firebase/firebase_bootstrap.dart` calls `Firebase.initializeApp` then, only in emulator mode, `FirebaseAuth.useAuthEmulator` / `FirebaseFirestore.useFirestoreEmulator`. `lib/main.dart` calls this instead of initializing Firebase directly.

## What is intentionally not built yet

- No presentation-layer code consumes the new repositories. Legacy screens (`HomeMenu`, `grids/*`, `registration/*`) are unchanged and still point at the obsolete Django `RequestHandler`.
- No dependency injection / service locator.
- `ScannerService`/`ReportService`/`NotificationService` are contracts only.
- Offline-state UI (synced/pending/failed) is not built; Firestore's own offline cache is unconfigured beyond its native platform default.

See `ICRASH_V2_SPECIFICATION.md` for authoritative scope and dependency order, and `docs/FIREBASE_MODEL.md` for the Firestore collection layout and the conservative-expiry rule those repositories implement.
