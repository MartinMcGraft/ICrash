# Architecture

Status: login → institution selection → per-institution dashboard (cart list/creation/edit/duplicate, cross-cart alerts, internal-QR cart navigation) → responsible-user management → member management → drawer/slot editor → product catalogue/slot assignments (assign/replenish/consume/reconcile/correct, replenish now optionally scan-assisted via GS1 Data Matrix camera or HID barcode scanner) → product search within a cart → institution-wide activity history, all live and validated on the Android emulator; legacy app still reachable from there. Everything else in the legacy app (grids, registration, request handler) is untouched and still compiles; it will be replaced flow by flow in later phases. Every major workstream from the specification's core scope is now implemented; remaining work is workstream J (QA/hardening/release) and a handful of explicitly deferred enhancements — see "What is intentionally not built yet" below.

Existing app: legacy Flutter screens and HTTP `RequestHandler` targeting the old Django endpoint remain in place under `lib/` (`grids/`, `registration/`, `request_handler/`, `qr_code_reader/`, `updates/`). `HomeMenu` is no longer the app's entry point, but it is still reachable — see "Presentation" below.

## V2 layers (`lib/src/`)

```
presentation/
  auth/login_screen.dart
  institution/institution_selection_screen.dart
  dashboard/institution_home_screen.dart      per-institution home: status counts, recent
                                               activity, cart list/search + creation
  reports/history_screen.dart                 institution-wide filterable usage-event history
  cart/cart_detail_screen.dart                cart's drawer list + creation/edit/duplicate
  cart/cart_status_label.dart, create_cart_dialog.dart, create_drawer_dialog.dart
  cart/edit_cart_dialog.dart, duplicate_cart_dialog.dart
  cart/responsible_users_screen.dart          manager+: grant/revoke per-cart access
  cart/product_search_screen.dart             find an assigned product by name within a cart
  cart/bump_layout_version.dart               shared helper: increments Cart.layoutVersion
  cart/slot_editor_screen.dart                merge/split grid editor for one drawer's slots
  cart/assignment_dialog.dart                 per-slot: assign a product, replenish (optionally
                                               via GS1 scan), consume
  cart/assignment_status_label.dart
  scanning/gs1_scan_screen.dart               full-screen GS1 Data Matrix scanner (camera or HID)
  scanning/cart_qr_code_screen.dart           shows a cart's own internal QR code
  scanning/cart_qr_scan_screen.dart           full-screen internal-QR scanner
  members/members_screen.dart                 institution-admin-only: list/create/role/status
  members/add_member_dialog.dart, membership_labels.dart
  products/products_screen.dart               institution-wide product catalogue
  products/create_product_dialog.dart
        ↑
domain/
  entities/        plain Dart classes, fromMap/toMap only, no Firebase imports
  repositories/    abstract interfaces (AuthRepository, InstitutionRepository,
                   CartRepository, DrawerRepository, ProductRepository,
                   InventoryRepository, UsageRepository, AuditRepository)
  inventory_rules.dart   pure functions: conservative-expiry/no-FEFO rule, and
                         AssignmentAlert/computeAlert (cross-cart dashboard alerts) —
                         all unit-tested without Firebase
        ↑
data/firebase/     Firestore/Auth implementations of every repository interface,
                   Firestore path constants, timestamp codec, exception mapping,
                   emulator bootstrap
services/          scanner_platform_support.dart (shared camera-capability check);
                   scanner_service.dart (InternalQrScannerService, Gs1DataMatrixScannerService
                   contracts); gs1_camera_scanner_service.dart / gs1_hid_scanner_service.dart
                   (camera and HID/keyboard-wedge implementations); gs1_data_matrix_parser.dart
                   (pure, camera-independent AI 01/10/17 parser); internal_qr_camera_scanner_service.dart
                   (camera implementation); internal_qr_payload.dart (pure payload encode/decode);
                   ReportService/NotificationService — still contracts only
common/            AppEnvironment (emulator vs cloud selection), AppServices
                   (repository bundle + InheritedWidget + scanner factories), RepositoryFailure
```

The domain layer imports nothing from `cloud_firestore`/`firebase_auth`/`firebase_core`. `lib/src/domain/inventory_rules.dart` is proof of this: it is exercised directly in `test/domain/inventory_rules_test.dart` with no emulator running.

`lib/src/data/firebase/*` is the only place that imports Firebase packages. Firestore documents are converted to/from domain entities there; `Timestamp` never leaks past this layer (`firestore_codec.dart` converts it to a plain `DateTime` before entities see it).

## Presentation and dependency wiring

