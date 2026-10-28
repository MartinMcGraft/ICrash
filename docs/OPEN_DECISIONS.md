# Open decisions

What is decided, what is only proposed, and what still needs the team or the clinicians.
Updated 28 Oct 2026 (database decisions DB1–DB4, DB7, DB8, DB10 and P1–P3, P5, P6, P9, P11, P12, P14, P16, P17; see `docs/DATABASE.md`).

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
| R1 | Platform split | One Flutter codebase: **App** on Android/iOS/iPadOS, **Dashboard** on web/Windows/macOS/Linux |
| R2 | Monthly management | In scope, and the App's **default mode** |
| R3 | Phones | In scope, landscape |
| R4 | Orientation and navigation | Landscape only; permanent side bar |
| R5 | Offline | Required, with sync on reconnect |
| R6 | Cart state | Manual, with an optional automatic rule (D7) |
| R7 | Structure editing (drawers, grid, catalogue, templates, users) | Dashboard only |

## 2. Design decisions

| # | Decision | Status | What was chosen / proposed | Where in the app |
|---|---|---|---|---|
| D1 | Shell by platform or by role | **Decided** | The platform picks the shell; the role decides what's visible inside it | `resolveShellKind()` in `app_root.dart` |
| D2 | User types and permissions | **Confirmed** (13 Oct) | Engineer Admin, Institution Manager, Health Professional (a 4th type still undefined). The Engineer Admin is the institution's IT department (28 Oct, P14). The Health Professional may view carts, record consumption, replenish, do the monthly check, sign reports and use emergency mode; structure stays with managers. **Still to do:** map it to the code roles and update `firestore.rules` (today a HP may change only `currentQuantity`). Database: UserType, Permission and UserTypePermission tables | B7, `AppPermission` |
| D3 | Cart login and PIN | **Changed** (18 Oct) | Scanning the cart QR opens a session limited to that cart. **New direction (database design, 18 Oct):** the institution issues each employee's credentials (`userNumber`, password and PIN), and the PIN is checked by the institution's server, so it works on any cart tablet. This replaces the device-only PIN of 13 Oct. **Decided (28 Oct, DB3):** only the administration generates, changes or resets credentials; users can't change their own. Each institution chooses how it logs in (I-Crash offers options); this is defined last | A2, A3 |
| D4 | Monthly check content | **Decided** (18 Oct, Martim) | The whole cart is checked in one go (breaks allowed; the app remembers where the nurse was). **Only items that are expired or expiring are checked**; everything else counts as valid by default. No drawer-by-drawer confirmation. Still open: the checklist items, the frequency (clinical Q7), and whether hospital procedure still requires a quick check of the rest (DATABASE.md DB6). Replaces the drawer-by-drawer proposal of 13 Oct and `DOMAIN.md` §46 "every drawer must be verified" | A8 |
| D5 / §9 | Emergency mode | **Idea kept, out of the final prototype.** No emergency mode for now (28 Oct, P12) | Consumption only, tap = −1 unit, a red shell, and ending it sets "Reposição necessária" and creates a summary. Open questions are in §4 | A10 |
| D6 | Report signing | **Confirmed** (13 Oct) | Name + PIN + timestamp; the report is read-only once signed. Not a qualified digital signature (CMD / Cartão de Cidadão). **Decided (28 Oct, DB4):** the person who performs the check signs it; there is no separate signer | A9 |
| D7 | Automatic cart state | **Confirmed** (13 Oct) | Expired or missing product → Reposição necessária; check older than 31 days → Verificação em atraso; otherwise Operacional; Fora de serviço is always manual. Switchable per cart | B3, `suggestedCartStatus` |
| D8 | Shifts | **Confirmed** (13 Oct) | One responsible Health Professional per cart per shift (morning / afternoon / night) | B8 |
| D9 | Scanning | Default implemented | GS1 Data Matrix, EAN-13 and Code 128; internal QR for carts. **NFC deferred** (stub) | A11 |
| D10 | Minimum stock | **Decided: none** (18 Oct, Martim) | No minimum stock; only `0 ≤ current ≤ max`, and "needs replenishment" = below max. The app still has an optional `minimumQuantity` and a "Stock baixo" slot state to remove | B4 |
| D11 | Grid cell content | Default implemented | Short name + quantity + a badge when not OK | `SlotCell` |
| D12 | Slot interaction | Default implemented | Tap opens the side panel (no long-press) | A6 |
| D13 | What a Health Professional sees on the carts list | Default implemented | Their carts with state; cross-cart alerts are manager+ (a Firestore limitation, see FIREBASE.md §6) | A4 |
| D14 | Offline conflicts (two devices, same slot) | **Open** | Proposal: increments + append-only events for stock; last write wins for structure. Blocked on the offline-write fix | — |
| D15 | Deleting things that have history | Partly decided | **Archive, never delete.** Carts can be archived (the rules forbid deleting them). Drawers, slots and placements: once History refers to them they can't be deleted, and a used slot keeps its consumable; a cart's structure is expected to stay as built (28 Oct, P1/P2). Products: still to define. Database: carts have `archived`, batches `removedAt`; History and Report rows reference users, slots and products, so those can't be deleted once used (see DB11 for users) | B3 |

