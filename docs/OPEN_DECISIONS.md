# Open decisions

What is decided, what is only proposed, and what still needs the team or the clinicians.
Updated 2 Nov 2026 (Dashboard review as Admin: D24, D25, P25; then D26 and shifts set aside, D8). Before that, 30 Oct 2026 (app review: D16–D22, see `docs/REVIEW_2026-10-30.md`; then Martim's answers on the database points: D23, DB5, DB6, DB9, DB11, P7, P8, P10, P15, P18, P19). Before that, 28 Oct (database decisions DB1–DB4, DB7, DB8, DB10 and P1–P3, P5, P6, P9, P11, P12, P14, P16, P17; see `docs/DATABASE.md`).

**Sources:**
- Product decisions: the design audit of 12 Oct 2026 (claude.ai project "I-Crash",
  `audit-figma-vs-app-2026-10-12.md`, §8–9).
- Confirmation status: the cover of the Figma file "I-Crash · Design v2" (13 Oct 2026).

**Rule:** never invent a clinical answer in code or in the designs. If something
depends on an open question, make it configurable or leave it visibly undecided.

---

## 1. Product direction (decided)

| # | Decision | Resolution |
|---|---|---|
| R1 | Platform split | One Flutter codebase: **App** on all platforms, **Dashboard** on web/Windows/macOS/Linux |
| R2 | Monthly management | In scope, and the App's **default mode** |
| R3 | Phones | In scope, landscape |
| R4 | Orientation and navigation | Landscape only; permanent side bar |
| R5 | Offline | Required, with sync on reconnect |
| R6 | Cart state | Manual, with an optional automatic rule (D7) |
| R7 | Structure editing (drawers, grid, catalogue, templates, users) | Dashboard only, only Super and Admin are allowed |
| R8 | Design is responsive, **App** fits on all screens because it is made mobile first, **Dashboard** is only for large devices, laptops/desktops, with minimal width of 992px |

## 2. Design decisions

| # | Decision | Status | What was chosen / proposed | Where in the app |
|---|---|---|---|---|
| D1 | Shell by platform or by role | **Decided** | The platform picks the shell; the role decides what's visible inside it | `resolveShellKind()` in `app_root.dart` |
| D2 | User types and permissions | **Superseded by D16** (30 Oct) for the types; the permission list below still applies to Managers | Engineer Admin, Institution Manager, Health Professional (a 4th type still undefined). The Engineer Admin is the institution's IT department (28 Oct, P14). The Health Professional may view carts, record consumption, replenish, do the monthly check, sign reports and use emergency mode; structure stays with managers. **Still to do:** map it to the code roles and update `firestore.rules` (today a HP may change only `currentQuantity`). Database: UserType, Permission and UserTypePermission tables | B7, `AppPermission` |
| D3 | Cart login and PIN | **Changed** (18 Oct); device setup added by **D17** (30 Oct) | Scanning the cart QR opens a session limited to that cart. **New direction (database design, 18 Oct):** the institution issues each employee's credentials (`userNumber`, password and PIN), and the PIN is checked by the institution's server, so it works on any cart tablet. This replaces the device-only PIN of 13 Oct. **Decided (28 Oct, DB3):** only the administration generates, changes or resets credentials; users can't change their own. Each institution chooses how it logs in (I-Crash offers options); this is defined last | A2, A3 |
| D4 | Monthly check content | **Decided** (18 Oct, Martim); **build now** (D22, 30 Oct) | The whole cart is checked in one go (breaks allowed; the app remembers where the nurse was). **Only items that are expired or expiring are checked**; everything else counts as valid by default. No drawer-by-drawer confirmation. Still open: the checklist items, the frequency (clinical Q7), and whether hospital procedure still requires a quick check of the rest (DATABASE.md DB6). Replaces the drawer-by-drawer proposal of 13 Oct and `DOMAIN.md` §46 "every drawer must be verified" | A8 |
| D5 / §9 | Emergency mode | **Idea kept, out of the final prototype.** No emergency mode for now (28 Oct, P12) | Consumption only, tap = −1 unit, a red shell, and ending it sets "Reposição necessária" and creates a summary. Open questions are in §4. **30 Oct (D23):** the summary becomes the **usage report**, which is needed whether or not emergency mode comes back | A10 |
| D6 | Report signing | **Confirmed** (13 Oct) | Name + PIN + timestamp; the report is read-only once signed. Not a qualified digital signature (CMD / Cartão de Cidadão). **Decided (28 Oct, DB4):** the person who performs the check signs it; there is no separate signer | A9 |
| D7 | Automatic cart state | **Confirmed** (13 Oct) | Expired or missing product → Reposição necessária; check older than 31 days → Verificação em atraso; otherwise Operacional; Fora de serviço is always manual. Switchable per cart | B3, `suggestedCartStatus` |
| D8 | Shifts | **Idea kept, out of the prototype** (2 Nov, Martim), like emergency mode (P12). Before that: confirmed 13 Oct | Hidden behind `kShiftsEnabled = false` (`ui/core/feature_flags.dart`): no "Turnos" in the Dashboard sidebar (B8), no "Responsável no turno" in B2 or A5, no "Os meus" tab in A4. The B8 code, the shift repository (local stub) and their tests are kept; flip the constant to bring it back. D25, DB5 and P18 wait with it. The idea as it was: one responsible Health Professional per cart per shift (morning / afternoon / night). **30 Oct (DB5, P18):** the Admin sets up shifts and responsible people for now; see DB5 | B8 |
| D9 | Scanning | Default implemented | GS1 Data Matrix, EAN-13 and Code 128; internal QR for carts. **NFC deferred** (stub) | A11 |
| D10 | Minimum stock | **Decided: none** (18 Oct, Martim) | No minimum stock; only `0 ≤ current ≤ max`, and "needs replenishment" = below max. The app still has an optional `minimumQuantity` and a "Stock baixo" slot state to remove | B4 |
| D11 | Grid cell content | Default implemented | Short name + quantity + a badge when not OK | `SlotCell` |
| D12 | Slot interaction | Default implemented | Tap opens the side panel (no long-press) | A6 |
| D13 | What a Health Professional sees on the carts list | Default implemented | Their carts with state; cross-cart alerts are manager+ (a Firestore limitation, see FIREBASE.md §6) | A4 |
| D14 | Offline conflicts (two devices, same slot) | **Open** | Proposal: increments + append-only events for stock; last write wins for structure. Blocked on the offline-write fix | — |
| D16 | User types | **Decided** (30 Oct, Martim); **in the code and rules** (30 Oct, phase 6) | **Super** = the I-Crash team's IT staff: full access to fix problems, ship updates and help the institution's IT; reaches several institutions, one at a time, only on request (D18); every screen type. **Admin** = the institution's IT staff: everything in one institution (all carts, users, devices, settings), no other institution; Dashboard, tablet/phone to test. **Manager** = a health professional: full access to the carts they're registered to; tablet or phone, may use the Dashboard. **User is dropped.** Code: `platformSuperAdmin`, `institutionAdmin`, `manager` (narrowed to registered carts); `user` removed. Replaces D2's types and P14 | B7, `Role`, `firestore.rules` |
| D17 | Device setup and sign-in | **Decided** (30 Oct, Martim) | I-Crash delivers the tablet with the app installed; Admin and/or Super set it up once (device account, users, carts). On a registered device people use PIN or cart login without ever typing a password there; personal devices keep e-mail + password. Needed because Firebase Auth can't sign in with a PIN without server code. Rules: a `device` membership may read its institution's PIN hashes; writes carry the acting member. Prototype limit: the rules can't prove who typed the PIN. **Done in code (31 Oct, phase 7b):** tablets bound to ≥ 1 cart, identification by nº mecanográfico or e-mail + PIN, 5-min inactivity, credentials in `flutter_secure_storage` | A1–A3, new "Configurar dispositivo", Dashboard device list |
| D18 | Support access for Super | **Decided** (30 Oct, Martim); **in the code and rules** (30 Oct, 4 h / 24 h / 7 dias; design in `docs/DESIGN_D17_D18.md`) | Off by default. The institution's Admin grants it for a limited time with a reason and can close it; Super sees only institutions with an open grant; every access is logged and readable by the Admin; a banner shows while Super is inside. Maximum duration still to fix. Database: DB13 | Institution picker (Super only), Dashboard "Acesso do suporte" |
| D19 | Terminology | **Decided** (30 Oct) | "Produto" → **Consumível** (short) and **Consumível clínico** (long); EN "Consumable" / "Clinical consumable". UI, PDF and CSV; code names unchanged | ARB files |
| D20 | Drawer name | **Decided** (30 Oct), reverses the drawer half of P17 | Drawers get an **optional descriptive name** (e.g. "Via aérea") shown after the number badge; empty → "Gaveta N". Users still have no department | A5, B3, DATABASE.md DRAWER |
| D21 | Phone vs tablet | **Decided** (30 Oct) | Same actions on every form factor. Phones may shorten labels, scroll vertically or group secondary actions in "Mais ações", never hide an action | A5, A6, all screens |
| D22 | Monthly check rewrite | **Decided** (30 Oct) | Build D4 now: only expired/expiring batches, one outcome each, autosave, resume; "Marcar restantes" removed. An unsigned report survives back and is signed later from "Por assinar". **Changed (30 Oct, D23/P8):** no "Não encontrado" outcome | A8, A9 |
| D23 | Reports and History | **Decided** (30 Oct, Martim); the database model still has to be reworked (DATABASE.md) | **Two report types.** **Utilização** (daily usage): written every time a cart is used; lists, by drawer, the consumables used and the ones replenished (replenishing after use is mandatory), plus the cart, date and time, who signed and a note saying what the use was (e.g. the emergency). **Gestão mensal** (monthly management): by drawer, what was expired and was therefore replenished, and what is expiring, plus the cart, date and time, who signed and a note. **History** is the chronological list of what the reports contain, for one report type, several or all; it isn't a separate log people write to. **A report can't change once signed**: there are no corrections (P15) and no "Não encontrado" (P8). Replaces the emergency summary (D5) and the Correction, Count and reconciliation actions | A6, A8, A9, A10, B9 |
| D24 | "Histórico" in the Dashboard sidebar | **Decided** (2 Nov, Martim); **in the code** | Removed from the sidebar. It opened the same screen as "Relatórios" ("Relatórios e histórico"), only on the "Eventos" tab, so history stays there (tabs Relatórios · Eventos · Estatísticas) | Dashboard sidebar, B9 |
| D26 | B4 position panel beside the grid | **Decided** (2 Nov, Martim: the floating panel covers the positions and they can't be reached while configuring a drawer; in the App it works, so only the Dashboard changes) | In B4 "Editar grelha" the position panel is docked to the right of the grid (Figma's B4 layout, Material 3 "supporting pane"); the grid shrinks into the remaining width, so no position is covered and nothing scrolls sideways. Panel ≤ 380 px and ≤ 40 % of the width. Narrow cells (< 72 px) show a wrapped name plus quantity and state icon. The App (A6/A7) keeps the panel over the grid (14 Oct decision unchanged there). Enforced in `layout_fit_test.dart`. DC-64 | B4 |
| D25 | Shift setup usability | **Set aside with D8** (2 Nov; was open, "to define and think through") | Today each cell (cart × day × period) is set one at a time in a dialog (cart, day, M/T/N tab, responsible), plus "Copiar semana anterior". Too slow to be useful. Martim wants at least to set M, T and N of a day in one go. Ideas to weigh: several periods (or "Dia inteiro") in the dialog; select several cells in the grid (days × periods, across carts) and assign once; repeat a pattern (weekdays, a whole week) or copy a day; assign from the "Por pessoa" view. Depends on DB5: if shifts are later imported from the hospital's system, the screen mostly shows them and needs less editing | B8 |
| D15 | Deleting things that have history | Partly decided | **Archive, never delete.** Carts can be archived (the rules forbid deleting them). Drawers, slots and placements: once History refers to them they can't be deleted, and a used slot keeps its consumable; a cart's structure is expected to stay as built (28 Oct, P1/P2). Products: still to define. Database: carts have `archived`, batches `removedAt`; History and Report rows reference users, slots and products, so those can't be deleted once used (see DB11 for users) | B3 |

**Infrastructure:**
- **New direction (18 Oct):** each institution runs on its **own local server** and nothing inside an institution is shared outside it. This may change the Firebase strategy; to be decided in the security/hosting phase. The relational model is being designed for PostgreSQL (`docs/DATABASE.md`); testing the scenarios in PostgreSQL is dropped (30 Oct).
- The Firebase project `i-crash-pt-2026` (Firestore in `eur3`) is set up and used.
- **No billing is authorised** (Spark plan), so nothing that needs Cloud Functions.
- The repository is `https://github.com/MartinMcGraft/ICrash.git`.

---

## 2b. Database design (open, 18 Oct)

Details and reasoning in `docs/DATABASE.md` §1.6 (conceptual model) and §2.6 (logical model).

| # | Item | Status |
|---|---|---|
| DB1 | Batch (one row per expiry date in a slot) and SlotCC `earliestExpirationDate` | **Decided (18 Oct, confirmed 28 Oct):** a batch is the units of one slot that share the same expiry date; `earliestExpirationDate` is derived. Clinical Q6 waits with emergency mode (P12). **30 Oct:** PostgreSQL testing dropped; a batch is now one **lot** in a slot (P10) |
| DB2 | Clinical consumable catalogue per institution or shared | **Decided (28 Oct): per institution.** Can be pre-loaded at setup from an outside catalogue (template, INFARMED, or the hospital's own catalogue database) |
| DB3 | Login method (company-issued `userNumber` + password + PIN; maybe hospital Active Directory later) | **Decided (28 Oct):** the administration generates and hands out credentials; only it can change or reset them (`mustChangeCredentials` removed). The login method itself is chosen per institution, last |
| DB4 | Separate report signer (e.g. a manager) | **Decided (28 Oct): none.** The person who performs the check signs it (D6) |
| DB5 | Shifts recorded on the cart–user link (`day` + `period`) | **Set aside with D8 (2 Nov):** shifts are out of the prototype. Was decided for now (30 Oct): the **Admin** sets up shifts and who is responsible for each cart, on a Dashboard screen, and the app shows them. The hospital already plans shifts, so typing them twice should be avoided: later they're **imported** from the hospital's system, and the screen stays to show them. **Open:** how shifts are planned in the hospital (who does it, in which system), and whether that person needs their own user type. Not modelled yet |
| DB6 | Is checking only expired/expiring items enough, or does procedure still require a quick check of the rest? | **Open**: ask ESEL. Martim (30 Oct): keep the question. The app is only useful if health professionals can trust it; the time it saves comes from checking only expired and expiring items |
| DB7 | Templates: `qr_code` and `location` | **Decided (28 Oct):** templates have neither; both are NULL for templates and required for real carts |
| DB8 | Should `qr_code` (and a permission's name) be unique? | **Decided (28 Oct):** both UNIQUE; `qr_code` may be NULL (templates) |
| DB9 | Slot state stored (recalculated on each change and daily) or calculated in a view | **Meaning decided (28 Oct):** the state the slot is in now; when several apply, the highest priority wins (e.g. Expired 3 → Expiring 2 → Valid 1). **Still open:** stored or calculated. In plain words: the slot's state (expired, expiring, needs replenishment, OK) can be **saved** in the slot's row and updated by the server whenever stock changes and once a night (a date can start expiring without anyone touching the cart), or **worked out** each time a screen asks, from the quantities and dates already stored. Recommended: worked out (a view), since it can't go out of date and needs no nightly job; store it only if that proves slow |
| DB10 | `weight` and `volume` as text with unit, or numbers with a fixed unit | **Decided (28 Oct):** descriptive text ("30 mg", "3 ml"); the list of units is an app setting, for non-metric countries |
| DB11 | Deactivating users (no active/disabled status; used users can't be deleted) | **Direction decided (30 Oct):** users are managed independently of everything else: added, **deactivated**, reactivated and removed. A deactivated user can't log in, and their history is kept. For privacy, a user's personal data must be removable after some time; if that would break History or signed reports, the model changes (e.g. History becomes a view built on request, or the user row stays with its personal fields erased). **Open:** the retention period, and how a removed user still shows on signed reports (ask the hospital's data protection officer) |
| DB12 | Not modelled yet: per-product expiry warning, drawer layout versions, administrative audit log | **Open**: the audit log goes to the security phase |
| DB13 | Support access grant and its access log (D18) | **Open** (30 Oct) in the relational model; built on Firestore as `support/current`, `supportGrants`, `supportLog` (FIREBASE.md). Likely a SUPPORTGRANT table (institution, granted by, reason, from, until, closed at) and a SUPPORTACCESSLOG |
| DB14 | Registered devices (D17) | **Open** (30 Oct): not in the conceptual model yet. Firestore has it since 31 Oct (`devices/{id}`: name, `cartIds`, `authUid`, registered by/at, revoked at; FIREBASE.md). The DB still needs a DEVICE table and DEVICE–CART link, and whether History rows reference the device. Also new: `userNumber` on the person (unique per institution) |

**From the design-vs-code comparison** (questions P1–P18 in the claude.ai project,
`claude/db-design-vs-code-gap-report-2026-10-19.md`):

| # | Item | Status |
|---|---|---|
| P1, P2 | Retiring a placement, slot or drawer that has history | **Decided (28 Oct): not supported.** Carts rarely change structure, so a cart keeps the design it was built with; used drawers, slots and placements can't be deleted, and a used slot keeps its consumable |
| P12 | Emergency rules | **Set aside (28 Oct):** no emergency mode for now |
| P16 | Is GTIN unique? | **Decided (28 Oct):** UNIQUE, NULL allowed |
| P3 | Templates: deleted or not? | **Decided (28 Oct):** made at setup or when layouts need changing; edited by hand or archived, never deleted |
| P5 | May stock exceed the maximum? | **Decided (28 Oct): no.** A cart never holds more than it needs |
| P6 | Is the first stock in a slot a Replenishment row? | **Not applicable (28 Oct):** there's no first-stock event; a cart is configured with the stock it already holds. Follow-up: P19 |
| P9 | Lot number required at replenishment? | **Decided (28 Oct): optional.** Some items show only an expiry date; then it's entered and checked by hand |
| P11 | Month-only expiry dates | **Decided (28 Oct):** last day of the month |
| P14 | What is an Engineer Admin on a one-institution server? | **Superseded (30 Oct) by D16:** the institution's IT department is the **Admin**; **Super** is the I-Crash team, with support access per D18 |
| P17 | Department for users, name for drawers? | **Decided (28 Oct): neither. Changed (30 Oct, D20):** drawers get an optional name; users still have no department |
| P19 | New (28 Oct): how does configuring a cart record the stock it already holds (`currNumberCC` and the batches' expiry dates), given that stock otherwise changes only through History? | **Decided (30 Oct):** every cart is set up once, with the I-Crash team's help, on the Dashboard with Super access: drawers (number, optional name, shape), slots and the consumable in each, plus the institution's users, user types and permissions. The cart is full at that point, so `currNumberCC` = `maxNumberCC` for every placement. **Follow-up:** are each slot's lots and expiry dates recorded at setup too? The monthly check can't flag anything without them |
| P25 | New (2 Nov): a newly placed consumable shows "Em falta". B4 "Aplicar à posição" and applying a template create the placement with **0 units**, so the slot shows "Em falta" (red, second-highest priority) and, with D7 on, the cart turns "Reposição necessária" when a manager opens it. This contradicts P19 (cart set up full, current = max). Should it? | **Open (Martim: evaluate).** Options: (a) keep 0 until someone does "Repor stock" (honest, and records lot and expiry, but every new cart starts all red); (b) create the placement full, current = max, as P19 says (one line in `grid_editor_view_model.dart` and `domain/use_cases/cart_templates.dart`; the rules already allow it), but the slot then shows OK with no lot or expiry, so the monthly check can't flag it; (c) as (b), plus a neutral state such as "Sem validade" until a batch with an expiry date exists. Depends on the P19 follow-up (lots and expiry recorded at setup?) and P4 |
| P4 | Slot-state priority values | **Deferred (28 Oct):** set once the database design is closed. The order is "worst wins" (DB9). Kept open (30 Oct) |
| P7 | History types. The model has five: Consumption, Replenishment, Discard, Correction, Count. The code has neither Discard nor Count; it has a "reconciliation" after an audit. (a) Is **Count** the same thing: the nurse counts the units in a slot and the app records the difference? (b) Can units be thrown away (e.g. a broken ampoule) outside a monthly check, recorded as **Discard**? | **Answered by D23 (30 Oct):** no Count and no Correction. Stock changes come only from the two reports: what was used and replenished (usage report), and expired units replaced (monthly). Follow-up: a unit broken or thrown away outside a check, is it recorded as used in a usage report? |
| P15 | Corrections. A wrong History row (e.g. −3 recorded instead of −2) is fixed by a new Correction row that points to it. (a) Must the correction be for the same slot as the row it fixes? The model doesn't check this. (b) Must the person write a reason, or is it optional (as now)? | **Decided (30 Oct): no corrections.** A report can be edited until it's signed and never changes afterwards, so mistakes are fixed before signing. The Correction type and History's "Corrects" link (R29) go, and so do A6 "Corrigir" and its reason (built 29 Oct) |
| P8 | "Not found" during a check: does it write a History row? | **Decided (30 Oct): there is no "Não encontrado".** **Follow-up (important):** consumption never says which lot was used (DOMAIN.md §24), so after a use the app can't know whether the expiring units are still in the slot, which is the case "Não encontrado" covered. Without it, either the usage report says which lot or date was used (e.g. picked when replenishing), or the app assumes the one expiring first was used (FEFO). Links to clinical Q6 and Q17 |
| P10 | Same-date lots in one slot: which lot number? | **Decided (30 Oct):** a lot has one expiry date, and all its units share the lot code. So a batch is **one lot in a slot**: replenishing the same lot adds to it, two different lots with the same date stay two batches, and items without a lot (P9) are grouped by expiry date. Refines DB1 |
| P13 | "Check overdue" measured from `signedAt` or `periodEnd`; new carts from `createdAt`? | **Kept open (30 Oct)** |
| P18 | Who assigns responsible people to carts, and where? | **Decided for now (30 Oct):** the Admin, on the Dashboard, together with shifts (DB5). **2 Nov:** shifts are set aside (D8); the Admin still registers Managers to carts in B7 |

---

## 3. Clinical questions (for the nurses)

These need clinicians, not engineering. Keep the wording when asking them.

1. Can a physical compartment have an L/T/non-rectangular shape?
2. Should Managers be allowed to change active drawer structures?
3. Can more than one healthcare professional simultaneously be responsible for one cart?
4. Is a minimum stock quantity useful in addition to current and target/max quantity?
5. Should GS1 Data Matrix scanning during replenishment eventually become mandatory?
6. Is the conservative lot strategy correct: daily consumption changes only aggregate quantity and lot reconciliation happens during physical audits?
7. How often should a complete physical cart audit occur?
8. Must every individual slot be explicitly confirmed, or is mandatory confirmation of every drawer sufficient?
9. Which checklist items are operationally required?
10. Which notifications are valuable without producing alert fatigue?
11. Which roles may correct historical inventory entries?
12. Which GS1 information should normal users actually see?
13. How often are carts duplicated from an identical configuration?
14. Are there institution-specific rules for expiry warning periods?
15. Is it useful in a future version to distinguish stock usage between individual consecutive emergencies, or is aggregate post-emergency recording preferable?
16. Should replenishment require confirmation that the scanned Data Matrix product matches the slot product?
17. How should partially known lots be displayed during the period between emergency consumption and the next physical reconciliation?

---

## 4. Emergency mode: questions to settle before it's built for real

**Set aside (28 Oct):** there is no emergency mode for now (P12). These questions wait until it
comes back.

1. What can be done in it? Only record consumption, or also replenish?
2. Speed vs control: no confirmation dialogs? Bigger targets? Tap to decrement?
3. Does entering it need a login or PIN, or can anyone at the cart use it?
4. Recording style: per item during the event, or one total afterwards (clinical Q15)?
5. Leaving it: a summary screen? Automatic "Reposição necessária"? A report to sign?
6. It must work with no network (depends on the offline-write fix).
7. How different must it look so nobody stays in it by accident?
8. Is "daily management" the same as emergency mode, or is there also a calm daily
   check (e.g. a seal check at shift start)?