No dependency-injection framework was introduced. `AppServices` (`lib/src/common/app_services.dart`) is a plain class holding one instance of every repository; `lib/main.dart` constructs it once from `bootstrapFirebase()`'s result and hands it down via `AppServicesScope`, an `InheritedWidget`. A screen reads what it needs with `AppServicesScope.of(context).auth` etc. `AppServices.withRepositories(...)` is a second constructor that takes every repository directly (used by widget tests to inject fakes without touching Firebase — see `test/fakes/fake_repositories.dart`).

`lib/main.dart`'s `_AuthGate` widget listens to `AuthRepository.authStateChanges()` and shows `LoginScreen` when signed out, `InstitutionSelectionScreen` when signed in. Selecting an institution pushes `InstitutionHomeScreen`, which lists that institution's carts (`CartRepository.watchAccessibleCarts`) and — for a manager/institutionAdmin/platformSuperAdmin, checked once via `InstitutionRepository.getMyMembership` — shows a "Novo carro" FAB. Tapping a cart opens `CartDetailScreen`, which lists that cart's drawers and (manager+) a "Nova gaveta" FAB; stock/assignments (workstreams C/E/F) still don't exist. Per the "preserve existing functionality" rule, `InstitutionHomeScreen` also has a button that opens the legacy `HomeMenu` unmodified. Nothing in the new screens calls the legacy `RequestHandler`.

The FAB visibility check is a UX nicety, not the security boundary — `firestore.rules` independently enforces that only manager+ can `create`/`update` a cart (spec section 18: never rely on hiding a button). If `createCart` is ever called by someone Rules reject, it fails with a `RepositoryFailure` shown in a `SnackBar`.

`InstitutionHomeScreen` also has a "Membros" `AppBar` icon, shown only for an institution admin/platform super admin (a stricter check than the cart FAB's manager-or-above), opening `MembersScreen`. It lists every membership (`InstitutionRepository.watchMembers`), lets the admin change a member's role or toggle active/disabled, and creates brand-new members via a "Novo membro" dialog. There is still no Cloud Function to invite an existing user by e-mail alone (Phase 1 has none), so `createMember` always provisions a fresh Firebase Auth account for the given e-mail/temporary-password, then writes `memberships`/`memberIndex` in one `WriteBatch` — see "Isolated account creation" below for how the new account is created without signing the admin out of their own session. As with carts, `firestore.rules` is the real boundary (`isInstitutionAdmin`, not just `isManagerOrAbove`, gates `memberships`/`memberIndex` writes); the UI gating only avoids showing controls that would fail.

`CartDetailScreen` lists a cart's drawers (`DrawerRepository.watchDrawers`) and, for manager+, a "Nova gaveta" FAB (`create_drawer_dialog.dart`: name + rows/columns). Tapping a drawer opens `SlotEditorScreen`, which edits its slot layout (spec sections 36-37): every cell starts as its own unit slot; selecting cells whose combined area exactly tiles a rectangle and tapping "Juntar" merges them into one bigger slot, and "Dividir" on a selected merged slot restores it to unit cells. Both are local edits until "Guardar" persists the whole set via `DrawerRepository.replaceSlots` in one call. The grid always fills the available screen area — a `LayoutBuilder` divides the actual on-screen width/height by the drawer's `columns`/`rows` to get each unit cell's size, so a single slot occupies the whole visible area, two slots split it in half, and so on, mirroring a real physical drawer rather than a fixed pixel grid. Cells are `Positioned` inside a `Stack` sized by `row/column/rowSpan/columnSpan × that computed cell size`, not a `GridView` — Flutter's built-in grid widgets don't support cell spanning. This tap-to-select-then-merge/split model is simpler and more testable than reproducing the legacy `grid_slots.dart` prototype's long-press-to-select/double-tap-to-split gesture model (untouched, still reachable from the legacy `HomeMenu`, and not reused here).

Long-pressing any slot (tap is reserved for merge-selection) opens `assignment_dialog.dart`'s `showAssignmentDialog`, which reads a live `Stream<List<CartProductAssignment>>` and a one-shot product list `SlotEditorScreen` already holds. An unassigned slot shows either an "Atribuir produto" form (manager+: pick a product from `ProductsScreen`'s catalogue, set initial/target quantities, calls `InventoryRepository.createAssignment`) or a plain "ainda não tem produto atribuído" message for anyone else. An assigned slot shows the product name and `current/target` quantity plus:

