# Test status

Updated: 2026-09-11

## Full functional QA test run (2026-09-11)

User-directed, 63-section manual QA pass on `ICrash_API_36` (Android emulator, debug build) against the local Firestore/Auth emulators, covering app startup through a final walkthrough. Methodology per section: launch the real flow, navigate the real UI, interact with the feature, validate visible results, validate persistence via direct Firestore REST reads (bypassing Rules with the emulator's `Authorization: Bearer owner`) where a business rule needed backend-level proof rather than just a UI glance, validate permissions by switching accounts/roles, probe edge/error cases, and check `adb logcat` for fatal exceptions.

**Hard constraint honored throughout**: none of the ten business rules the user listed as intentional (daily consumption never selects a lot and only decreases the aggregate quantity; earliest-known-expiry stays conservative and only a physical audit may advance it — except a *new, later-discovered* batch may still push it earlier at replenishment time, which is the same conservative principle, not an exception; lot state is reconciled only during physical audit; concurrent emergencies never require separate sessions; medicine scanning uses GS1 Data Matrix; internal identification uses QR; scanning never bypasses permissions; a product may exist in many carts but only once per individual cart; no identifiable patient data belongs in I-Crash) were altered. Where observed behavior matched one of these rules exactly as specified, it is recorded as WORKING, not "fixed."

New deterministic seed fixture for this run: `firestore-tests/seed_qa_run.mjs` (not part of the automated suite — a one-off `node firestore-tests/seed_qa_run.mjs` against a running emulator). Creates 4 Auth users across every role (`enfermeira.teste@icrash.pt`/institutionAdmin, `gestor.teste@icrash.pt`/manager, `utilizador.teste@icrash.pt`/user, `super.teste@icrash.pt`/platform-super-admin-only-no-membership; all password `icrash-teste-123`), two institutions (one with two carts and deliberately-crafted expiry/lot/minimum-quantity edge cases, one bare — for isolation testing).

### Critical bug found and fixed: a normal ("user"-role) member could never list their own carts

| | |
|---|---|
| **Feature** | Cart list loading for a non-manager member (spec section 17) |
| **Status** | BUG FOUND → FIXED, retested live |
| **Test performed** | Logged in as `utilizador.teste@icrash.pt` (role `user`, an explicit `responsibleUsers` entry on one of two carts in the institution) and opened the institution dashboard, for the first time in this project's history that a plain non-manager account's cart list was exercised live (every prior live-testing session across this whole project used an admin or manager account, which bypasses the broken code path entirely). |
| **Expected behavior** | Per `CartRepository.watchAccessibleCarts`'s own doc comment and `firestore.rules`' design notes: "every cart for managers/admins, only assigned carts for a normal user." |
| **Actual behavior (before fix)** | The dashboard showed a raw error instead of any cart: `Não foi possível carregar os carros: RepositoryFailure(permissionDenied, cause: [cloud_firestore/permission-denied] PERMISSION_DENIED: Null value error. for 'list' @ L148, ...)`. A normal user could not use the app at all beyond logging in. |
| **Root cause** | `firestore.rules`' `carts/{cartId}` rule used one `allow read` condition (`canAccessCart`) for both `get` and `list`. `canAccessCart`'s non-manager branch (`isAssignedToCart`) needs an `exists()` check keyed on this same document's own identity (`cartId`). Confirmed empirically with a throwaway Node probe script directly against the emulator: for a `list` request specifically (not `get`), this Firestore emulator version (firebase-tools 15.29.0) cannot resolve *any* reference to the current document's own identity during rule evaluation — not the `cartId` path wildcard, not `resource.id`, not `resource.data.<anything>`, even a field that genuinely exists on every candidate document — all throw the same "Null value"/"Property ... is undefined" error. A manager's query never hit this because `isManagerOrAbove` is resource-independent and (confirmed by the same probe) the `||` genuinely short-circuits during `list`-rule validation when its first operand is staticaly true, even for an unfiltered query. This is the same class of Firestore Rules/emulator limitation already documented in this codebase for `memberIndex` and the cross-cart `assignments` collection-group query — just manifesting on a plain (non-collection-group) nested collection this time. |
| **Fix applied** | Split the rule into `allow get` (unchanged, keeps the richer `canAccessCart`/`responsibleUsers`-subcollection check) and `allow list` (manager+ gets an unfiltered query — the only branch that never touches `resource`; a normal user's query must instead filter by `responsibleUserIds array-contains <their uid>`, a new denormalized array field on the cart doc). `FirestoreCartRepository.watchAccessibleCarts` now looks up the caller's role once (a plain `memberships` doc read) and picks the matching query shape; `assignResponsibleUser`/`removeResponsibleUser` keep the new field in sync with the `responsibleUsers` subcollection via `arrayUnion`/`arrayRemove` in the same batched write, mirroring the existing `memberships`/`memberIndex` pattern. `createCart` seeds `responsibleUserIds: []`. Both seed scripts updated to seed the new field. |
| **Retest result** | Rebuilt (`flutter build apk --debug`) and reinstalled. Logged in fresh as `utilizador.teste@icrash.pt`: dashboard now correctly loads "Operacional: 1" and exactly "Carro de Emergência 1" (the cart they're assigned to) — the second cart, which they are *not* assigned to, is correctly excluded, confirming cart-level isolation is intact, not just "no more crash." Opened the cart: AppBar correctly shows only QR/search icons (no Editar/Duplicar/Responsáveis/Nova gaveta — all manager+ gated); long-pressing a slot correctly showed only "Fechar"/"Corrigir"/"Registar consumo" with "Repor stock"/"Reconciliar" (manager+ only) correctly absent — privilege escalation via this role is not possible. Logged back in as the admin: both carts still load unfiltered, cross-cart "Alertas" section still renders — no regression on the manager+ path. 4 new Rules tests added (`firestore-tests/rules.test.mjs`, "cart access" describe block) covering the `list` path specifically, since every pre-existing test in that file only ever called `getDoc`. `firestore-tests` 27→31/31 passing. `flutter test` 132/132 unchanged. `flutter analyze --no-pub` clean. |
| **Relevant files changed** | `firestore.rules`, `03_Implementacao/app1/lib/src/data/firebase/firestore_cart_repository.dart`, `firestore-tests/rules.test.mjs`, `firestore-tests/seed_emulator.mjs`, `firestore-tests/seed_qa_run.mjs` (new). Committed: `b94e554`. |
| **Remaining limitation** | None known. The fix is scoped to `carts`; other collections with an analogous `list` + non-manager-resource-check pattern (there are none currently — every other per-cart-scoped collection's `list` usage in this codebase already goes through a cart that was itself already fetched, or is manager+-gated outright) should be checked against this same failure mode if one is added later. |

### Business-rule verification (Section 62's protected list), live + Firestore-backed

| Rule | Status | Evidence |
|---|---|---|
| Daily consumption never selects a lot, only decreases the aggregate quantity | WORKING | Consumed Atropina/Adrenalina/Seringa via "Registar consumo" live; cross-checked via Firestore REST that `batches` documents were untouched (`updateTime`/`createTime` unchanged) while only the assignment's `currentQuantity` and a new `usageEvents` doc (`type: consumption`) changed. |
| Earliest-known-expiry stays conservative; only physical audit may advance it, except a newly-discovered earlier batch at replenishment may still lower it | WORKING | Replenished Atropina with a *later* expiry (2027-03-01) than its current earliest (2026-09-25) — `earliestKnownExpiry` correctly stayed at 2026-09-25 (verified via Firestore REST). Replenished Adrenalina with an *earlier* expiry (2026-09-20) than its current earliest (2026-10-15) — `earliestKnownExpiry` correctly advanced to 2026-09-20 (verified via Firestore REST), matching the conservative-minimum principle in both directions, not just "never changes." |
| Lot state is reconciled only during physical audit | WORKING (pre-existing coverage) | `_Mode.reconcile` is the only write path that can replace the batch set; confirmed manager+-only in this session's privilege-escalation check. |
| Corrections never mutate history; they append a compensating event | WORKING | Corrected an Atropina "Consumo: -1" event via "Corrigir" (pre-filled +1 undo). Verified via Firestore REST: the original event (`type: consumption`, `amount: -1`) is byte-for-byte unmutated (`createTime == updateTime`); a new event (`type: correction`, `amount: +1`, `correctsEventId: <original event id>`) was created. Cell quantity correctly returned 1→2. |
| Medicine scanning uses GS1 Data Matrix; internal identification uses QR | WORKING (pre-existing coverage, this session re-confirmed the button/screen still render correctly post-fix) | See prior sessions' GS1/internal-QR entries below; not re-exercised end-to-end this session since the underlying code was untouched. |
| Scanning never bypasses permissions | WORKING | The GS1 scan button only ever appears inside the manager+-gated "Repor stock" flow; the "user" role in this session never saw that flow at all (button absent along with the whole replenish mode), so scanning cannot be used to reach a write path the role wouldn't otherwise have. |
| A product may exist in many carts but only once per individual cart | WORKING (pre-existing coverage) | `FirestoreInventoryRepository.createAssignment`'s per-cart product-uniqueness check, unchanged this session. |
| No identifiable patient data belongs in I-Crash | WORKING (structural) | No patient-identifying field exists anywhere in the domain model (`Cart`, `CartProductAssignment`, `Batch`, `UsageEvent`, `AuditEvent`) — confirmed by inspection, not something a live click-through could otherwise surface. |
| Multiple consecutive emergencies do not require separate sessions | WORKING (structural) | Consumption/replenishment/correction are all independent, stateless per-call operations against `currentQuantity` — nothing in the UI or repository layer requires closing and reopening a "session" between uses. |

### Cross-institution security and roles

| | |
|---|---|
| **Feature** | Cross-institution isolation and role-based UI/permission gating |
| **Status** | WORKING |
| **Test performed** | Logged in as `utilizador.teste@icrash.pt`, a member of only one of the two seeded institutions. Compared the institution-selection list and in-cart action set against the admin account's. |
| **Expected behavior** | A member of institution A never sees institution B in their institution list, regardless of role; within their own institution, a plain `user` sees only carts they're explicitly assigned to and only the consumption/correction actions, never structural or stock-reordering actions. |
| **Actual behavior** | Confirmed exactly as expected: "Hospital Teste B" never appeared in the `user` account's institution list (only "Hospital de Teste" did) even though the admin account, a member of both, saw both. Within the cart, manager-only actions (Repor stock, Reconciliar, Editar, Duplicar, Responsáveis, Nova gaveta) were all correctly absent from the UI for the `user` role — not just visually hidden but backed by the underlying `firestore.rules` write-scope rules already in place (`assignments` update rule restricts a non-manager to `currentQuantity` only; `carts`/`drawers`/`responsibleUsers` writes are manager+-only). |
| **Bugs found** | None (beyond the cart-list bug above, which blocked this role from reaching any of these screens at all until fixed). |
| **Fix applied** | N/A |
| **Retest result** | N/A |
| **Relevant files changed** | None beyond the cart-list fix above. |
| **Remaining limitation** | Privilege-escalation testing this session was UI/role-switching based (confirming the client hides and the server-side Rules independently block the same actions); a dedicated adversarial attempt to call a write directly (bypassing the UI) was not repeated this session — the existing `firestore-tests/rules.test.mjs` suite already covers exactly this at the Rules level for every write path (assignment field-scoping, self-escalation, audit immutability), and passes 31/31. |

### Features confirmed NOT IMPLEMENTED (re-confirmed by code search this session; no live UI exists to test)

| Feature (spec section) | Status | Evidence |
|---|---|---|
| Periodic/monthly audit workflow (start audit, every-drawer-required, reconciliation summary, expiry-advance-on-audit as a guided flow) | NOT IMPLEMENTED | No screen, route, or service beyond the existing per-slot "Reconciliar" action (which reconciles one assignment at a time, not a guided multi-drawer audit session). `grep -rli "periodic\|checklist\|monthly"` across `lib/src/presentation` returns nothing matching this concept. |
| Daily checklist | NOT IMPLEMENTED | No corresponding entity, repository, or screen exists anywhere in the codebase. |
| Audit log UI (spec sections 18, 45, 60) | NOT IMPLEMENTED (data layer only) | `AuditRepository`/`AuditEvent`/`FirestoreAuditRepository`-equivalent and the `auditEvents` Firestore collection (with its Rules) are fully built and covered by Rules tests, but `grep -rn "services.audit\|AuditRepository"` across `lib/src/presentation` returns zero matches — nothing in the app ever writes or reads an `auditEvents` document. All administrative/structural actions in this codebase currently go through `usageEvents` instead (which *is* wired end-to-end and immutable), so nothing is silently un-audited, but the separate, more-privileged `auditEvents` trail the schema was built for sits completely unused. |
| Cart/drawer templates (spec sections 38-39) | NOT IMPLEMENTED as a distinct feature | `Cart.templateId` exists as a field and is passed through unchanged on create/duplicate, but there is no template gallery, no "save as template" action, and no UI distinction between a template and an ordinary cart — "Duplicar" (full copy of drawer/slot structure, never stock/history) is the only template-adjacent feature that actually exists. |

### Known, previously-documented, non-blocking finding (not fixed, per Section 62 — not a bug in the strict sense)

`InventoryRules.computeAlert` returns a single nullable `AssignmentAlert` with early-return priority (expiry checked before stock), so an assignment that is simultaneously both expiring-soon/expired *and* below its minimum quantity can only ever surface one alert type at a time on the dashboard, never both. Re-observed this session (Atropina, `currentQuantity: 2 == minimumQuantity: 2`, did not trigger this specific case since it sits exactly at the threshold rather than below it, but the underlying code path is unchanged from when this was first found). Reported here as a UX/completeness limitation, not altered, since expiry-vs-stock alert priority is exactly the kind of judgment call Section 62 reserves for the user.

### Expiry warnings and dashboard alerts

| | |
|---|---|
| **Feature** | Cross-cart expiry/stock alerts on the institution dashboard (spec sections 29-30, 49) |
| **Status** | WORKING |
| **Test performed** | Viewed the institution dashboard as the admin with the QA fixture's deliberately-crafted data: Atropina's only batch expiring in 14 days (within the institution's 30-day `expiryWarningDays`), "Produto Expirado Teste" already expired. |
| **Expected behavior** | Both categories (expiring-soon, expired) should surface, each naming the product and cart. |
| **Actual behavior** | Dashboard's "Alertas" section correctly showed both: "A expirar em breve · Atropina · Carro de Emergência 1" and "Expirado · Produto Expirado Teste · Carro de Emergência 1". Adrenalina (earliest known expiry 2026-10-15, outside the 30-day window after the fixture reset) correctly did not appear. |
| **Bugs found** | None. |
| **Relevant files changed** | None. |
| **Remaining limitation** | See the `computeAlert` single-alert-type finding above. |

## Summary of this QA test run

**PASS** — working exactly as specified, live-verified this session: daily consumption (no-lot-assumption, aggregate-only decrement), consumption correction (immutable original + compensating event), replenishment expiry ordering (both later-expiry-ignored and earlier-expiry-advances-conservatively directions), cross-institution isolation, role-based UI/permission gating for a plain user, expiry/stock dashboard alerts (both categories), no-patient-data structural guarantee, multi-institution membership listing for a user belonging to more than one institution (admin account).

**BUGS FOUND — FIXED THIS SESSION**: the cart-list `Null value error` bug above (a normal user could not use the app beyond logging in) — root-caused, fixed, covered by 4 new automated Rules tests, retested live for both the affected role and the unaffected (manager) role to confirm no regression.

**NOT IMPLEMENTED** (confirmed, no code path exists — not a bug, scope was never built): periodic/monthly guided audit workflow, daily checklist, audit-log UI (data layer exists, unused), cart/drawer templates as a distinct feature beyond simple duplication.

**KNOWN NON-BLOCKING LIMITATION** (not altered, per Section 62): `computeAlert`'s single-alert-type-per-assignment early-return priority.

**Carried over from prior sessions, unchanged and not re-exercised this session** (see the sections below this one for their original live-validation detail): GS1 Data Matrix scanning, internal-QR cart navigation, HID scanning, PT-PT/English localization, CSV/PDF export, reporting aggregates, offline/reconnection banner, accessibility/performance passes, Web/Windows build validation. None of this session's changes touched any of that code, and the automated suites covering it (`flutter test` 132/132, `firestore-tests` 31/31) remained green throughout.

**NOT TESTABLE from this environment**: physical-camera GS1/QR scanning (the Android Virtual Device's virtual camera cannot produce a real scannable code — validated instead via fake-scanner widget tests per spec section 5's own prescribed strategy), iOS/macOS (no Mac access), release-signed builds (no upload keystore).

## Phase 2, reporting/orphan-cleanup/touch-target + full localization — Android emulator live validation, Web/Windows rebuild

Full walkthrough on `ICrash_API_36` against the real Firestore/Auth emulators, signed in as the seeded `institutionAdmin`, after `flutter build apk --debug` + `adb install -r` with all of this batch's changes (`shared_preferences`, `pdf`, `printing`, `flutter_localizations` newly added):

- **Cold-start ANR, investigated and dismissed as environmental**: the very first launch after install hit a recurring "app1 isn't responding" system dialog (`Input dispatching timed out (Application does not have a focused window)`). `adb logcat`'s ANR report showed a whole-device CPU/memory pressure spike at that moment (`kswapd0` at 82% kernel, unrelated processes like `com.google.android.apps.wellbeing` simultaneously spiking to 90% CPU, system-wide load average 2.91) — not anything specific to this app's own code path. `adb shell am force-stop` + a fresh `am start` a few seconds later loaded cleanly with no ANR, and the rest of the session (every screen below) ran with zero further ANRs and zero fatal exceptions in logcat. Recorded here rather than silently ignored, but not treated as a real defect given the evidence.
- **Language switcher**: WORKING end-to-end. The institution dashboard's new globe `AppBar` icon opens a "Português"/"English" menu; selecting "English" re-rendered the *entire currently-open screen* instantly — status counts, "Alertas"/"Alerts", "Atividade recente"/"Recent activity", the search field's hint, the "Novo carro"/"New cart" FAB — while cart/product *names* (user-entered data) correctly stayed unchanged. Navigated into History while still in English: filter chips, "View summary", "Export CSV", "Export PDF" all rendered in English.
- **Reporting — per-cart/per-period summaries**: WORKING. In the (English) summary dialog, switching the `SegmentedButton` from "Product" to "Cart" showed "Carro de Emergência 1 — Consumed: 0 Replenished: 5"; switching to "Period" (day granularity, the default) showed today's date with the same totals. Both new grouping dimensions compute correctly against real seeded data.
- **Reporting — PDF export**: WORKING. "Export PDF" opened Android's native print/share sheet (`printing` package) with a rendered one-page preview: title "Activity history" (English — follows the UI locale, since `HistoryScreen` passes it in), table headers/data in fixed Portuguese ("Data / Tipo / Produto / Quantidade", "Reposição", "Adrenalina", "+5") — confirms the deliberate export-language split (see `docs/ARCHITECTURE.md`) works as designed, not by accident.
- **Slot editor**: WORKING. Opened a real 5×7 drawer; grid rendered correctly with legible, adequately-sized cells (this particular size didn't need the new touch-target scroll fallback to engage, since 7 columns still fit above the 48dp floor on this screen width — the fallback path itself is covered by its own widget test with a denser 10×10 drawer, not re-proven live here).
- Orphaned-assignment reassign/delete were **not** separately reproduced live beyond the passing widget tests against the fakes — deliberately: reproducing a genuine orphan requires a specific non-top-left merge sequence that's fragile to script via raw `adb shell input tap` coordinates, and the underlying Firestore operations (`reassignSlot`/`deleteAssignment`) are simple `.update()`/batched `.delete()` calls following the exact same patterns as this repository's other already-live-validated methods, gated by Rules already covered by the existing manager+ `update`/`delete` rules on `assignments` (no new Rules were added or needed).
- `firestore-tests` (`npm test`, local emulator): 27/27 passing on a clean re-run (one run immediately after the heaviest Android activity showed a single transient failure tied to emulator connection contention, not reproducible on retry).
- `flutter build web --no-pub`: passed. `flutter build windows --no-pub`: passed; launched `app1.exe` directly and confirmed the process stayed running after 5 seconds (no crash) with every new package linked in.
- `flutter analyze --no-pub`: clean. `flutter test`: 132/132.

## Phase 2, Web/Windows build re-validation

`flutter build web --no-pub`: passed (60.9s), including the Wasm dry run. `flutter build windows --no-pub`: passed (170.9s), producing `build/windows/x64/runner/Release/app1.exe`; launched it directly and confirmed it started and stayed running (no crash) with the new packages linked in — `mobile_scanner`, `camera`, `qr_flutter`, `connectivity_plus` — none of which have a real Windows implementation (`mobile_scanner`/`camera` have none at all; `isCameraScanningSupported` correctly gates their UI entry points off on this platform, which is exactly what HID scanning exists for). Confirms nothing added across this whole 10-step batch broke either target at the build level. No further live click-through was done beyond the launch-and-stay-running check — a fuller Windows UI walkthrough (HID scanning end-to-end, QR display, connectivity banner) remains open, same as it always has been for this platform (see `docs/AI_HANDOFF.md`'s "Known platform limitations").

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
