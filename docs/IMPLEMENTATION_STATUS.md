# Implementation status

Updated: 2026-09-10

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

## Phase 2 continued — audit reconciliation and event correction

Status: complete and validated live on the Android emulator.

- `assignment_dialog.dart` gained two more modes: `_Mode.reconcile` (manager+: shows the assignment's recorded batches as checkboxes defaulting to all-confirmed-present, plus a physically-confirmed-quantity field defaulting to the current value; submitting calls `InventoryRepository.reconcileAfterAudit`, which replaces the batch set and recomputes `currentQuantity`/`earliestKnownExpiry` strictly from what was confirmed) and `_Mode.correct` (anyone with cart access: lists the assignment's usage events newest-first via `UsageRepository.watchEventsForAssignment`, pre-selects the most recent one with a pre-filled "undo" adjustment, and calls `InventoryRepository.recordCorrection`, which appends a compensating event referencing the original without mutating it).
- New `usageEventTypeLabel` in `assignment_status_label.dart` for the event picker's PT-PT labels.
- No repository, Firestore, or Rules changes were needed — `InventoryRepository.reconcileAfterAudit`/`recordCorrection` and `UsageRepository`/`FirestoreUsageRepository` were already complete from the architecture-foundation phase; this was purely a presentation-layer gap.
- `FakeInventoryRepository` gained `reconcileAfterAudit`/`recordCorrection`; `FakeUsageRepository` upgraded from an unimplemented stub to real in-memory behavior.
- New tests: 3 more in `slot_editor_screen_test.dart` (correct-an-event, reconcile-after-audit, role-gating showing Corrigir/Registar-consumo but hiding Repor-stock/Reconciliar for a normal user).
- Live Android validation: reconciled an assignment (unchecked its one batch, set confirmed quantity to 2 — cell updated to "2/1" and the batch was dropped), then corrected the reconciliation event with the default pre-filled adjustment (cell updated back to "3/1"). See `docs/TEST_STATUS.md`.

This closes out `InventoryRepository`'s entire surface in the presentation layer — every method (`createAssignment`, `recordConsumption`, `recordReplenishment`, `reconcileAfterAudit`, `recordCorrection`) is now reachable from the UI.

## Phase 2 continued — product catalogue and slot assignments

Status: complete and validated live on the Android emulator.

- New `lib/src/presentation/products/`: `products_screen.dart` (institution-wide catalogue, manager+ gated creation via a `canManage` flag passed in from the caller rather than re-fetched) and `create_product_dialog.dart` (name + optional unit/GTIN). `InstitutionHomeScreen` gained a "Produtos" `AppBar` icon next to "Membros", gated the same as the cart FAB (manager+).
- New `lib/src/presentation/cart/assignment_dialog.dart` and `assignment_status_label.dart`: long-pressing a slot in `SlotEditorScreen` opens a mode-switching dialog (`_Mode.assign/view/consume/replenish`) built around the existing, already-complete `InventoryRepository`/`InventoryRules`. Assigning a product and replenishing stock are manager+ only (Rules reserve `earliestKnownExpiry`/`batches` writes to manager+); recording consumption is available to anyone who reached the screen, matching the Rules boundary that lets a non-manager change only `currentQuantity` on an assignment they can access.
- `SlotEditorScreen` now also holds a `Stream<List<CartProductAssignment>>` and a one-shot `Future<List<Product>>`, both fed into each grid cell so an assigned slot shows the product's name and `current/target` quantity instead of just its row/column position.
- No repository, Firestore, or Rules changes were needed — `InventoryRepository`/`FirestoreInventoryRepository`/`ProductRepository`/`FirestoreProductRepository` and the `products`/`assignments`/`batches` Rules were already complete from the architecture-foundation phase; this slice only added the presentation layer that exercises them.
- `FakeProductRepository`/`FakeInventoryRepository` upgraded from unimplemented stubs to real in-memory behavior, mirroring the existing fakes' pattern.
- New tests: `products_screen_test.dart` (4), 3 more in `slot_editor_screen_test.dart` (assign/consume/informational-message-for-a-normal-user).
- Live Android validation: created a product, assigned it to a slot, replenished it with a lot number and expiry date, then recorded consumption — each step's effect (quantities, product name) visible instantly on the grid cell. See `docs/TEST_STATUS.md`.

Reconciliation-after-audit and correction were the immediate next step after this and are covered in the section above. Still not started: GS1 Data Matrix/QR-driven product lookup (`ProductRepository.findByGtin` exists, unused), cart edit/duplicate/template, `responsibleUsers` management UI.