- "Registar consumo" (anyone with cart access — only changes `currentQuantity`, matching what non-managers may write per Rules);
- "Corrigir" (also anyone with cart access): lists the assignment's `UsageEvent`s via `UsageRepository.watchEventsForAssignment`, pre-selects the newest with a pre-filled compensating adjustment, and calls `InventoryRepository.recordCorrection` — which only ever appends a new event referencing the one it corrects, never mutating it (spec section 44);
- manager+ only: "Repor stock" (amount + lot number + expiry date via `showDatePicker`, calls `recordReplenishment`, which also touches `earliestKnownExpiry`/`batches` — manager+-only fields) and "Reconciliar" (shows the assignment's recorded batches as checkboxes plus a physically-confirmed-quantity field, calls `reconcileAfterAudit`, which replaces the batch set and recomputes `currentQuantity`/`earliestKnownExpiry` strictly from what was confirmed present — spec section 27, never derived by summing batches).

`ProductsScreen`, reachable via a "Produtos" `AppBar` icon on `InstitutionHomeScreen` (manager+ gated the same way as the cart FAB), is the institution-wide catalogue those assignments draw from. As everywhere else in this app, the Rules are the real boundary; the dialog's mode-gating only avoids showing a control that would fail. This is `InventoryRepository`'s entire surface — every method is now reachable from the UI.

### Correctness fixes: product uniqueness and layout versioning

Two spec gaps found by review rather than by a missing screen, both fixed at the data/domain layer rather than only in the UI (per the "Rules/repository are the real boundary" rule used everywhere else):

- **Product uniqueness per cart (spec section 20)**: `FirestoreInventoryRepository.createAssignment` now checks for an existing assignment with the same `productId` anywhere in the cart before creating a new one, throwing `RepositoryFailure(RepositoryFailureReason.conflict)` if found. `assignment_dialog.dart` shows a specific PT-PT message for this case ("Este produto já está atribuído a outro slot deste carro.") rather than the generic failure message.
- **Layout versioning (spec section 38)**: `bump_layout_version.dart`'s `bumpCartLayoutVersion(services, cart)` re-reads the cart, increments `layoutVersion`, and writes it back via `CartRepository.updateCart`. Called after every structural change to a cart's drawers/slots — `CartDetailScreen._createDrawer` and `SlotEditorScreen._save` (merge/split/save) — so the version increments regardless of which screen triggered the change, rather than duplicating the read-increment-update logic at each call site.

### GS1 Data Matrix scanning (spec sections 29-32)

- `Gs1DataMatrixScannerService` (`services/scanner_service.dart`) is the abstraction business logic depends on — never `MobileScanner` directly (spec section 32). `MobileScannerGs1Service` (`services/gs1_camera_scanner_service.dart`) is the camera-backed implementation, wrapping a `MobileScannerController` restricted to `BarcodeFormat.dataMatrix` and exposing its `barcodes` stream as raw payload strings.
- `services/gs1_data_matrix_parser.dart`'s `parseGs1DataMatrix` is a pure, camera-independent function (spec section 31's explicit testability requirement) extracting the three Application Identifiers this app needs: AI 01 (GTIN, 14 digits), AI 10 (batch/lot, variable length, terminated by an FNC1 separator when present or by the next recognized AI otherwise), and AI 17 (expiry, 6-digit YYMMDD, decoded per the GS1 general specification's year-window rule). Scanner recognition and GS1 parsing are kept as separate layers exactly as spec section 31 requires — the parser never touches `mobile_scanner` types.
- `presentation/scanning/gs1_scan_screen.dart`'s `showGs1ScanScreen` pushes a full-screen scanner that listens to whatever `Gs1DataMatrixScannerService` it's given, parses every payload, and pops with the first result that yields at least one recognized field — or `null` if the user cancels. Scanning is always optional, retryable, and cancellable to manual entry (spec section 30); an unparseable payload shows an inline retry message and keeps listening rather than closing.
- `AppServices` gained `createGs1Scanner` (a `Gs1DataMatrixScannerService Function()` factory, not a shared singleton — the service owns a camera resource, so a fresh instance is built and disposed per scan screen). The real constructor picks the implementation based on `isCameraScanningSupported` (see "HID/keyboard-wedge scanning" below); `buildTestServices` defaults to `FakeGs1DataMatrixScannerService.new`, which lets a widget test push canned payloads via `emit(...)` without touching a camera.
- `assignment_dialog.dart`'s `_Mode.replenish` has a "Digitalizar código GS1" button, always visible (no platform gate — see below). A successful scan pre-fills the lot/expiry fields (still freely editable — manual correction is never blocked, spec section 30) and, when the payload carried a GTIN, resolves it via `ProductRepository.findByGtin`: an unknown GTIN is never silently attached to any product (spec section 30's explicit requirement) — it only stays on the recorded `Batch.gtin`/`Batch.source`; a GTIN that resolves to a *different* product than the slot's own shows a warning but does not block submission, since spec section 72 leaves "should replenishment require confirming scanned-product-matches-slot-product" as an open decision — blocking would be the more conservative-sounding choice but was rejected here because it would make a valid manual-fallback replenishment (spec section 30's own requirement) impossible whenever the GTIN catalogue is incomplete, which is expected in this prototype.

