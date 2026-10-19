# Open decisions

What is decided, what is only proposed, and what still needs the team or the clinicians.
Updated 18 Oct 2026 (database design decisions: conceptual and logical model, see `docs/DATABASE.md`).

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
| D2 | User types and permissions | **Confirmed** (13 Oct) | Engineer Admin, Institution Manager, Health Professional (a 4th type still undefined). The Health Professional may view carts, record consumption, replenish, do the monthly check, sign reports and use emergency mode; structure stays with managers. **Still to do:** map it to the code roles and update `firestore.rules` (today a HP may change only `currentQuantity`). Database: UserType, Permission and UserTypePermission tables | B7, `AppPermission` |
| D3 | Cart login and PIN | **Changed** (18 Oct) | Scanning the cart QR opens a session limited to that cart. **New direction (database design, 18 Oct):** the institution issues each employee's credentials (`userNumber`, password and PIN), the employee must change them on first login, and the PIN is checked by the institution's server, so it works on any cart tablet. This replaces the device-only PIN of 13 Oct. Login method still open (DATABASE.md DB3) | A2, A3 |
| D4 | Monthly check content | **Decided** (18 Oct, Martim) | The whole cart is checked in one go (breaks allowed; the app remembers where the nurse was). **Only items that are expired or expiring are checked**; everything else counts as valid by default. No drawer-by-drawer confirmation. Still open: the checklist items, the frequency (clinical Q7), and whether hospital procedure still requires a quick check of the rest (DATABASE.md DB6). Replaces the drawer-by-drawer proposal of 13 Oct and `DOMAIN.md` §46 "every drawer must be verified" | A8 |
| D5 / §9 | Emergency mode | **Idea kept, out of the final prototype** | Consumption only, tap = −1 unit, a red shell, and ending it sets "Reposição necessária" and creates a summary. Open questions are in §4 | A10 |
| D6 | Report signing | **Confirmed** (13 Oct) | Name + PIN + timestamp; the report is read-only once signed. Not a qualified digital signature (CMD / Cartão de Cidadão). Database model assumes **the person who performs the check signs it**; a separate signer (e.g. a manager) is open (DATABASE.md DB4) | A9 |
| D7 | Automatic cart state | **Confirmed** (13 Oct) | Expired or missing product → Reposição necessária; check older than 31 days → Verificação em atraso; otherwise Operacional; Fora de serviço is always manual. Switchable per cart | B3, `suggestedCartStatus` |
| D8 | Shifts | **Confirmed** (13 Oct) | One responsible Health Professional per cart per shift (morning / afternoon / night) | B8 |
| D9 | Scanning | Default implemented | GS1 Data Matrix, EAN-13 and Code 128; internal QR for carts. **NFC deferred** (stub) | A11 |
| D10 | Minimum stock | **Decided: none** (18 Oct, Martim) | No minimum stock; only `0 ≤ current ≤ max`, and "needs replenishment" = below max. The app still has an optional `minimumQuantity` and a "Stock baixo" slot state to remove | B4 |
| D11 | Grid cell content | Default implemented | Short name + quantity + a badge when not OK | `SlotCell` |
| D12 | Slot interaction | Default implemented | Tap opens the side panel (no long-press) | A6 |
| D13 | What a Health Professional sees on the carts list | Default implemented | Their carts with state; cross-cart alerts are manager+ (a Firestore limitation, see FIREBASE.md §6) | A4 |
| D14 | Offline conflicts (two devices, same slot) | **Open** | Proposal: increments + append-only events for stock; last write wins for structure. Blocked on the offline-write fix | — |
| D15 | Deleting things that have history | Partly decided | **Archive, never delete.** Carts can be archived (the rules forbid deleting them). Products and drawers: still to define. Database: carts have `archived`, batches `removedAt`; History and Report rows reference users, slots and products, so those can't be deleted once used (see DB11 for users) | B3 |

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
| DB1 | Batch (one row per expiry date in a slot) and SlotCC `earliestExpirationDate` | **Decided (18 Oct): Batch adopted**; `earliestExpirationDate` is derived. Still to test in PostgreSQL, and clinical Q6 for after-emergency handling |
| DB2 | Clinical consumable catalogue per institution or shared | **Open** |
| DB3 | Login method (company-issued `userNumber` + password + PIN; maybe hospital Active Directory later) | **Open** |
| DB4 | Separate report signer (e.g. a manager) | **Open** (D6) |
| DB5 | Shifts recorded on the cart–user link (`day` + `period`) | **Open** (D8) |
| DB6 | Is checking only expired/expiring items enough, or does procedure still require a quick check of the rest? | **Open**: ask ESEL |
| DB7 | Templates: `qr_code` and `location` are mandatory, but a template has neither | **Open** |
| DB8 | Should `qr_code` (and a permission's name) be unique? | **Open**: probably yes for `qr_code` |
| DB9 | Slot state stored (recalculated on each change and daily) or calculated in a view | **Open** |
| DB10 | `weight` and `volume` as text with unit, or numbers with a fixed unit | **Open**: text proposed |
| DB11 | Deactivating users (no active/disabled status; used users can't be deleted) | **Open** |
| DB12 | Not modelled yet: per-product expiry warning, drawer layout versions, administrative audit log | **Open**: the audit log goes to the security phase |

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

1. What can be done in it? Only record consumption, or also replenish?
2. Speed vs control: no confirmation dialogs? Bigger targets? Tap to decrement?
3. Does entering it need a login or PIN, or can anyone at the cart use it?
4. Recording style: per item during the event, or one total afterwards (clinical Q15)?
5. Leaving it: a summary screen? Automatic "Reposição necessária"? A report to sign?
6. It must work with no network (depends on the offline-write fix).
7. How different must it look so nobody stays in it by accident?
8. Is "daily management" the same as emergency mode, or is there also a calm daily
   check (e.g. a seal check at shift start)?
