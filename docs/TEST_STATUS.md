# Test status

Updated: 2026-09-10

## Phase 2, accessibility/performance/offline-reconnection review — Android emulator live validation

Full walkthrough on `ICrash_API_36`, signed in as the seeded `institutionAdmin`, covering workstream J's accessibility review, performance review, and offline/reconnection UX (see `docs/IMPLEMENTATION_STATUS.md` for what each pass found and fixed):

- Accessibility: no separate live pass beyond re-running the full widget suite (120/120 unchanged) — the two fixes (`Semantics` on `SlotEditorScreen`'s grid cells and `CartQrCodeScreen`'s QR image) are additive semantic metadata with no visual/behavioral change, so `flutter analyze`/`flutter test` plus a visual spot-check of both screens (unchanged rendering, confirmed via screenshot) was the appropriate validation depth here.
- Performance: same — the stream-caching fix changes *when* a Firestore listener resubscribes, not what renders, so validation was the automated suite (120/120 unchanged) plus a live spot-check on `InstitutionHomeScreen` (the worst instance, three listeners) confirming the cart list/alerts/recent-activity sections all still update live while typing in the "Pesquisar carro" field, with no visible flicker or reload.
- Offline banner, initial render: WORKING with one issue found and fixed. With wifi and mobile data disabled (`adb shell svc wifi disable && adb shell svc data disable`), a red banner "Sem ligação à internet — a mostrar dados guardados localmente." appeared at the top of the screen immediately, above the existing "Escolher instituição" content, which kept showing the previously-loaded "Hospital de Teste" from Firestore's local cache. First screenshot showed the banner text rendered with a debug-mode red/yellow squiggly underline (missing-`Material`-ancestor artifact, since the banner sits directly under `MaterialApp.builder`, outside any screen's own `Scaffold`).
- Offline banner, after fix: WORKING. Wrapped the banner's content in its own `Material` + `SafeArea(bottom: false, ...)`; rebuilt, reinstalled, relaunched while still offline — banner re-rendered cleanly with no artifact, same text, same position, cached institution list still showing underneath.
- Reconnection: WORKING. Re-enabling wifi/data (`adb shell svc wifi enable && adb shell svc data enable`) made the banner disappear on the next `onConnectivityChanged` event, with the underlying screen unaffected.
- No fatal `pt.icrash.app` exceptions in logcat across the whole session (`adb logcat -d -s AndroidRuntime:E flutter:E *:F` empty).

No new Firestore Rules were needed for any of these three — accessibility/performance are presentation-layer-only changes, and the connectivity banner reads no Firestore data at all (`connectivity_plus` is a pure device-connectivity plugin).

## Phase 2, history CSV export and per-product summary — Android emulator live validation

Full walkthrough on `ICrash_API_36`, on `HistoryScreen` against real seeded data (one "Reposição · Adrenalina (+5)" event from the prior live-testing session):

- "Ver resumo"/"Exportar CSV" buttons: WORKING. Both render next to the type-filter chips, above the event list.
- Per-product summary: WORKING. Tapping "Ver resumo" opened a dialog showing "Adrenalina" with "Consumido: 0   Reposto: 5" — correct given the single seeded replenishment event.
- CSV export: WORKING. Tapping "Exportar CSV" opened a dialog showing the exact expected CSV: header row `Data,Tipo,Produto,Quantidade` followed by `10/09/2026 14:04,Reposição,Adrenalina,+5`. Tapping "Copiar" showed a "CSV copiado." confirmation.
- No fatal `pt.icrash.app` exceptions in logcat.

No new Firestore Rules were needed — both features are pure functions over data `HistoryScreen` already fetches.

## Phase 2, HID barcode scanning / internal-QR cart navigation / cross-cart dashboard alerts — Android emulator live validation

Full walkthrough on `ICrash_API_36`, against local emulators re-seeded mid-session via `firestore-tests/seed_emulator.mjs` (see the operational note below), signed in as the seeded `institutionAdmin`:

- Cart QR code display: WORKING. "Mostrar código QR" on the cart detail screen opened `CartQrCodeScreen`, rendering the cart's name and a real QR image (`qr_flutter`) encoding its `icrash://v1/cart/...` payload.
- Internal-QR scan screen: WORKING. "Ler código do carro" on the institution home screen opened a full-screen scanner with a live camera preview restricted to QR codes (confirmed the virtual camera feed rendered, same as the GS1 scanner), instructions, and a "Cancelar" fallback that correctly returned to the dashboard.
- GS1 scan button always visible: WORKING. Confirmed "Digitalizar código GS1" renders in the replenish form with no platform gate now applied (previously hidden when unsupported; HID now covers those platforms instead).
- Cross-cart alerts, full live scenario: WORKING end-to-end. Created a new product ("Adrenalina"), a new drawer, assigned the product to a slot, then replenished it with a lot number and an expiry date 10 days out (within the institution's default 30-day `expiryWarningDays`) — all via the ordinary UI. Returning to the institution dashboard showed a new "Alertas" section reading "A expirar em breve · Adrenalina · Carro de Emergência 1", confirming the manager+-gated `collectionGroup('assignments')` query, `InventoryRules.computeAlert`, and the `_CrossCartAlerts` widget all work correctly together against the real Firestore emulator, not just fakes.
- No fatal `pt.icrash.app` exceptions in logcat across the whole session.

**Operational note, not an app bug**: mid-session, running `npm --prefix firestore-tests test` (to verify the new `firestore.rules` collection-group rule) against the *same* long-lived Firestore emulator instance used for this manual live-testing session wiped all seeded app data — the rules test suite's `beforeEach(() => testEnv.clearFirestore())` operates on whatever emulator is listening on `127.0.0.1:8081`, shared or not. Discovered when the app suddenly showed "Ainda não tem acesso a nenhuma instituição" after a routine reinstall; resolved by re-running `npm --prefix firestore-tests run seed`. Anyone continuing a live-validation session should re-run the Firestore Rules test suite *before* starting manual testing, or run it against a separate emulator instance, not interleaved with a manual session.

**Live-testing note, not an app bug**: reproducing a Firestore Rules `list`-query bug required several iterations of a throwaway Node probe script (since deleted) directly against the emulator, isolating the exact failure down to a rule referencing a `resource.data` field the query itself didn't filter on. See `docs/FIREBASE_MODEL.md`, "Why the cross-cart alerts query is manager+ only", for the full empirical account — this is the same class of Firestore-emulator quirk already documented for `memberIndex`, but a different specific failure mode.

## Phase 2, GS1 Data Matrix scanning — Android emulator live validation

Full walkthrough on `ICrash_API_36`, against local emulators seeded via `firestore-tests/seed_emulator.mjs`, signed in as the seeded `institutionAdmin`, on the "Adrenalina" assignment (3/1) in "Carro de Emergência 1":

- Scan button: WORKING. "Digitalizar código GS1" renders inside "Repor stock" between the amount field and the lot field.
- Scan screen: WORKING. Tapping it opens a full-screen scanner with a live camera preview (the emulator's virtual camera feed rendered, confirming `MobileScanner` initializes and streams frames correctly on this device), instructions text, and an always-visible "Cancelar e inserir manualmente" fallback.
- Cancel/manual fallback: WORKING. Cancelling returned to the replenish form with the previously entered "Quantidade recebida" (5) still intact, confirming the scan flow is non-destructive to in-progress manual entry.
- Manual entry after cancelling: WORKING. Lot number text field and the expiry date picker both worked as before, unaffected by the new button; "Validade: 30/09/2026" and "LOTE-MANUAL" both entered and displayed correctly.
- Decode-and-prefill path: NOT independently live-verifiable — the AVD's virtual camera cannot produce a real scannable GS1 Data Matrix code, the same pre-existing limitation recorded for the legacy QR reader since Phase 0 (`docs/TEST_STATUS.md`'s "Android walkthrough" section). This path (parse → prefill lot/expiry → resolve GTIN → warn on mismatch/unknown → submit with `Batch.source = gs1DataMatrix`) is instead covered end-to-end by an automated widget test using a fake scanner (`slot_editor_screen_test.dart`'s "replenishes stock by scanning a GS1 code" test), which is the same testing strategy the specification itself prescribes for scanner code (spec section 5: "create testable scanner abstractions and mock GS1/Data Matrix inputs").
- No fatal `pt.icrash.app` exceptions in logcat across the whole session (checked both mid-session and at the end, spanning the earlier responsibleUsers/cart-edit-duplicate/product-search/dashboard/history walkthrough below and this one).

No new Firestore Rules were needed — `ProductRepository.findByGtin` and `Batch.gtin`/`Batch.source` already existed from the architecture-foundation phase.

**Live-testing note**: while validating this, a live tap-coordinate mistake (not an app bug) briefly looked like a real one — tapping what appeared visually to be the non-duplicate "Carro de Emergência 1" card on the dashboard actually landed inside the "(cópia)" card's tap target one row above it, so "Pesquisar produto" correctly reported no results for a cart that genuinely has no assignments (duplication never copies assignments, by design). Resolved by cross-checking the Firebase Emulator UI's Firestore data browser directly (confirming the assignment and its product both exist and reference each other correctly) and then `adb shell uiautomator dump` for the exact on-screen bounds of each cart card, rather than trusting a screenshot's visual proportions for tap coordinates.

## Phase 2, correctness fixes/responsibleUsers/cart edit-duplicate/product search/dashboard/history — Android emulator live validation

Full walkthrough on `ICrash_API_36`, against local emulators already seeded via `firestore-tests/seed_emulator.mjs`, signed in as the seeded `institutionAdmin`, continuing from "Hospital de Teste" with one cart ("Carro de Emergência 1", one drawer "GavetaPrincipal" 3×2):

- Dashboard: WORKING. Institution home now shows "Operacional: 1" status chip and "Atividade recente" with 4 real historical usage events (correction/reconciliation/consumption/replenishment) using the correct PT-PT type labels and signed amounts, above the existing cart list and a new "Pesquisar carro" name-filter field.
- History screen: WORKING. New "Histórico" `AppBar` icon opens a full event list; tapping the "Consumo" `ChoiceChip` correctly narrowed it to just the consumption event.
- Product search: WORKING. New search icon on the cart detail screen; typing "Adren" found "Adrenalina 3/1" and tapping it opened the assignment dialog directly in view mode ("Atual: 3 Alvo: 1") with all its action buttons.
- Cart edit: WORKING. The overflow menu's "Editar" opened pre-filled with the cart's current name and status ("Operacional"); "Cancelar" left the cart unchanged.
- Cart duplicate: WORKING. "Duplicar" opened pre-filled with "Carro de Emergência 1 (cópia)" and explicit copy-scope text ("Não copia produtos, stock nem histórico."); confirming created the second cart with the same drawer ("GavetaPrincipal", 3×2) and no stock/history, and the dashboard's status count updated to "Operacional: 2" immediately via the Firestore stream.
- Responsible users: WORKING. New "Responsáveis" `AppBar` icon lists every institution member (shown by uid, since no display names exist in this seed data) with their role; the seeded manager-role membership's checkbox was correctly disabled (inactive membership), and toggling the active institution-admin's checkbox on and off both persisted immediately through the Firestore emulator (`watchResponsibleUsers` stream reflected each change without a manual refresh).
- Product uniqueness / layout versioning fixes: covered by automated tests only this round (`slot_editor_screen_test.dart`'s new "refuses duplicate product assignment" test, and the two edit/duplicate tests exercising `bumpCartLayoutVersion` indirectly) — not separately re-verified live beyond what the flows above already exercise (creating a drawer, saving a slot layout).
- No fatal `pt.icrash.app` exceptions in logcat across the whole walkthrough.

No new Firestore Rules were needed — `updateCart`, `watchResponsibleUsers`/`assignResponsibleUser`/`removeResponsibleUser`, and `watchRecentEvents` were already institution/role-scoped from earlier phases; only `createAssignment`'s new uniqueness check is new repository logic, and it needed no Rules change since it is enforced above the Rules layer.

## Phase 2, audit reconciliation and event correction — Android emulator live validation

Full walkthrough on `ICrash_API_36`, continuing from the assigned "Adrenalina" slot (3 units after the earlier replenishment/consumption walkthrough), signed in as the seeded `institutionAdmin`:

- Reconciliation: WORKING. "Reconciliar" (manager+) showed the assignment's one recorded batch ("LOTE123") pre-checked and the confirmed-quantity field pre-filled with the current value (3). Unchecking the batch (simulating "not physically found") and setting the confirmed quantity to 2, then confirming, updated the cell to "2/1" and replaced the stored batch set with none, via `InventoryRepository.reconcileAfterAudit`.
- Correction: WORKING. "Corrigir" (available to anyone with cart access, not just managers) listed the assignment's usage events with the most recent (the reconciliation just performed, "Reconciliação: -1") pre-selected and the adjustment field pre-filled with `-event.amount` (i.e. a one-tap "undo"). Confirming with the default +1 adjustment updated the cell back to "3/1" via `InventoryRepository.recordCorrection`, referencing the reconciliation event's id without modifying it.
- Role gating confirmed both live and in `slot_editor_screen_test.dart`: "Repor stock"/"Reconciliar" require manager+ (Rules reserve `earliestKnownExpiry`/`batches` writes to manager+); "Corrigir"/"Registar consumo" are available to anyone with cart access (Rules let a non-manager change only `currentQuantity`).
- No fatal `pt.icrash.app` exceptions in logcat.

No new Firestore Rules were needed — `assignments`/`batches`/`usageEvents` write rules already covered these operations exactly as designed from the architecture-foundation phase.

## Phase 2, product catalogue and slot assignments — Android emulator live validation

Full walkthrough on `ICrash_API_36`, against local emulators seeded via `firestore-tests/seed_emulator.mjs`, signed in as the seeded `institutionAdmin`:

- Products screen: WORKING. Reachable via a new "Produtos" `AppBar` icon on the institution home screen (manager+ only). Empty state, then created "Adrenalina" via the "Novo produto" dialog; appeared in the list immediately.
- Slot assignment: WORKING. Long-pressing an unassigned slot in the slot editor opens "Atribuir produto" (manager+); picking "Adrenalina" with quantities 0/1 created the assignment, and the slot's cell immediately showed "Adrenalina" and "0/1" (current/target) via the live `watchAssignments` stream.
- Replenishment: WORKING. Long-pressing the assigned slot opened its detail dialog ("Atual: 0 Alvo: 1", status chip "OK"); "Repor stock" (manager+) with quantity 5, lot "LOTE123" and an expiry date (via `showDatePicker`) updated the cell to "5/1" and recorded a `Batch` + `usageEvents` doc through `InventoryRepository.recordReplenishment`'s transaction.
- Consumption: WORKING. "Registar consumo" with quantity 2 updated the cell to "3/1", confirming `recordConsumption`'s transaction decremented `currentQuantity` without touching the batch just recorded.
- No fatal `pt.icrash.app` exceptions in logcat across the whole walkthrough.

No new Firestore Rules were needed — `products`/`assignments`/`batches` were already institution-scoped and role-scoped from the architecture-foundation phase (manager+ for `create`/replenishment-shaped updates, any cart-accessible member for consumption-shaped updates).

**Live-testing note**: a `TextFormField`'s actual tap target in this Material theme extends beyond its visible text line to include its label/helper-text band, so two vertically-stacked fields' tap targets can be much closer together than they look in a screenshot — a tap aimed at the second field's visible text row can still land inside the first field's (taller) tap target. Confirmed via `uiautomator dump`'s exact `EditText` bounds rather than guessing from screenshot pixel rows.

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

- `flutter analyze --no-pub`: passed, no issues, throughout — including after the correctness fixes/responsibleUsers/cart edit-duplicate/product search/dashboard/history changes and after GS1 Data Matrix scanning.
- `flutter test --no-pub`: passed, **120 tests** as of this round (up from 108, 83, 69, 48 before that) — `test/domain/inventory_rules_test.dart` (19: 11 conservative-expiry/lot tests including the two literal critical inventory scenarios from spec sections 58-59, plus 8 for `InventoryRules.computeAlert`'s cross-cart alert logic), `test/services/gs1_data_matrix_parser_test.dart` (10, pure GS1 AI parsing), `test/services/internal_qr_payload_test.dart` (5), `test/services/gs1_hid_scanner_service_test.dart` (2), `test/presentation/history_csv_export_test.dart` (5, new: header+row shape, timestamp formatting, missing-product placeholder, comma-quoting, empty list), `test/presentation/history_summary_test.dart` (5, new: consumed/replenished split, other-adjustments net, per-product grouping/sort, missing-product placeholder, empty list), `test/widget_test.dart` (legacy `HomeMenu` smoke test), and presentation-layer suites using fakes from `test/fakes/fake_repositories.dart`: `login_screen_test.dart` (3), `institution_selection_screen_test.dart` (3), `institution_home_screen_test.dart` (16), `members_screen_test.dart` (5), `cart_detail_screen_test.dart` (12), `slot_editor_screen_test.dart` (12), `products_screen_test.dart` (4), `responsible_users_screen_test.dart` (3), `product_search_screen_test.dart` (3), `history_screen_test.dart` (5: the 3 from before plus export-to-clipboard/shows-summary), `gs1_scan_screen_test.dart` (4), `cart_qr_scan_screen_test.dart` (3).
- `flutter build apk --debug --no-pub`: passed, confirming the Firebase bootstrap (emulator-by-default in debug, cloud in release) compiles end to end on Android.
- `firebase emulators:exec --only firestore --project demo-icrash-v2 "npm --prefix firestore-tests test"`: passed, **27/27** Firestore Rules tests (up from 22) — spec section 60's security scenarios, the `memberIndex` collection-group query, and the new `assignments` collection-group query (manager sees every cart's assignments, normal user and cross-institution user are both denied outright, `institutionId`/`cartId` must match their document's own path at creation and can never change afterward).
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

Physical-camera QR/GS1 validation, backend flows, and permissions UI remain untested. A basic offline/reconnection UX (connectivity banner) is now live-validated — see the accessibility/performance/offline review section above — but broader domain scenarios around offline are still open: multi-lot replenishment through the real repository against the emulator while offline, and offline queued writes replaying against Rules once reconnected, have not been exercised. Security Rules have automated coverage (see Phase 2 above), but only for the scenarios in spec section 60. Scanner abstractions and mock GS1 inputs belong to later phases. iOS/macOS cannot be claimed from Windows. The complete screen classification is deferred until V2 screens replace the legacy ones, as required by the specification.

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