### HID/keyboard-wedge scanning, and internal-QR cart navigation (spec sections 29, 32-33, 67)

- `services/scanner_platform_support.dart`'s `isCameraScanningSupported` (`kIsWeb` or Android/iOS/macOS) is the one platform check both scanning domains share, replacing what used to be a private copy inside `assignment_dialog.dart`. `mobile_scanner` has no Windows/Linux desktop support at all (spec section 32 calls this out explicitly for Windows).
- `services/gs1_hid_scanner_service.dart`'s `HidGs1ScannerService` is a second `Gs1DataMatrixScannerService` implementation for exactly the platforms the camera one can't reach. A HID barcode scanner is, from the OS's point of view, a keyboard typing very fast and finishing with Enter — no driver integration is needed, only a focused text field to type into. `AppServices`'s real constructor now picks `MobileScannerGs1Service.new` when `isCameraScanningSupported`, `HidGs1ScannerService.new` otherwise, so `assignment_dialog.dart`'s scan button no longer needs to hide itself anywhere — it always opens `Gs1ScanScreen`, which itself branches on the concrete scanner type (`MobileScannerGs1Service` → camera preview; `HidGs1ScannerService` → a focused `_HidScanInput` text field whose `onSubmitted` is the entire "detection" step, re-focusing itself after every scan).
- `services/internal_qr_payload.dart` encodes/decodes the internal I-Crash QR payload (spec section 33): `icrash://v1/cart/<institutionId>/<cartId>`, a pure function pair mirroring `gs1_data_matrix_parser.dart`'s separation of decoding from parsing. Scanning only resolves an id — it never grants access by itself; whoever reads the resolved cart still goes through `CartRepository.getCart`, gated by the exact same Rules as any other cart read.
- `services/internal_qr_camera_scanner_service.dart`'s `MobileScannerInternalQrService` implements `InternalQrScannerService` (previously a contract only) the same way `MobileScannerGs1Service` implements the GS1 one, restricted to `BarcodeFormat.qrCode`. No HID counterpart was built for this domain — a keyboard-wedge scanner is a barcode/GS1 tool in practice, not something used to scan a printed internal navigation QR code, so Windows simply has no internal-QR entry point (the "Ler código do carro" icon is gated on `isCameraScanningSupported`).
- `presentation/scanning/cart_qr_code_screen.dart`'s `CartQrCodeScreen` renders a cart's payload as a QR image via the `qr_flutter` package (pure Dart, no native platform code — works on every platform including Windows, since *displaying* a code needs no camera). Reachable from `CartDetailScreen`'s "Mostrar código QR" `AppBar` icon, visible to anyone who already has cart access.
- `presentation/scanning/cart_qr_scan_screen.dart`'s `showCartQrScanScreen` mirrors `gs1_scan_screen.dart`'s structure for this domain. `InstitutionHomeScreen`'s "Ler código do carro" icon opens it, then resolves the decoded target via `CartRepository.getCart` and pushes `CartDetailScreen` on success, or shows an error `SnackBar` (not a silent no-op) if the cart doesn't exist or Rules deny the read.

### Cross-cart dashboard alerts (spec section 49)

- `InventoryRules.computeAlert` (`domain/inventory_rules.dart`) is a pure function computing an `AssignmentAlert?` (`expired` / `expiringSoon` / `belowMinimum`) from one assignment's `earliestKnownExpiry`/`currentQuantity`/`minimumQuantity` plus the institution's `expiryWarningDays` and the current time — deliberately computed at read-time, never stored, since an approaching expiry becomes true purely from the passage of time. It never flags "below target" alone (only an explicit, opt-in `minimumQuantity`), since whether target-alone should alert is one of the open clinical questions in `docs/OPEN_DECISIONS.md` this app does not answer.
- `InventoryRepository.watchAllAssignments(institutionId)` backs this with a `collectionGroup('assignments').where('institutionId', isEqualTo: institutionId)` query. Every assignment document now carries denormalized `institutionId`/`cartId` fields, written once at `createAssignment` and enforced immutable afterward by Rules — see `docs/FIREBASE_MODEL.md`, "Why the cross-cart alerts query is manager+ only", for the empirical reason this query (and its authorizing Rule) can only safely check role, not per-cart `responsibleUsers` membership. **Consequence: this dashboard section is manager+ only** — a normal user still sees their own responsible carts' assignments in full through the ordinary per-cart `watchAssignments`.
- `InstitutionHomeScreen`'s `_CrossCartAlerts` widget (manager+ gated, same `FutureBuilder<Membership?>` pattern as the rest of the screen) renders one line per assignment with a non-null alert, resolving product/cart names from data the screen already has (the one-shot `products` future, the `carts` stream the list below already uses) rather than fetching either again.