**Infrastructure:**
- **New direction (18 Oct):** each institution runs on its **own local server** and nothing inside an institution is shared outside it. This may change the Firebase strategy; to be decided in the security/hosting phase. The relational model is being designed for PostgreSQL (`docs/DATABASE.md`).
- The Firebase project `i-crash-pt-2026` (Firestore in `eur3`) is set up and used.
- **No billing is authorised** (Spark plan), so nothing that needs Cloud Functions.
- The repository is `https://github.com/MartinMcGraft/ICrash.git`.

---

## 2b. Database design (open, 18 Oct)

Details and reasoning in `docs/DATABASE.md` §1.6 (conceptual model) and §2.6 (logical model).

| # | Item | Status |
|---|---|---|
| DB1 | Batch (one row per expiry date in a slot) and SlotCC `earliestExpirationDate` | **Decided (18 Oct, confirmed 28 Oct):** a batch is the units of one slot that share the same expiry date; `earliestExpirationDate` is derived. Still to test in PostgreSQL. Clinical Q6 waits with emergency mode (P12) |
| DB2 | Clinical consumable catalogue per institution or shared | **Decided (28 Oct): per institution.** Can be pre-loaded at setup from an outside catalogue (template, INFARMED, or the hospital's own catalogue database) |
| DB3 | Login method (company-issued `userNumber` + password + PIN; maybe hospital Active Directory later) | **Decided (28 Oct):** the administration generates and hands out credentials; only it can change or reset them (`mustChangeCredentials` removed). The login method itself is chosen per institution, last |
| DB4 | Separate report signer (e.g. a manager) | **Decided (28 Oct): none.** The person who performs the check signs it (D6) |
| DB5 | Shifts recorded on the cart–user link (`day` + `period`) | **Open** (D8) |
| DB6 | Is checking only expired/expiring items enough, or does procedure still require a quick check of the rest? | **Open**: ask ESEL |
| DB7 | Templates: `qr_code` and `location` | **Decided (28 Oct):** templates have neither; both are NULL for templates and required for real carts |
| DB8 | Should `qr_code` (and a permission's name) be unique? | **Decided (28 Oct):** both UNIQUE; `qr_code` may be NULL (templates) |
| DB9 | Slot state stored (recalculated on each change and daily) or calculated in a view | **Meaning decided (28 Oct):** the state the slot is in now; when several apply, the highest priority wins (e.g. Expired 3 → Expiring 2 → Valid 1). **Still open:** stored or calculated |
| DB10 | `weight` and `volume` as text with unit, or numbers with a fixed unit | **Decided (28 Oct):** descriptive text ("30 mg", "3 ml"); the list of units is an app setting, for non-metric countries |
| DB11 | Deactivating users (no active/disabled status; used users can't be deleted) | **Open** |
| DB12 | Not modelled yet: per-product expiry warning, drawer layout versions, administrative audit log | **Open**: the audit log goes to the security phase |

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
| P14 | What is an Engineer Admin on a one-institution server? | **Decided (28 Oct):** the institution's IT department, with administrative access; they contact the I-Crash team for help |
| P17 | Department for users, name for drawers? | **Decided (28 Oct): neither** |
| P19 | New (28 Oct): how does configuring a cart record the stock it already holds (`currNumberCC` and the batches' expiry dates), given that stock otherwise changes only through History? | **Open** |
| P4 | Slot-state priority values | **Deferred (28 Oct):** set once the database design is closed. The order is "worst wins" (DB9) |
| P7 | History types. The model has five: Consumption, Replenishment, Discard, Correction, Count. The code has neither Discard nor Count; it has a "reconciliation" after an audit. (a) Is **Count** the same thing: the nurse counts the units in a slot and the app records the difference? (b) Can units be thrown away (e.g. a broken ampoule) outside a monthly check, recorded as **Discard**? | **Open** |
| P15 | Corrections. A wrong History row (e.g. −3 recorded instead of −2) is fixed by a new Correction row that points to it. (a) Must the correction be for the same slot as the row it fixes? The model doesn't check this. (b) Must the person write a reason, or is it optional (as now)? | **Open** |
| Others | P8, P10, P13, P18 | **Open**; see the gap report |

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