## Phase 2 continued — drawer/slot editor

Status: complete and validated live on the Android emulator.

- `lib/src/presentation/cart/cart_detail_screen.dart` rewritten from a static placeholder to a real per-cart drawer list (`DrawerRepository.watchDrawers`), with a "Nova gaveta" FAB gated on manager+ (same role check as the cart list's FAB).
- New `create_drawer_dialog.dart`: name + rows/columns (1-12 each, matching the legacy `UpdateDrawerShape` screen's range).
- New `lib/src/presentation/cart/slot_editor_screen.dart`: renders a drawer's slot layout as an absolutely-positioned grid (`Stack`/`Positioned`, cell size in pixels × row/column/rowSpan/columnSpan) rather than a `GridView`, since Flutter's grid widgets don't support cell spanning natively. A drawer with no saved slots yet starts as one unit (1×1) slot per grid cell. Selecting cells whose combined footprint is itself a rectangle (checked via area-sum-equals-bounding-box-area) and tapping "Juntar" merges them into one bigger slot; "Dividir" on a selected multi-cell slot restores it to unit cells. Both are local edits; "Guardar" persists the whole set via `DrawerRepository.replaceSlots` in one call. Editing controls (Juntar/Dividir/Guardar) are hidden for anyone below manager, matching the Rules boundary on `drawers`/`slots` writes.
- `RepositoryFailureReason.invalidInput` and the improved `FirebaseAuthException` mapping (added for membership management) are unrelated to this slice but shipped in the same window.
- `FakeDrawerRepository` upgraded from an unimplemented stub to real in-memory behavior (`watchDrawers`/`createDrawer`/`updateDrawer`/`watchSlots`/`replaceSlots`), mirroring `FakeCartRepository`'s pattern.
- New tests: `cart_detail_screen_test.dart` (4), `slot_editor_screen_test.dart` (4).
- Live Android validation: created a 3×2 drawer, merged two cells into one, split it back, merged again and saved, then confirmed the merged layout reloads correctly from Firestore after leaving and reopening the drawer. See `docs/TEST_STATUS.md`.

Product/assignment screens (workstream C) were the immediate next step after this and are covered in the section above.

## Phase 2 continued — membership management

Status: complete and validated live on the Android emulator.

- `InstitutionRepository` gained `watchMembers`, `createMember`, `updateMemberRole`, `setMembershipStatus`. `FirestoreInstitutionRepository.createMember` provisions a brand-new Firebase Auth account (no Cloud Function exists yet to invite an existing user by e-mail alone) via a throwaway, uniquely-named secondary `FirebaseApp` (`createIsolatedAccountCreationAuth` in `firebase_bootstrap.dart`) so the admin's own session is never disturbed, then writes `memberships`/`memberIndex` in one `WriteBatch`. `setMembershipStatus` writes both docs' `status` field together in a `WriteBatch`; `updateMemberRole` is a single-document update (`memberIndex` has no role field).
- New `lib/src/presentation/members/`: `members_screen.dart` (list, role change, enable/disable, institution-admin-only), `add_member_dialog.dart` (e-mail/temporary-password/role form), `membership_labels.dart` (PT-PT role/status labels).
- `InstitutionHomeScreen` gained a "Membros" `AppBar` icon, gated on institution-admin/platform-super-admin (stricter than the cart FAB's manager-or-above) via the same `getMyMembership` call, refactored to a single shared `Future` for both gates.
- No `firestore.rules`/`firestore.indexes.json` changes were needed — the `memberships`/`memberIndex` admin-only write rules already existed from the architecture-foundation phase.
- `RepositoryFailureReason` gained `invalidInput`; `firestore_exception_mapper.dart` now maps `FirebaseAuthException` codes (`email-already-in-use` → `conflict`, `invalid-email`/`weak-password` → `invalidInput`) instead of collapsing every Auth error to `unauthenticated`.
- New/extended tests: `members_screen_test.dart` (5 tests), `institution_home_screen_test.dart` gained 2 tests for the Membros icon's role gating. `FakeInstitutionRepository` gained real in-memory `watchMembers`/`createMember`/`updateMemberRole`/`setMembershipStatus`.
- Live Android validation: created a member (new Auth account + both Firestore docs, admin session undisturbed), changed their role, disabled them — all reflected instantly via the Firestore stream. See `docs/TEST_STATUS.md`.

## Phase 2 continued — correctness fixes, responsibleUsers, cart edit/duplicate, product search, dashboard, history

Status: complete and validated live on the Android emulator.

- **Fix (spec section 20)**: `FirestoreInventoryRepository.createAssignment` now rejects assigning a product that is already assigned elsewhere in the same cart, throwing `RepositoryFailure(RepositoryFailureReason.conflict)`; `assignment_dialog.dart` shows a specific message for this case.
- **Fix (spec section 38)**: new `bump_layout_version.dart` helper increments `Cart.layoutVersion` after every structural drawer/slot change (`CartDetailScreen._createDrawer`, `SlotEditorScreen._save`), previously never incremented anywhere.
- New `lib/src/presentation/cart/responsible_users_screen.dart` (spec section 17): manager+ screen listing every institution member with a checkbox reflecting/toggling `CartRepository.watchResponsibleUsers`/`assignResponsibleUser`/`removeResponsibleUser` — all already fully implemented in `FirestoreCartRepository`, only the presentation layer was missing. Reachable via a new "Responsáveis" `AppBar` icon on `CartDetailScreen`.
- `CartDetailScreen` gained an overflow menu (manager+ gated) with "Editar" (`edit_cart_dialog.dart`: rename/change status via `CartRepository.updateCart`) and "Duplicar" (`duplicate_cart_dialog.dart`: creates a new cart and copies every drawer/slot, deliberately never assignments/stock/history — spec sections 39-40).
- New `lib/src/presentation/cart/product_search_screen.dart` (spec section 41's "search/list" requirement): filters a cart's assignments by product name and opens the same assignment dialog the drawer grid uses. Reachable via a new "Pesquisar produto" `AppBar` icon on `CartDetailScreen`.
- `InstitutionHomeScreen` rewritten (spec section 49, scoped down): cart-status counts and the last 5 institution-wide usage events above the cart list, plus a cart-name search field. Cross-cart per-slot expiry alerts are deliberately deferred — they would need an institution-wide `assignments` collectionGroup query and a matching Rules change.
- New `lib/src/presentation/reports/history_screen.dart` (spec section 51, scoped to its read-only "detailed view" half): a `ChoiceChip`-filterable list of every usage event with resolved product names, reachable via a new "Histórico" `AppBar` icon on `InstitutionHomeScreen` (any user). PDF/CSV export and aggregate reports are explicitly deferred.
- No repository, Firestore, or Rules changes were needed beyond `createAssignment`'s uniqueness check above — every other repository method used here (`updateCart`, `watchResponsibleUsers`/`assignResponsibleUser`/`removeResponsibleUser`, `watchRecentEvents`) already existed from earlier phases.
- `FakeInventoryRepository`/`FakeCartRepository` extended to mirror the new repository behavior (uniqueness conflict, `getCart`/`updateCart`, `responsibleUsers`).
- New/extended tests: `responsible_users_screen_test.dart` (3), `product_search_screen_test.dart` (3), `history_screen_test.dart` (3), `cart_detail_screen_test.dart` (+7: bumps-layout-version, Responsáveis shown/hidden by role, edit, duplicate-without-stock, edit/duplicate hidden for a normal user, search action shown), `institution_home_screen_test.dart` (+4: status counts, name filter, history action, recent activity), `slot_editor_screen_test.dart` (+1: refuses a duplicate product assignment). Total: 69/69 passing, `flutter analyze --no-pub` clean.
- Live Android validation: dashboard showed real status counts and recent activity; History screen's type filter narrowed the list correctly; product search found an assigned product by partial name and opened its assignment dialog directly; the overflow menu's "Editar" pre-filled the current name/status and saved correctly; "Duplicar" created a second cart with the same drawer/slot structure (confirmed the new cart's `GavetaPrincipal 3×2` matched) and no stock/history, and the dashboard's counts updated accordingly; the "Responsáveis" screen listed real institution members, correctly disabled an inactive membership's checkbox, and a toggle on an active member persisted through the Firestore emulator. No fatal `pt.icrash.app` exceptions in logcat across the whole walkthrough. See `docs/TEST_STATUS.md`.

## Phase 2 continued — GS1 Data Matrix scanning

Status: complete and validated live on the Android emulator.

- New `lib/src/services/gs1_data_matrix_parser.dart`: pure, camera-independent parser for the GS1 Application Identifiers this app needs (AI 01 GTIN, AI 10 batch/lot, AI 17 expiry — spec section 31), handling both FNC1-separated and unseparated variable-length lots and the GS1 two-digit-year convention.
- New `lib/src/services/gs1_camera_scanner_service.dart`: `MobileScannerGs1Service`, a camera-backed implementation of the pre-existing `Gs1DataMatrixScannerService` contract (spec section 32 — business logic depends only on this interface, never on `MobileScanner`), restricted to `BarcodeFormat.dataMatrix`.
- New `lib/src/presentation/scanning/gs1_scan_screen.dart`: a full-screen scanner that parses every payload it reads and pops with the first recognized result, or `null` on cancel — scanning is always optional and retryable (spec section 30), with a "Cancelar e inserir manualmente" fallback always visible.
- `AppServices` gained a `createGs1Scanner` factory (fresh `Gs1DataMatrixScannerService` per scan screen, since it owns a camera resource); `assignment_dialog.dart`'s `_Mode.replenish` gained a "Digitalizar código GS1" button (hidden on platforms `mobile_scanner` doesn't support) that pre-fills lot/expiry from a scan and resolves a scanned GTIN via `ProductRepository.findByGtin` — an unknown GTIN is never silently attached to a product (spec section 30), and a GTIN matching a different product than the slot's own only warns, never blocks, preserving the mandatory manual-fallback path.
- No repository, Firestore, or Rules changes were needed — `ProductRepository.findByGtin` and `Batch.gtin`/`Batch.source` already existed from the architecture-foundation phase; this closes the last major gap between them and the UI.
- New tests: `test/services/gs1_data_matrix_parser_test.dart` (10, pure unit tests — FNC1 handling, out-of-order AIs, the documented no-separator truncation limitation, year-window decoding, malformed input), `test/presentation/gs1_scan_screen_test.dart` (3, using a `FakeGs1DataMatrixScannerService`), plus 1 more in `slot_editor_screen_test.dart` (replenish-via-scan, including the unknown-GTIN warning). Total: 83/83 passing, `flutter analyze --no-pub` clean, `flutter build apk --debug` passing.
- Live Android validation: the "Digitalizar código GS1" button rendered correctly in the replenish form; tapping it opened the scan screen with a live camera preview and instructions; "Cancelar e inserir manualmente" correctly returned to the replenish form with the previously entered quantity intact; manual lot/expiry entry (date picker + text field) and the rest of the replenish flow worked unaffected by the new button. The AVD's virtual camera cannot produce a real scannable Data Matrix code (the same pre-existing limitation documented for the legacy QR reader since Phase 0), so the actual decode-and-prefill path was validated via the automated widget test instead, which exercises it end-to-end against a fake scanner. No fatal exceptions in logcat across the whole session. See `docs/TEST_STATUS.md`.

This completes every major workstream in the V2 specification's core scope.

## Phase 2 continued — HID barcode scanning, internal-QR cart navigation, cross-cart dashboard alerts

Status: complete and validated live on the Android emulator.

- New `lib/src/services/scanner_platform_support.dart`: `isCameraScanningSupported`, the platform check both scanning domains now share.
- New `lib/src/services/gs1_hid_scanner_service.dart`: `HidGs1ScannerService`, a second `Gs1DataMatrixScannerService` implementation for platforms `mobile_scanner` doesn't reach (Windows/Linux desktop — spec section 32's "especially important for Windows"). A HID barcode scanner behaves like a keyboard typing fast and finishing with Enter, so this only needs a focused text field, not any driver integration. `AppServices`'s real constructor now picks camera vs HID based on `isCameraScanningSupported`; `assignment_dialog.dart`'s "Digitalizar código GS1" button is unconditionally visible.
- New `lib/src/services/internal_qr_payload.dart` (pure encode/decode of `icrash://v1/cart/<institutionId>/<cartId>`) and `lib/src/services/internal_qr_camera_scanner_service.dart` (`MobileScannerInternalQrService`, implementing the previously contract-only `InternalQrScannerService`, restricted to `BarcodeFormat.qrCode`).
- New `lib/src/presentation/scanning/cart_qr_code_screen.dart` (shows a cart's QR code via the new `qr_flutter` dependency — pure Dart, works on every platform) and `cart_qr_scan_screen.dart` (full-screen scanner). `CartDetailScreen` gained a "Mostrar código QR" icon (any user with cart access); `InstitutionHomeScreen` gained a "Ler código do carro" icon (camera-platform gated) that resolves the scanned target via `CartRepository.getCart` and opens it, or shows an error if denied/not found — scanning never grants access by itself (spec section 33).
- New `AssignmentAlert`/`InventoryRules.computeAlert` (pure, `domain/inventory_rules.dart`) and `InventoryRepository.watchAllAssignments(institutionId)`, backed by a `collectionGroup('assignments')` query. Every assignment now carries denormalized `institutionId`/`cartId` fields (written once at creation, immutable afterward — enforced in `firestore.rules`). **This cross-cart alerts query and its authorizing Rule are manager+ only** — a Firestore Rules constraint discovered empirically, not a design preference; see `docs/FIREBASE_MODEL.md`, "Why the cross-cart alerts query is manager+ only", for the full story (a `list` rule can only safely reference fields the query itself filters on). `InstitutionHomeScreen` gained a manager+-gated "Alertas" section.
- `firestore.rules` gained a `{path=**}/assignments/{assignmentId}` collection-group rule and immutability constraints on the new `institutionId`/`cartId` fields; `firestore.indexes.json` gained a matching `COLLECTION_GROUP` index. `firestore-tests/rules.test.mjs` gained 5 new tests.
- New tests: `test/services/internal_qr_payload_test.dart` (5), `test/services/gs1_hid_scanner_service_test.dart` (2), `test/presentation/cart_qr_scan_screen_test.dart` (3), 1 more in `test/presentation/gs1_scan_screen_test.dart` (HID text-field flow), 2 more in `test/presentation/cart_detail_screen_test.dart`/`test/presentation/institution_home_screen_test.dart` each for the QR icons, 8 for `InventoryRules.computeAlert` in `test/domain/inventory_rules_test.dart`, 3 for `_CrossCartAlerts` rendering. Total: 108/108 passing, `flutter analyze --no-pub` clean, `flutter build apk --debug` passing.
- Live Android validation: cart QR code rendered correctly with the cart's name and payload; the internal-QR scan screen opened with a live camera preview restricted to QR codes; "Digitalizar código GS1" (now unconditionally visible) opened correctly. Created a real product/drawer/assignment/replenishment live with a 10-day-out expiry, then confirmed the "Alertas" section on the institution dashboard correctly showed "A expirar em breve · Adrenalina · Carro de Emergência 1". No fatal exceptions in logcat. One operational note: running the Firestore Rules test suite against the same long-lived emulator used for manual live testing clears all seeded app data via `clearFirestore()` — hit mid-session, resolved by re-running `npm --prefix firestore-tests run seed`. See `docs/TEST_STATUS.md`.

## Phase 2 continued — history CSV export and per-product summary

Status: complete and validated live on the Android emulator.

- New `lib/src/presentation/reports/history_csv_export.dart`: `buildHistoryCsv`, a pure function turning a filtered `UsageEvent` list into a CSV string (Data/Tipo/Produto/Quantidade, RFC-4180-style quoting for commas/quotes in product names). `HistoryScreen` gained an "Exportar CSV" button showing the result in a `SelectableText` dialog with a "Copiar" action (`Clipboard.setData`) — scoped to clipboard-copy rather than a file download, to avoid adding a `path_provider`/`share_plus` dependency for a prototype-phase feature (spec section 51's export requirement).
- New `lib/src/presentation/reports/history_summary.dart`: `summarizeByProduct`, a pure function grouping the same filtered events by product into consumed/replenished/other-adjustments totals. `HistoryScreen` gained a "Ver resumo" button showing the result in a dialog. Per-cart/per-period aggregates remain deferred (spec section 51).
- No repository, Firestore, or Rules changes were needed — both features work entirely from the `UsageEvent`/`Product` data `HistoryScreen` already fetches.
- New tests: `test/presentation/history_csv_export_test.dart` (5), `test/presentation/history_summary_test.dart` (5), 2 more in `test/presentation/history_screen_test.dart` (export-to-clipboard, shows-summary). Total: 120/120 passing, `flutter analyze --no-pub` clean, `flutter build apk --debug` passing.
- Live Android validation: "Ver resumo" and "Exportar CSV" both render next to the type filter chips; "Ver resumo" against real seeded data showed "Adrenalina — Consumido: 0 Reposto: 5"; "Exportar CSV" showed the correct header row and a data row matching the same event, and "Copiar" showed a "CSV copiado." confirmation. No fatal exceptions in logcat.

See `MODERNIZATION_2026.md` for the baseline modernization and `ICRASH_V2_SPECIFICATION.md` for the authoritative V2 scope.