### responsibleUsers, cart edit/duplicate, product search, dashboard, history

- `ResponsibleUsersScreen` (spec section 17: institution membership alone does not grant cart access) lists every institution member via `InstitutionRepository.watchMembers`, with a `CheckboxListTile` per member reflecting `CartRepository.watchResponsibleUsers` and calling `assignResponsibleUser`/`removeResponsibleUser` on toggle; disabled for an inactive membership. Reachable from `CartDetailScreen`'s "Responsáveis" `AppBar` icon, manager+ gated. The repository methods already existed fully implemented in `FirestoreCartRepository` from the architecture-foundation phase — only the presentation layer was missing.
- `CartDetailScreen`'s overflow menu (manager+ gated, same check as the rest of the screen) adds "Editar" (`edit_cart_dialog.dart`: name + `CartStatus` dropdown, calls `CartRepository.updateCart`) and "Duplicar" (`duplicate_cart_dialog.dart`: confirms a name, then creates a new cart and copies every drawer and its slots via `createDrawer`/`replaceSlots` — deliberately **never** copies assignments, stock, or history, per spec section 39). There is no separate "template gallery" concept; any existing cart can serve as a duplication source.
- `ProductSearchScreen` (spec section 41's "search/list" requirement, alongside the existing "virtual drawer" visual navigation) filters a cart's `InventoryRepository.watchAssignments` by product name and opens the same `showAssignmentDialog` the drawer grid uses — built entirely on repositories that already existed.
- `InstitutionHomeScreen` (spec section 49, scoped down) gained a `_CartStatusSummary` (counts per `CartStatus`, derived from the same `watchAccessibleCarts` stream the list already used) and `_RecentActivity` (last 5 events from `UsageRepository.watchRecentEvents`, an institution-scoped query that already existed), plus a cart-name search field. Cross-cart per-slot expiry alerts are deliberately **not** included — they would need an institution-wide `assignments` collectionGroup query and a matching Rules change, which given the `memberIndex` collectionGroup/Rules quirks already documented above, is deferred as its own future slice.
- `HistoryScreen` (spec section 51, scoped down to its read-only "detailed view" half) is a `ChoiceChip`-filterable list over the same `watchRecentEvents` stream, reachable from `InstitutionHomeScreen`'s new "Histórico" `AppBar` icon (any user). It also has "Ver resumo" (`reports/history_summary.dart`'s `summarizeByProduct`: per-product consumed/replenished/other-adjustment totals within the current filter) and "Exportar CSV" (`reports/history_csv_export.dart`'s `buildHistoryCsv`, copied to the clipboard rather than downloaded as a file, to avoid a `path_provider`/`share_plus` dependency for a prototype-phase feature) — both pure functions over the same events/products the screen already has. PDF export and per-cart/per-period aggregates remain deferred.

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

- PDF export and per-cart/per-period aggregate reports (the rest of spec section 51) — CSV export (clipboard-based) and a per-product summary are now built; see `reports/history_csv_export.dart`/`history_summary.dart`.
- Cross-cart alerts are manager+ only (see "Cross-cart dashboard alerts" above) — a normal user does not get an aggregate view of expiry/stock issues outside carts they're responsible for.
- No dependency injection / service locator beyond `AppServicesScope`.
- `ReportService`/`NotificationService` are contracts only.
- Offline-state UI (synced/pending/failed) is not built; Firestore's own offline cache is unconfigured beyond its native platform default.
- Localization: screens currently hard-code PT-PT strings; `flutter_localizations`/`.arb` scaffolding is deferred to spec item 8.
- Workstream J (QA/hardening/releases): accessibility review, performance review, offline/reconnection validation, release signing/environment separation are all still open — see spec section 68.

See `ICRASH_V2_SPECIFICATION.md` for authoritative scope and dependency order, and `docs/FIREBASE_MODEL.md` for the Firestore collection layout and the conservative-expiry rule those repositories implement.
